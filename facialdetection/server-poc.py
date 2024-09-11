import socket
import cv2
import pickle
import struct
import dlib
import numpy as np
import os
import time

# init stuff
detector = dlib.get_frontal_face_detector()
sp = dlib.shape_predictor('/Users/wormy/GitHub/visionbuzz/facialdetection/shape_predictor_68_face_landmarks.dat')
facerec = dlib.face_recognition_model_v1('/Users/wormy/GitHub/visionbuzz/facialdetection/dlib_face_recognition_resnet_model_v1.dat')
data_path = 'Users/wormy/GitHub/visionbuzz/facialdata'
if not os.path.exists(data_path):
    os.makedirs(data_path)
data_file = os.path.join(data_path, 'face_encodings.pkl')
if os.path.isfile(data_file):
    with open(data_file, 'rb') as f:
        known_face_encodings, known_face_names = pickle.load(f)
else:
    known_face_encodings = []
    known_face_names = []

# Setup socket for receiving stream
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
host_name = socket.gethostname()
host_ip = socket.gethostbyname(host_name)
port = 15
socket_address = (host_ip, port)
server_socket.bind(socket_address)
server_socket.listen(5)
print("Listening at:", socket_address)

client_socket, addr = server_socket.accept()
print('Connection from:', addr)
data = b""
payload_size = struct.calcsize("L")

def save_faces():
    with open(data_file, 'wb') as f:
        pickle.dump((known_face_encodings, known_face_names), f)

def recognize_faces(rgb_frame):
    labels = []
    faces = detector(rgb_frame, 0)
    for face in faces:
        shape = sp(rgb_frame, face)
        face_descriptor = facerec.compute_face_descriptor(rgb_frame, shape)
        current_face_encoding = np.array(face_descriptor)

        # Attempt to match face with known faces
        if known_face_encodings:
            distances = np.linalg.norm(known_face_encodings - current_face_encoding, axis=1)
            min_distance = np.min(distances)
            if min_distance < 0.6:
                index = np.argmin(distances)
                labels.append(known_face_names[index])
            else:
                labels.append("Unknown")
        else:
            labels.append("Unknown")
    return labels


# This loop runs and constantly receives frames from the client as a tuple where data is frame, Name.
# Name is always filled with placeholder data until the client sends a frame with a new Name string. this triggers the facial embedding routine of the alg.
try:
    while True:
        while len(data) < payload_size:
            data += client_socket.recv(4096)
        packed_msg_size = data[:payload_size]
        data = data[payload_size:]
        msg_size = struct.unpack("L", packed_msg_size)[0]

        while len(data) < msg_size:
            data += client_socket.recv(4096)
        frame_data = data[:msg_size]
        data = data[msg_size:]

        frame, name = pickle.loads(frame_data)
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        if name: 
            face = detector(rgb_frame, 0)[0]  # Assuming there's at least one face
            shape = sp(rgb_frame, face)
            face_descriptor = facerec.compute_face_descriptor(rgb_frame, shape)
            current_face_encoding = np.array(face_descriptor)
            known_face_encodings.append(current_face_encoding)
            known_face_names.append(name)
            save_faces()
            response = f"Face encoding for {name} saved."
        else:
            labels = recognize_faces(rgb_frame)
            response = ", ".join(labels) if labels else "No faces detected."

        client_socket.sendall(response.encode())

finally:
    client_socket.close()
    server_socket.close()