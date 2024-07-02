"""## Segmentation
THIS CODE IS BASED OFF OF EXISTING REPOS. MANY OF THESE FUNCTIONS I DID NOT WRITE AND SHOULD NOT GET CREDIT FOR.
Original file is located at
    https://colab.research.google.com/github/NielsRogge/Transformers-Tutorials/blob/master/Grounding%20DINO/GroundingDINO_with_Segment_Anything.ipynb

Running SAM
"""

from typing import Any, List, Dict, Optional, Union, Tuple  # Type annotations
from PIL import Image  # Image handling
import torch  # CUDA availability and deep learning operations
from transformers import AutoModelForMaskGeneration, AutoProcessor  # Model loading and processing
import numpy as np  # Array handling

def grounded_segmentation(
    image: Union[Image.Image, str],
    labels: List[str],
    threshold: float = 0.3,
    polygon_refinement: bool = False,
    detector_id: Optional[str] = None,
    segmenter_id: Optional[str] = None
) -> Tuple[np.ndarray, List[DetectionResult]]:
    if isinstance(image, str):
        image = load_image(image)

    detections = detect(image, labels, threshold, detector_id)
    detections = segment(image, detections, polygon_refinement, segmenter_id)

    return np.array(image), detections