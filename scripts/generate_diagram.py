#!/usr/bin/env python3
"""
Alternative WaveDrom diagram generator using wavedrom Python package.
Use this if wavedrom-cli has issues.
"""

import json
import sys
from pathlib import Path
import glob

try:
    import wavedrom
    from cairosvg import svg2png
except ImportError:
    print("ERROR: Required packages not installed.")
    print("Install with: pip3 install wavedrom cairosvg")
    sys.exit(1)


def generate_diagram(json_file: str, output_svg: str, output_png: str = None):
    """Generate SVG and optionally PNG from WaveDrom JSON."""
    
    # Load JSON
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    # Generate SVG (returns Drawing object)
    drawing = wavedrom.render(json.dumps(data))
    
    # Save SVG
    drawing.saveas(output_svg)
    print(f"✓ Generated SVG: {output_svg}")
    
    # Generate PNG if requested
    if output_png:
        try:
            # Read the SVG file we just created
            with open(output_svg, 'rb') as f:
                svg_data = f.read()
            
            svg2png(bytestring=svg_data, 
                    write_to=output_png,
                    scale=3.0)  # 3x scale for better quality
            print(f"✓ Generated PNG: {output_png}")
        except Exception as e:
            print(f"⚠ PNG generation failed: {e}")
            print("  (SVG is still available)")


def generate_all_diagrams(docs_dir: str, build_dir: str):
    """Generate all timing diagrams from docs directory."""
    
    # Find all timing diagram JSON files
    pattern = f"{docs_dir}/timing_diagram*.json"
    json_files = glob.glob(pattern)
    
    if not json_files:
        print(f"ERROR: No timing diagram files found in {docs_dir}")
        sys.exit(1)
    
    print(f"Found {len(json_files)} diagram(s) to generate:")
    
    for json_file in sorted(json_files):
        basename = Path(json_file).stem
        svg_file = f"{docs_dir}/{basename}.svg"
        png_file = f"{build_dir}/{basename}.png"
        
        print(f"\nProcessing {basename}...")
        generate_diagram(json_file, svg_file, png_file)
    
    print(f"\n✓ All diagrams generated successfully!")


if __name__ == "__main__":
    if len(sys.argv) == 1:
        # No arguments - generate all diagrams
        generate_all_diagrams("docs", "build")
    elif len(sys.argv) >= 3:
        # Specific file mode
        json_file = sys.argv[1]
        output_svg = sys.argv[2]
        output_png = sys.argv[3] if len(sys.argv) > 3 else None
        
        if not Path(json_file).exists():
            print(f"ERROR: Input file not found: {json_file}")
            sys.exit(1)
        
        generate_diagram(json_file, output_svg, output_png)
    else:
        print("Usage:")
        print("  generate_diagram.py                              # Generate all diagrams")
        print("  generate_diagram.py <input.json> <out.svg> [out.png]  # Generate specific diagram")
        sys.exit(1)

