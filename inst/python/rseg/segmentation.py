from typing import List, Dict, Any
from PIL import Image
import torch
from transformers import AutoModelForMaskGeneration, AutoProcessor

from .utils import DetectionResult, get_boxes, refine_masks

def segment(
    image: Image.Image,
    detection_results: List[DetectionResult],
    polygon_refinement: bool = False,
    segmenter_id: str = "Zigeng/SlimSAM-uniform-77"
) -> List[DetectionResult]:
    device = "cuda" if torch.cuda.is_available() else "mps" if torch.backends.mps.is_available() else "cpu"

    segmentator = AutoModelForMaskGeneration.from_pretrained(segmenter_id).to(device)
    processor = AutoProcessor.from_pretrained(segmenter_id)

    boxes = get_boxes(detection_results)
    
    # Process the image without resizing first to get original dimensions
    inputs = processor(images=image, input_boxes=boxes, return_tensors="pt", do_resize=False)
    original_height, original_width = inputs["pixel_values"].shape[-2:]
    
    # Now process with default settings
    inputs = processor(images=image, input_boxes=boxes, return_tensors="pt")
    inputs = {k: v.to(torch.float32) if torch.is_tensor(v) else v for k, v in inputs.items()}
    inputs = {k: v.to(device) if torch.is_tensor(v) else v for k, v in inputs.items()}

    outputs = segmentator(**inputs)
    
    # Get reshaped size from the processed input tensor
    reshaped_height, reshaped_width = inputs["pixel_values"].shape[-2:]
    
    masks = processor.post_process_masks(
        masks=outputs.pred_masks,
        original_sizes=[(original_height, original_width)],
        reshaped_input_sizes=[(reshaped_height, reshaped_width)]
    )[0]

    masks = refine_masks(masks, polygon_refinement)

    for detection_result, mask in zip(detection_results, masks):
        detection_result.mask = mask

    return detection_results