import argparse
import json
import numpy as np
from PIL import Image

from rseg.detection import detect
from rseg.segmentation import segment
from rseg.utils import load_image, DetectionResult, BoundingBox
from rseg.visualization import plot_detections

def main(args):
    # Load image
    image = load_image(args.image)
    
    # Convert labels string to list
    labels = json.loads(args.labels)
    
    # Handle custom bounding box if provided
    if args.custom_bbox:
        custom_bbox = json.loads(args.custom_bbox)
        detection_results = [DetectionResult(
            score=1.0,
            label="custom",
            box=BoundingBox(
                xmin=custom_bbox[0],
                ymin=custom_bbox[1],
                xmax=custom_bbox[2],
                ymax=custom_bbox[3]
            )
        )]
    else:
        # Run detection
        detection_results = detect(
            image=image,
            labels=labels,
            threshold=args.threshold,
            detector_id=args.detector_id
        )
        # If no detections found, return empty results
    if not detection_results:
        if args.save_json:
            with open(args.save_json, 'w') as f:
                json.dump([], f)
        print("No detections found.")
        return

    # Run segmentation
    segmentation_results = segment(
        image=image,
        detection_results=detection_results,
        polygon_refinement=args.polygon_refinement,
        segmenter_id=args.segmenter_id
    )
    
    # Plot and save results if requested
    if args.save_plot or args.show_plot:
        plot_detections(
            np.array(image), 
            segmentation_results, 
            save_name=args.save_plot,
            show=args.show_plot
        )

    
    # Always save json results
    detections_dict = [
        {
            "label": d.label,
            "score": d.score,
            "box": d.box.__dict__,
            "mask": d.mask.tolist() if d.mask is not None else None
        } for d in segmentation_results
    ]
    with open(args.save_json, 'w') as f:
        json.dump(detections_dict, f)
    
    print("Grounded segmentation completed successfully.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run grounded segmentation on an image.")
    parser.add_argument("--image", type=str, required=True, help="Path to the input image")
    parser.add_argument("--labels", type=str, required=True, help="JSON string of labels to detect")
    parser.add_argument("--threshold", type=float, default=0.1, help="Detection threshold")
    parser.add_argument("--polygon_refinement", action="store_true", help="Whether to refine polygons")
    parser.add_argument("--detector_id", type=str, default="IDEA-Research/grounding-dino-tiny", help="ID of the detector model")
    parser.add_argument("--segmenter_id", type=str, default="Zigeng/SlimSAM-uniform-77", help="ID of the segmenter model")
    parser.add_argument("--save_plot", type=str, default=None, help="Path to save the plotted results")
    parser.add_argument("--show_plot", action="store_true", help="Whether to display the plot")
    parser.add_argument("--save_json", type=str, default=None, help="Path to save the detection results as JSON")
    parser.add_argument("--custom_bbox", type=str, default=None, help="JSON string of custom bounding box [xmin, ymin, xmax, ymax]")
    
    args = parser.parse_args()
    main(args)