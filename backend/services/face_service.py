import numpy as np
from dataclasses import dataclass
from deepface import DeepFace
from .face_alignment import *
import time
import onnx
import onnxruntime as ort


class FaceService:
    def __init__(self, config):
        self.detector = YuNetMultiViewAligner(
            model_path=config.YUNET_PATH,
            desired_size=112,
            confidence_threshold=0.8,
            nms_threshold=0.3,
            top_k=100,
        )

        if config.USE_QUANTIZED:
            options = ort.SessionOptions()
            options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
            options.intra_op_num_threads = 2  # Match CPU cores
            options.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL

            self.model = ort.InferenceSession(
                config.ARCFACE_INT8_PATH,
                providers=["CPUExecutionProvider"],
                sess_options=options,
            )
        else:
            self.model = ort.InferenceSession(
                config.ARCFACE_PATH,
                providers=["CUDAExecutionProvider", "CPUExecutionProvider"],
            )

    def get_faces(self, rgb_frame):
        """
        Detects faces in frame, returns cropped re-aligned images of faces
        """
        faces = self.detector.detect_and_align(rgb_frame)
        if faces is None or len(faces) == 0:
            return []

        return faces

    # TODO: Should we make this a queue or something to avoid overloading the server?
    # TODO: Set up batching if we move to GPU host
    def get_face_embeds(self, img):
        """
        From frame, return list of embeddings of faces
        """

        # needs to be BGR for arcface
        img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)

        if img.dtype != np.uint8:
            img = (img * 255).astype(np.uint8)

        faces = self.get_faces(img)
        embedding_list = []

        for face in faces:
            aligned_face = face.aligned_face
            img_processed = aligned_face.astype(np.float32)
            img_processed = np.expand_dims(img_processed, axis=0)
            img_processed = np.transpose(img_processed, (0, 3, 1, 2))

            input_name = self.model.get_inputs()[0].name
            output_name = self.model.get_outputs()[0].name

            embedding = self.model.run([output_name], {input_name: img_processed})[0]
            embedding = embedding.flatten()
            embedding /= np.linalg.norm(embedding)
            embedding_list.append(np.array(embedding))

        return embedding_list
