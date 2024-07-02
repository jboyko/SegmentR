import argparse
import json
import numpy as np
from PIL import Image

from rsegcol.detection import detect
from rsegcol.segmentation import segment
from rsegcol.utils import load_image
from rsegcol.visualization import plot_detections

def grounded_segmentation(
    image: Image.Image,
    labels: list,
    threshold: float = 0.3,
    polygon_refinement: bool = False,
    detector_id: str = "IDEA-Research/grounding-dino-tiny",
    segmenter_id: str = "Zigeng/SlimSAM-uniform-77"
) -> tuple:
    print('Beginning detection...')
    detections = detect(image, labels, threshold, detector_id)
    print('Detection complete.')
    print('Beginning segmentation...')
    detections = segment(image, detections, polygon_refinement, segmenter_id)
    print('Segmentation complete.')
    return np.array(image), detections

def main():
    parser = argparse.ArgumentParser(description="Run grounded segmentation on an image.")
    parser.add_argument("--image", type=str, required=True, help="Path or URL to the input image")
    parser.add_argument("--labels", type=str, required=True, help="JSON string of labels to detect")
    parser.add_argument("--threshold", type=float, default=0.3, help="Detection threshold")
    parser.add_argument("--polygon_refinement", action="store_true", help="Whether to refine polygons")
    parser.add_argument("--detector_id", type=str, default="IDEA-Research/grounding-dino-tiny", help="ID of the detector model")
    parser.add_argument("--segmenter_id", type=str, default="Zigeng/SlimSAM-uniform-77", help="ID of the segmenter model")
    parser.add_argument("--save_plot", type=str, default=None, help="Path to save the plotted results")
    parser.add_argument("--save_json", type=str, default=None, help="Path to save the detection results as JSON")
    
    args = parser.parse_args()
    
    # Load image
    image = load_image(args.image)
    
    # Convert labels string to list
    labels = json.loads(args.labels)
    
    # Run grounded segmentation
    image_array, detections = grounded_segmentation(
        image=image,
        labels=labels,
        threshold=args.threshold,
        polygon_refinement=args.polygon_refinement,
        detector_id=args.detector_id,
        segmenter_id=args.segmenter_id
    )
    
    # Plot and save results if requested
    if args.save_plot:
        plot_detections(image_array, detections, args.save_plot)
    
    # Save detections as JSON if requested
    if args.save_json:
        detections_dict = [
            {
                "label": d.label,
                "score": d.score,
                "box": d.box.__dict__,
                "mask": d.mask.tolist() if d.mask is not None else None
            } for d in detections
        ]
        with open(args.save_json, 'w') as f:
            json.dump(detections_dict, f)
    
    print("Grounded segmentation completed successfully.")

if __name__ == "__main__":
    main()
