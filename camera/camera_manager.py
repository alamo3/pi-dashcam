import cv2

from camera.camera_source import CameraSource


class CameraManager:

    def __init__(self, max_cameras, camera_res_x, camera_res_y):
        self.cameras = []
        self.camera_res_x = camera_res_x
        self.camera_res_y = camera_res_y
        self.max_cameras = max_cameras


        # Function to test available camera indices
    def detect_cameras(self):
        for i in range(self.max_cameras):
            camera_source_test = CameraSource(i, self.camera_res_x, self.camera_res_y)

            if camera_source_test.ok:
                self.cameras.append(camera_source_test)


    def get_num_cameras(self):
        return len(self.cameras)

    def add_camera_routes(self, app):

        for cam in self.cameras:
            cam.add_app_route(app)

    def start_recording(self, cam_id):
        for cam in self.cameras:
            if cam.camera_id == cam_id:
                cam.start_recording()
