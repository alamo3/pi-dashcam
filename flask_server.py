from importlib import reload

from flask import Flask, Response, jsonify
import cv2

from camera.camera_manager import CameraManager

app = Flask(__name__)

cam_manager = CameraManager(max_cameras=4, camera_res_x=640, camera_res_y=480)

@app.route('/camera_count')
def index():
    response = {
        'cameras': cam_manager.get_num_cameras(),
        'status' : 'ok',
    }

    return jsonify(response)

if __name__ == '__main__':
    cam_manager.detect_cameras()
    cam_manager.add_camera_routes(app)
    cam_manager.start_recording(0)
    app.run(host='0.0.0.0', port=5000, threaded=True, debug=False)
