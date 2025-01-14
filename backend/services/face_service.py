import os
import pickle
import numpy as np
import dlib
import cv2


class FaceService:
    def __init__(self, config):
        self.detector = dlib.get_frontal_face_detector()
        self.sp = dlib.shape_predictor(config.SHAPE_PREDICTOR_PATH)
        self.facerec = dlib.face_recognition_model_v1(config.FACE_REC_MODEL_PATH)

        # Data directory and file setup
        # TODO: DOES THIS ONLY DO IT FOR ONE PERSON? WE NEED FOR EVERYONE
        self.data_path = config.FACE_DATA_PATH
        self.match_threshold = config.FACE_MATCH_THRESHOLD

        os.makedirs(self.data_path, exist_ok=True)
        self.data_file = os.path.join(self.data_path, "face_encodings.pkl")

        # Load known faces
        self.user_face_data = self._load_face_data()

    def _load_face_data(self):
        if os.path.isfile(self.data_file):
            with open(self.data_file, "rb") as f:
                return pickle.load(f)
        return {}

    def _save_faces(self):
        with open(self.data_file, "wb") as f:
            pickle.dump(self.user_face_data, f)

    def get_user_face_data(self, user_id):
        if user_id not in self.user_face_data:
            self.user_face_data[user_id] = ([], [])
        return self.user_face_data[user_id]

    def set_user_face_data(self, user_id, encodings, names):
        self.user_face_data[user_id] = (encodings, names)
        self._save_faces()

    def recognize_faces_per_user(
        self, rgb_frame, known_face_encodings, known_face_names
    ):
        labels = []
        faces = self.detector(rgb_frame, 0)

        for face in faces:
            shape = self.sp(rgb_frame, face)
            face_descriptor = self.facerec.compute_face_descriptor(rgb_frame, shape)
            current_face_encoding = np.array(face_descriptor)

            # Attempt to match face with known faces
            # TODO: Is this really the best way to match embeddings?
            if known_face_encodings:
                distances = np.linalg.norm(
                    known_face_encodings - current_face_encoding, axis=1
                )
                min_distance = np.min(distances)
                if min_distance < self.match_threshold:
                    index = np.argmin(distances)
                    labels.append(known_face_names[index])
                else:
                    labels.append("Unknown")
            else:
                labels.append("Unknown")

        return labels

    def detect_and_encode_face(self, rgb_frame):
        faces = self.detector(rgb_frame, 0)
        if len(faces) == 0:
            return None, "No face detected in the image"
        elif len(faces) > 1:
            return (
                None,
                "Multiple faces detected. Please upload an image with a single face",
            )

        face = faces[0]
        shape = self.sp(rgb_frame, face)
        face_descriptor = self.facerec.compute_face_descriptor(rgb_frame, shape)
        return np.array(face_descriptor), None
