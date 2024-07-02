from typing import List, Dict, Any
from PIL import Image
from transformers import pipeline
import torch

from .utils import DetectionResult

def detect(
    image: Image.Image,
    labels: List[str],
    threshold: float = 0.3,
    detector_id: str = "IDEA-Research/grounding-dino-tiny"
) -> List[DetectionResult]:
    """
    Use Grounding DINO to detect a set of labels in an image in a zero-shot fashion.
    """
    device = "cuda" if torch.cuda.is_available() else "cpu"
    object_detector = pipeline(model=detector_id, task="zero-shot-object-detection", device=device)

    labels = [label if label.endswith(".") else label+"." for label in labels]

    results = object_detector(image, candidate_labels=labels, threshold=threshold)
    results = [DetectionResult.from_dict(result) for result in results]

    return results
