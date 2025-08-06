from flask import Flask, Response, jsonify
import cv2

app = Flask(__name__)
cameras = {}  # camera_id -> VideoCapture

# Function to test available camera indices
def detect_cameras(max_tested=4):
    available = []
    for i in range(max_tested):
        cap = cv2.VideoCapture(i)
        if cap.read()[0]:
            available.append(i)
            cameras[i] = cap
        else:
            cap.release()
    return available

def make_stream_route(camera_id):

    def generate():
        cap = cameras[camera_id]
        while True:
            success, frame = cap.read()
            if not success:
                break
            ret, buffer = cv2.imencode('.jpg', frame)
            frame_bytes = buffer.tobytes()
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')

    def stream():
        return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')

    return stream

# Scan and create routes dynamically
for cam_id in detect_cameras():
    route = f"/stream/{cam_id}"
    app.add_url_rule(route, f'stream_{cam_id}', make_stream_route(cam_id))

@app.route('/camera_count')
def index():
    response = {
        'cameras': len(cameras),
        'status' : 'ok',
    }

    return jsonify(response)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, threaded=True)
