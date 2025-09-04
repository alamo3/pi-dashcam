import platform

import cv2
import time
import threading
import queue
from pathlib import Path
from datetime import datetime, timedelta
from flask import Response

class CameraSource:
    def __init__(self, camera_id, res_x=1280, res_y=720, fps=30,
                 base_dir="recordings", max_dir_bytes=5_000_000_000):
        """
        base_dir:       Parent directory for recordings
        max_dir_bytes:  Per-camera max size budget (bytes)
        """

        system = platform.system()
        backend = 0

        if system == "Windows":
            backend = cv2.CAP_DSHOW
        elif system == "Linux":
            backend = cv2.CAP_V4L2

        self.camera_id = camera_id
        self.cap = cv2.VideoCapture(camera_id, backend)
        self.ok = self.cap.isOpened()

        if self.ok:
            self.cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*'MJPG'))
            self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, res_x)
            self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, res_y)
            self.cap.set(cv2.CAP_PROP_FPS, fps)
            self.width  = int(self.cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            self.height = int(self.cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            self.fps    = self._safe_fps(fps)
        else:
            self.width = self.height = self.fps = 0

        # --- Producer control ---
        self._run = False
        self._producer_th = None

        # --- Streaming state ---
        self._latest_bgr = None
        self._latest_jpeg = None
        self._seq = 0
        self._cv_new = threading.Condition()
        self._stream_clients = 0
        self._stream_clients_lock = threading.Lock()

        # --- Recording state & rotation ---
        self._recording = False
        self._writer = None
        self._writer_fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        self._record_q = queue.Queue(maxsize=256)
        self._writer_th = None

        # NEW: storage policy
        self.base_dir = Path(base_dir)
        self.max_dir_bytes = int(max_dir_bytes)
        self._cam_dir = self.base_dir / f"cam_{self.camera_id}"

        self._file_prefix = f"cam{self.camera_id}_"

        # NEW: rotation timing
        self._segment_start_dt = None          # datetime for file naming
        self._segment_end_dt = None            # datetime for 60s boundary

        if self.ok:
            self._cam_dir.mkdir(parents=True, exist_ok=True)
            self._start_producer()

        self.actual_stream_id = -1



    def _safe_fps(self, requested):
        got = self.cap.get(cv2.CAP_PROP_FPS)
        if got and got > 0:
            return got
        return requested if requested > 0 else 30

    # ---------------- Producer ----------------
    def _start_producer(self):
        if self._run or not self.ok:
            return
        self._run = True
        self._producer_th = threading.Thread(target=self._producer_loop, daemon=True)
        self._producer_th.start()

    def _producer_loop(self):
        while self._run:
            ok, frame = self.cap.read()
            if not ok:
                time.sleep(0.01)
                continue

            # Streaming
            jpeg_needed = (self._stream_clients > 0)
            if jpeg_needed:
                ret, buf = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
                if ret:
                    with self._cv_new:
                        self._latest_bgr = frame
                        self._latest_jpeg = buf.tobytes()
                        self._seq += 1
                        self._cv_new.notify_all()
            else:
                with self._cv_new:
                    self._latest_bgr = frame
                    self._seq += 1
                    self._cv_new.notify_all()

            # Recording (lossless path)
            if self._recording:
                try:
                    self._record_q.put(frame, timeout=0.5)
                except queue.Full:
                    # Consider logging a warning or bumping queue size
                    pass

        with self._cv_new:
            self._cv_new.notify_all()

    # ---------------- Recording with 1-minute rotation ----------------
    def start_recording(self):
        """
        Begin continuous 1-minute segments. Filenames & rotation handled internally.
        """
        if not self.ok or self._recording:
            return False

        self._drain_queue(self._record_q)
        # Prepare first segment
        if not self._open_new_segment():
            return False

        self._recording = True
        self._writer_th = threading.Thread(target=self._writer_loop, daemon=True)
        self._writer_th.start()
        return True

    def _open_new_segment(self) -> bool:
        """
        Close any existing writer, evict old files to honor max_dir_bytes,
        then open a new 1-minute segment file.
        """
        # Close previous writer if present
        if self._writer is not None:
            try:
                self._writer.release()
            except Exception:
                pass
            self._writer = None

        # Compute this segment's time window aligned to wall-clock minute
        now = datetime.now()
        # Align start to current second (we just use now as start; optional: floor to minute)
        self._segment_start_dt = now
        self._segment_end_dt = self._segment_start_dt + timedelta(minutes=1)

        # Evict old files BEFORE starting a new one
        self._evict_until_under_limit()

        # Build filename
        ts = self._segment_start_dt.strftime("%Y%m%d_%H%M%S")
        filename = f"{self._file_prefix}{ts}.mp4"
        path = self._cam_dir / filename

        self._writer = cv2.VideoWriter(
            str(path),
            self._writer_fourcc,
            self.fps if self.fps > 0 else 30.0,
            (self.width, self.height)
        )
        if not self._writer.isOpened():
            self._writer = None
            return False
        return True

    def _writer_loop(self):
        while self._recording:
            try:
                frame = self._record_q.get(timeout=0.5)
            except queue.Empty:
                # Time-based rotation even if no frames were queued recently
                self._maybe_rotate_by_time()
                continue

            if frame is None:  # shutdown sentinel
                break

            # Write current frame
            if self._writer is not None:
                self._writer.write(frame)

            # Check if we crossed 60s window and rotate if needed
            self._maybe_rotate_by_time()

        # Drain on exit
        while not self._record_q.empty():
            frame = self._record_q.get_nowait()
            if frame is None:
                break
            if self._writer is not None:
                self._writer.write(frame)

        if self._writer is not None:
            self._writer.release()
            self._writer = None

    def _maybe_rotate_by_time(self):
        if self._segment_end_dt is None:
            return
        if datetime.now() >= self._segment_end_dt:
            # Close current file, evict if needed, open next
            self._open_new_segment()

    def stop_recording(self):
        if not self._recording:
            return
        self._recording = False
        try:
            self._record_q.put_nowait(None)  # unblock writer
        except queue.Full:
            pass
        if self._writer_th:
            self._writer_th.join(timeout=2.0)
            self._writer_th = None
        if self._writer:
            self._writer.release()
            self._writer = None

    # ---------------- Storage management (per camera) ----------------
    def _camera_files(self):
        """List this camera's files (Path objects), sorted by modification time (oldest first)."""
        if not self._cam_dir.exists():
            return []
        files = [p for p in self._cam_dir.glob(f"{self._file_prefix}*.mp4") if p.is_file()]
        files.sort(key=lambda p: p.stat().st_mtime)  # oldest first
        return files

    def _dir_size_bytes(self) -> int:
        total = 0
        for p in self._cam_dir.glob("*"):
            if p.is_file():
                try:
                    total += p.stat().st_size
                except FileNotFoundError:
                    pass
        return total

    def _evict_until_under_limit(self):
        """
        Remove oldest segments for THIS camera until folder size <= max_dir_bytes.
        Never touches a file currently open for writing (we always close before eviction).
        """
        if self.max_dir_bytes <= 0:
            return

        files = self._camera_files()
        size = self._dir_size_bytes()
        # Heuristic: keep evicting while we exceed the cap
        # (Optionally add a safety margin, e.g., leave ~10MB headroom.)
        while size > self.max_dir_bytes and files:
            victim = files.pop(0)
            try:
                sz = victim.stat().st_size
            except FileNotFoundError:
                sz = 0
            try:
                victim.unlink()
                size -= sz
            except Exception:
                # If deletion fails, break to avoid infinite loop
                break

    # ---------------- Streaming ----------------
    def _register_stream_client(self):
        with self._stream_clients_lock:
            self._stream_clients += 1

    def _unregister_stream_client(self):
        with self._stream_clients_lock:
            self._stream_clients = max(0, self._stream_clients - 1)

    def _stream_generator(self, heartbeat_s=1.0):
        self._register_stream_client()
        client_seq = -1
        try:
            boundary = b'--frame\r\nContent-Type: image/jpeg\r\n\r\n'
            last_heartbeat = time.time()
            while True:
                with self._cv_new:
                    self._cv_new.wait(timeout=0.5)
                    seq = self._seq
                    jpeg = self._latest_jpeg

                now = time.time()
                if jpeg is not None and seq != client_seq:
                    client_seq = seq
                    yield boundary + jpeg + b'\r\n'
                    last_heartbeat = now
                elif now - last_heartbeat >= heartbeat_s:
                    yield b'\r\n'
                    last_heartbeat = now
        finally:
            self._unregister_stream_client()

    def set_actual_stream_id(self, stream_id):
        self.actual_stream_id = stream_id

    def make_stream_route(self):
        def stream():
            return Response(self._stream_generator(),
                            mimetype='multipart/x-mixed-replace; boundary=frame')
        return stream

    def add_app_route(self, app):
        route = f"/stream/{self.actual_stream_id}"
        app.add_url_rule(route, f'stream_{self.actual_stream_id}', self.make_stream_route())

    # ---------------- Cleanup ----------------
    def release(self):
        self.stop_recording()
        if self._run:
            self._run = False
            if self._producer_th:
                self._producer_th.join(timeout=2.0)
                self._producer_th = None
        if self.cap:
            try:
                self.cap.release()
            except Exception:
                pass

    @staticmethod
    def _drain_queue(q: queue.Queue):
        try:
            while True:
                q.get_nowait()
        except queue.Empty:
            pass
