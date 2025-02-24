import cv2
import numpy as np
from dataclasses import dataclass


@dataclass
class FaceAlignment:
    """Stores face alignment results"""

    raw_face: np.ndarray
    aligned_face: np.ndarray
    box: np.ndarray
    landmarks: np.ndarray


# Order: left eye, right eye, nose, left mouth, right mouth
# TODO: obtain a better three_quarter and profile set
CANONICAL_LANDMARK_COORDS = {
    "frontal": np.float32(
        [
            [30.2946, 51.6963],
            [65.5318, 51.5014],
            [48.0252, 71.7366],
            [33.5493, 92.3655],
            [62.7299, 92.2041],
        ]
    )
    / 112.0,
    "three_quarter": np.float32(
        [[0.3, 0.35], [0.55, 0.35], [0.45, 0.5], [0.3, 0.7], [0.55, 0.7]]
    ),
    "profile": np.float32(
        [[0.3, 0.35], [0.45, 0.35], [0.4, 0.5], [0.3, 0.7], [0.45, 0.7]]
    ),
}


class YuNetMultiViewAligner:
    def __init__(
        self,
        model_path: str,
        desired_size: int = 256,
        confidence_threshold: float = 0.9,
        nms_threshold: float = 0.3,
        top_k: int = 5000,
    ):

        self.desired_size = desired_size
        self.detector = cv2.FaceDetectorYN.create(
            model_path,
            "",
            (desired_size, desired_size),
            confidence_threshold,
            nms_threshold,
            top_k,
        )

        self.REFERENCE_POINTS = CANONICAL_LANDMARK_COORDS

    def _estimate_pose(self, landmarks) -> str:
        """
        Estimate pose based on landmarks
        """

        left_eye = landmarks[0]
        right_eye = landmarks[1]
        nose = landmarks[2]

        eye_midpoint = (left_eye + right_eye) / 2
        eye_distance = np.linalg.norm(right_eye - left_eye)
        displacement = (nose[0] - eye_midpoint[0]) / eye_distance

        if abs(displacement) < 0.15:
            pose = "frontal"
        elif abs(displacement) < 1.0:
            pose = "three_quarter"
        else:
            pose = "profile"

        return pose

    def _get_transformation_matrix(self, box, landmarks, pose) -> np.ndarray:
        """
        Calculate affine transform from observed landmarks to canonical
        """
        dst_points = self.REFERENCE_POINTS[pose] * self.desired_size

        try:
            # Note, affinePartial does not allow sheering (desired)
            M = cv2.estimateAffinePartial2D(landmarks, dst_points, method=cv2.LMEDS)[0]
        except cv2.error as e:  # Fall back to bounding box
            M = self._get_box_transform(box)

        return M

    def _get_box_transform(self, box: np.ndarray):
        """
        Create matrix to scale & translate bounding box appropriately
        """

        x, y, w, h = box
        scale = self.desired_size / max(w, h)
        displace_x = self.desired_size / 2 - scale * (x + w / 2)
        displace_y = self.desired_size / 2 - scale * (y + h / 2)

        M = np.array([[scale, 0, displace_x], [0, scale, displace_y]], dtype=np.float32)

        return M

    def _align_face(self, image, box, landmarks, pose, warp) -> np.ndarray:
        if warp:
            M = self._get_transformation_matrix(box, landmarks, pose)
        else:
            M = self._get_box_transform(box)

        aligned_face = cv2.warpAffine(
            image,
            M,
            (self.desired_size, self.desired_size),
            flags=cv2.INTER_CUBIC,
            borderMode=cv2.BORDER_REPLICATE,
        )

        # Mirror if right profile
        if pose == "profile" and landmarks[0][0] > landmarks[1][0]:
            aligned_face = cv2.flip(aligned_face, 1)

        return aligned_face

    def detect_and_align(self, image, warp=True):
        """
        Detect and align faces in the image.
        """

        # Set input size for detector
        self.detector.setInputSize((image.shape[1], image.shape[0]))

        _, faces = self.detector.detect(image)

        if faces is None:
            return None

        results = []
        for face in faces:
            landmarks = face[4:14].reshape(-1, 2)
            box = face[:4]

            x, y, w, h = box
            x, y, w, h = int(x), int(y), int(w), int(h)
            raw_face = image[y : y + h, x : x + w]

            pose = self._estimate_pose(landmarks)
            aligned_face = self._align_face(image, box, landmarks, pose, warp)

            results.append(
                FaceAlignment(
                    raw_face=raw_face,
                    aligned_face=aligned_face,
                    box=box,
                    landmarks=landmarks - [x, y],
                )
            )

        return results
