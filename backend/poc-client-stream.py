import cv2
import requests
import time
import threading

# Initialize the video capture
video_capture = cv2.VideoCapture(0)

# Set frame dimensions (optional)
video_capture.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
video_capture.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

# Server configuration
SERVER_URL = 'http://localhost:5000/api/v1/upload_image'
# Replace with your actual JWT token
JWT_TOKEN = 'super-secret-key'

# Headers for the HTTP request
headers = {
    'Authorization': f'Bearer {JWT_TOKEN}',
}

# Initialize variables
active_faces = {}
exit_buffer = 3  # seconds for exit buffer
last_sent_time = 0
send_interval = 1  # seconds
name_to_save = None
lock = threading.Lock()

def send_frame(frame, name=None):
    global active_faces
    ret, jpeg = cv2.imencode('.jpg', frame)
    if not ret:
        print("Failed to encode frame")
        return

    files = {
        'image': ('frame.jpg', jpeg.tobytes(), 'image/jpeg')
    }
    data = {}
    if name:
        data['name'] = name

    try:
        response = requests.post(SERVER_URL, headers=headers, files=files, data=data)
        if response.status_code == 200:
            json_response = response.json()
            labels = json_response.get('message', '').split(', ')
            print("Received back:", ', '.join(labels))

            current_seen = set(labels)
            current_time = time.time()

            with lock:
                for label in current_seen:
                    if label not in active_faces:
                        log_face_time(label, 'entered', current_time)
                    active_faces[label] = current_time

                for name in list(active_faces):
                    if name not in current_seen and current_time - active_faces[name] > exit_buffer:
                        log_face_time(name, 'exited', current_time)
                        del active_faces[name]
        else:
            print("Server returned an error:", response.text)
    except Exception as e:
        print("An error occurred while sending the frame:", str(e))

def log_face_time(name, action, time_stamp):
    if name == 'No faces detected.' or name == 'Unknown' or not name:
        return
    time_str = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time_stamp))
    log_entry = f"{time_str} - {name} {action}\n"
    with open('face_timeline.log', 'a') as file:
        file.write(log_entry)

def capture_and_send_frames():
    global last_sent_time, name_to_save
    while video_capture.isOpened():
        ret, frame = video_capture.read()
        if not ret:
            print("Failed to grab frame")
            break

        cv2.imshow('Video', frame)
        key = cv2.waitKey(1) & 0xFF

        current_time = time.time()
        if current_time - last_sent_time >= send_interval:
            last_sent_time = current_time
            threading.Thread(target=send_frame, args=(frame, name_to_save)).start()
            name_to_save = None

        # TODO: change this to listen for a button press instead of a keystroke
        if key == ord('q'):
            print("Enter name for the new face:")
            name_to_save = input().strip()
            if name_to_save == '':
                name_to_save = None
        elif key == 27: # esc key to end
            break

    video_capture.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    capture_and_send_frames()
