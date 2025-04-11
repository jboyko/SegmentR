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
    
    # Store original size for later use
    original_size = image.size  # (width, height)
    
    # Option 1: Allow resizing (simpler approach)
    inputs = processor(images=image, input_boxes=boxes, return_tensors="pt")
    
    # Or Option 2: Manually resize first while preserving aspect ratio
    # max_size = 1024
    # width, height = image.size
    # scale = min(max_size / width, max_size / height)
    # new_width, new_height = int(width * scale), int(height * scale)
    # resized_image = image.resize((new_width, new_height), Image.BILINEAR)
    # inputs = processor(images=resized_image, input_boxes=boxes, return_tensors="pt", do_resize=False)
    
    inputs = {k: v.to(torch.float32) if torch.is_tensor(v) else v for k, v in inputs.items()}
    inputs = {k: v.to(device) if torch.is_tensor(v) else v for k, v in inputs.items()}

    outputs = segmentator(**inputs)
    
    # Get reshaped size from the processed input tensor
    reshaped_height, reshaped_width = inputs["pixel_values"].shape[-2:]
    
    original_sizes = [(int(size[0].item()), int(size[1].item())) for size in inputs["original_sizes"].cpu()]
    reshaped_sizes = [(int(size[0].item()), int(size[1].item())) for size in inputs["reshaped_input_sizes"].cpu()]
    
    masks = processor.post_process_masks(
        outputs.pred_masks.cpu(),
        original_sizes=original_sizes,
        reshaped_input_sizes=reshaped_sizes
    )[0]

    masks = refine_masks(masks, polygon_refinement)
    
    for detection_result, mask in zip(detection_results, masks):
        detection_result.mask = mask
            
    return detection_results