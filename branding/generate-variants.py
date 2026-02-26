#!/usr/bin/env python3
"""Generate color variants for TokenCap brand assets."""

import os
import re

BRAND_COLOR = "rgb(217,123,63)"
SECONDARY_COLOR = "rgb(230,140,75)"
TERTIARY_COLOR = "rgb(250,190,174)"
WHITE = "rgb(255,255,255)"
BLACK = "rgb(0,0,0)"
DARK_BG = "rgb(26,26,46)"

# Background rect pattern (first path, full canvas rect)
BG_PATTERN = re.compile(
    r'<path d="M 0 0 L 2048 0 L 2048 2048 L 0 2048 L 0 0 z" fill="[^"]*" transform="[^"]*"></path>'
)

def read_svg(path):
    with open(path, 'r') as f:
        return f.read()

def write_svg(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print(f"  -> {path}")

def remove_bg(svg):
    return BG_PATTERN.sub('', svg, count=1)

def recolor(svg, old, new):
    return svg.replace(f'fill="{old}"', f'fill="{new}"')

def generate_variants(src_path, dst_dir, prefix):
    svg = read_svg(src_path)

    # 1. Color (as-is)
    write_svg(f"{dst_dir}/{prefix}-color.svg", svg)

    # 2. Color transparent (remove bg)
    write_svg(f"{dst_dir}/{prefix}-color-transparent.svg", remove_bg(svg))

    # 3. Black
    black = recolor(svg, BRAND_COLOR, BLACK)
    black = recolor(black, SECONDARY_COLOR, BLACK)
    black = recolor(black, TERTIARY_COLOR, BLACK)
    write_svg(f"{dst_dir}/{prefix}-black.svg", black)

    # 4. Black transparent
    write_svg(f"{dst_dir}/{prefix}-black-transparent.svg", remove_bg(black))

    # 5. White on dark
    # Step 1: bg -> dark
    wod = BG_PATTERN.sub(
        f'<path d="M 0 0 L 2048 0 L 2048 2048 L 0 2048 L 0 0 z" fill="{DARK_BG}" transform="translate(0,0)"></path>',
        svg, count=1
    )
    # Step 2: brand colors -> white
    wod = recolor(wod, BRAND_COLOR, WHITE)
    wod = recolor(wod, SECONDARY_COLOR, WHITE)
    wod = recolor(wod, TERTIARY_COLOR, WHITE)
    # Step 3: remaining white detail shapes -> dark
    # The original white details are now indistinguishable from our new whites
    # So we need a two-pass approach: first mark brand-to-white, then original-white-to-dark
    # Re-do with placeholder
    wod = BG_PATTERN.sub(
        f'<path d="M 0 0 L 2048 0 L 2048 2048 L 0 2048 L 0 0 z" fill="{DARK_BG}" transform="translate(0,0)"></path>',
        svg, count=1
    )
    wod = recolor(wod, WHITE, DARK_BG)  # original white details -> dark
    wod = recolor(wod, BRAND_COLOR, WHITE)  # brand -> white
    wod = recolor(wod, SECONDARY_COLOR, WHITE)
    wod = recolor(wod, TERTIARY_COLOR, WHITE)
    write_svg(f"{dst_dir}/{prefix}-white-on-dark.svg", wod)

    # 6. White transparent
    wt = remove_bg(svg)
    wt = recolor(wt, WHITE, "rgb(200,200,200)")  # temp placeholder for white details
    wt = recolor(wt, BRAND_COLOR, WHITE)
    wt = recolor(wt, SECONDARY_COLOR, WHITE)
    wt = recolor(wt, TERTIARY_COLOR, WHITE)
    write_svg(f"{dst_dir}/{prefix}-white-transparent.svg", wt)

if __name__ == "__main__":
    base = os.path.dirname(os.path.abspath(__file__))

    print("=== Generating icon variants ===")
    generate_variants(
        f"{base}/final/icon/tokencap-icon-color.svg",
        f"{base}/final/icon",
        "tokencap-icon"
    )

    print("\n=== Generating wordmark variants ===")
    generate_variants(
        f"{base}/final/wordmark/tokencap-wordmark-color.svg",
        f"{base}/final/wordmark",
        "tokencap-wordmark"
    )

    print("\nDone! 12 variant files generated.")
