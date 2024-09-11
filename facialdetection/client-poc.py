import cv2
import socket
import pickle
import struct
import time

# init stuff
video_capture = cv2.VideoCapture(0)
video_capture.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
video_capture.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
host_ip = '127.0.0.1'  # Replace with Device 2's IP
port = 15
client_socket.connect((host_ip, port))

# init timeline stuff
active_faces = {}
exit_buffer = 3 # seconds for exit buffer 
start_time = time.time()

def log_face_time(name, action, time_stamp):
    if name == 'No faces detected.' or name == 'Unknown':
        return
    time_str = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time_stamp))
    log_entry = f"{time_str} - {name} {action}\n"
    with open('face_timeline.log', 'a') as file:
        file.write(log_entry)

try:
    while video_capture.isOpened():
        ret, frame = video_capture.read()
        if not ret:
            print("Failed to grab frame")
            break

        cv2.imshow('Video', frame)
        key = cv2.waitKey(1) & 0xFF

        # Here is where we're pausing the video stream to attach a name label to the frame.
        # TODO: Replace key press with hardware button press
        if key == ord('p'):
            print("Enter name for the new face:")
            name = input() 
        else:
            name = None 

        data = pickle.dumps((frame, name))
        message_size = struct.pack("L", len(data))
        client_socket.sendall(message_size + data)

        data = client_socket.recv(4096)
        labels = data.decode().split(', ')
        print("Received back:", ', '.join(labels))

        current_seen = set(labels)
        current_time = time.time()

        # Update active faces and log timeline
        for label in current_seen:
            if label not in active_faces:
                # New face entering
                log_face_time(label, 'entered', current_time)
            active_faces[label] = current_time  # Update last seen time

        # Check for faces that may have exited
        for name in list(active_faces):
            if name not in current_seen and current_time - active_faces[name] > exit_buffer:
                # Face has exited
                log_face_time(name, 'exited', current_time)
                del active_faces[name]

finally:
    video_capture.release()
    client_socket.close()
    cv2.destroyAllWindows()