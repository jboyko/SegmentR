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

def segment(
    image: Image.Image,
    detection_results: List[Dict[str, Any]],
    polygon_refinement: bool = False,
    segmenter_id: Optional[str] = None
) -> List[DetectionResult]:
    """
    Use Segment Anything (SAM) to generate masks given an image + a set of bounding boxes.
    """
    device = "cuda" if torch.cuda.is_available() else "cpu"
    segmenter_id = segmenter_id if segmenter_id is not None else "facebook/sam-vit-base"

    segmentator = AutoModelForMaskGeneration.from_pretrained(segmenter_id).to(device)
    processor = AutoProcessor.from_pretrained(segmenter_id)

    boxes = get_boxes(detection_results)
    inputs = processor(images=image, input_boxes=boxes, return_tensors="pt").to(device)

    outputs = segmentator(**inputs)
    masks = processor.post_process_masks(
        masks=outputs.pred_masks,
        original_sizes=inputs.original_sizes,
        reshaped_input_sizes=inputs.reshaped_input_sizes
    )[0]

    masks = refine_masks(masks, polygon_refinement)

    for detection_result, mask in zip(detection_results, masks):
        detection_result.mask = mask

    return detection_results
