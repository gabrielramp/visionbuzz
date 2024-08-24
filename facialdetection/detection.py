import dlib
import cv2
import numpy as np
import pickle
import os

#############################################
# this is what a celsius at 10pm looks like #
#############################################

# init face detector and facial landmark predictor
detector = dlib.get_frontal_face_detector()
sp = dlib.shape_predictor('/path/to/shape_predictor_68_face_landmarks.dat')
facerec = dlib.face_recognition_model_v1('/path/to/dlib_face_recognition_resnet_model_v1.dat')

# init camera
video_capture = cv2.VideoCapture(0)
video_capture.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
video_capture.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

# Load face encodings and names
data_path = './facialdata'
if not os.path.exists(data_path):
    os.makedirs(data_path)
data_file = os.path.join(data_path, 'face_encodings.pkl')

if os.path.isfile(data_file):
    with open(data_file, 'rb') as f:
        known_face_encodings, known_face_names = pickle.load(f)
else:
    known_face_encodings = []
    known_face_names = []

def save_faces():
    with open(data_file, 'wb') as f:
        pickle.dump((known_face_encodings, known_face_names), f)

def add_new_face(face_encoding, name):
    known_face_encodings.append(face_encoding)
    known_face_names.append(name)
    save_faces()

try:
    while True:
        ret, frame = video_capture.read()
        if not ret:
            print("Failed to grab video frame... this shouldn't happen oopsies")
            break

        small_frame = cv2.resize(frame, (0, 0), fx=0.5, fy=0.5)
        rgb_frame = cv2.cvtColor(small_frame, cv2.COLOR_BGR2RGB)
        faces = detector(rgb_frame, 0)

        for face in faces:
            x1, y1, x2, y2 = (face.left()*2, face.top()*2, face.right()*2, face.bottom()*2)
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)

            shape = sp(rgb_frame, face)
            face_descriptor = facerec.compute_face_descriptor(rgb_frame, shape)
            current_face_encoding = np.array(face_descriptor)

            name = "Unknown"
            if known_face_encodings:
                distances = np.linalg.norm(known_face_encodings - current_face_encoding, axis=1)
                min_distance = np.min(distances)
                if min_distance < 0.6:
                    index = np.argmin(distances)
                    name = known_face_names[index]

            cv2.rectangle(frame, (x1, y2 - 35), (x2, y2), (0, 255, 0), cv2.FILLED)
            font = cv2.FONT_HERSHEY_DUPLEX
            cv2.putText(frame, name, (x1 + 6, y2 - 6), font, 0.5, (255, 255, 255), 1)

        cv2.imshow('Video', frame)

        # TODO: Change this 'key' listener to use our hardware button
        key = cv2.waitKey(1) & 0xFF
        if key == ord('w'):
            print("Learning sequence initiated by button press")
            if len(faces) == 1:
                for face in faces:
                    shape = sp(rgb_frame, face)
                    face_descriptor = facerec.compute_face_descriptor(rgb_frame, shape)
                    current_face_encoding = np.array(face_descriptor)

                    print("Enter name for the new face:")
                    # TODO: Change this input to come from NOT the console
                    new_name = input()
                    add_new_face(current_face_encoding, new_name)
            else: # If there are too many faces in the frame
                # TODO: Play a sound or error vibration to let the user know to try again.
                print("Multiple faces detected. Try again with only one face in the frame.")

finally:
    video_capture.release()
    cv2.destroyAllWindows()
