import numpy as np
from dataclasses import dataclass
from deepface import DeepFace

class FaceService:
    def __init__(self, config):
        self.detector = YuNetMultiViewAligner(
            model_path=config.YUNET_PATH,
            desired_size=160,
            confidence_threshold=0.9,
            nms_threshold=0.3,
            top_k=5000
        )

    def get_faces(self, rgb_frame):
        """
        Detects faces in frame, returns cropped re-aligned images of faces
        """
        faces = self.detector(rgb_frame, 0)
        if len(faces) == 0:
            return []

    # TODO: Should we make this a queue or something to avoid overloading the server?
    # TODO: Set up batching if we move to GPU host 
    def get_face_embeds(self, img):
        """
        From frame, return list of embeddings of faces
        """
        if img.dtype != np.uint8:
            img = (img * 255).astype(np.uint8)

        faces = self.get_faces(img)
        embedding_list = []

        for face in faces:
            embedding = DeepFace.represent(aligned_face, model_name="ArcFace",
                                           enforce_detection=False, align=False,
                                           detector_backend="skip")[0]['embedding']
            embedding_list.append(np.array(embedding))

        return embedding_list


