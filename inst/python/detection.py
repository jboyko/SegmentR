"""## Grounded Segment Anything (SAM)
THIS CODE IS BASED OFF OF EXISTING REPOS. MANY OF THESE FUNCTIONS I DID NOT WRITE AND SHOULD NOT GET CREDIT FOR.
Original file is located at
    https://colab.research.google.com/github/NielsRogge/Transformers-Tutorials/blob/master/Grounding%20DINO/GroundingDINO_with_Segment_Anything.ipynb

Use Grounding DINO to detect a given set of texts in the image. The output is a set of bounding boxes.
"""

from dataclasses import dataclass
from typing import Any, List, Dict, Optional, Union, Tuple  # Used for type annotations

import torch  # Used for checking CUDA availability and potentially for deep learning operations
from PIL import Image  # Used for image handling
from transformers import pipeline  # Used for zero-shot object detection


def detect(
    image: Image.Image,
    labels: List[str],
    threshold: float = 0.3,
    detector_id: Optional[str] = None
) -> List[Dict[str, Any]]:
    """
    Use Grounding DINO to detect a set of labels in an image in a zero-shot fashion.
    """
    device = "cuda" if torch.cuda.is_available() else "cpu"
    detector_id = detector_id if detector_id is not None else "IDEA-Research/grounding-dino-tiny"
    object_detector = pipeline(model=detector_id, task="zero-shot-object-detection", device=device)

    labels = [label if label.endswith(".") else label+"." for label in labels]

    results = object_detector(image,  candidate_labels=labels, threshold=threshold)
    results = [DetectionResult.from_dict(result) for result in results]

    return results
