import numpy as np
import dlib

class FaceService:
    def __init__(self, config):
        self.detector = dlib.get_frontal_face_detector()
        self.sp = dlib.shape_predictor("../" + config.SHAPE_PREDICTOR_PATH)
        self.facerec = dlib.face_recognition_model_v1("../" + config.FACE_REC_MODEL_PATH)

    # TODO: This only works well for frontal face views. Replace with multi-view alignment approach
    def get_aligned_faces(self, rgb_frame, face_shapes):
        """
        Realigns faces based on information in face_shapes, returns cropped face
        """
        return dlib.get_face_chips(rgb_frame, face_shapes)

    # TODO: Replace detector with YuNet (dlib detector isnt great)
    def get_faces(self, rgb_frame):
        """
        Detects faces in frame, returns cropped re-aligned images of faces
        """
        face_shapes = self.detector(rgb_frame, 0) 
        return self.get_aligned_faces(rgb_frame, face_shapes)

    # TODO: Should we make this a queue or something to avoid overloading the server?
    # TODO: Should we add batching? (if host has GPU)
    def get_face_embeds(self, rgb_frame):
        """
        From frame, return list of embeddings of faces
        """
        faces = self.get_faces(rgb_frame)
        embedding_list = []

        for face in faces:
            embedding = self.facerec.compute_face_descriptor(face)
            embedding_list.append(np.array(embedding))

        return embedding_list

