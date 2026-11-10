#!/usr/bin/env python3
"""
Generate macOS App Icons and Branding Assets for KobeanQAUtils
Uses Apple Human Interface Guidelines for macOS App Icons:
- 1024x1024 master canvas
- 824x824 squircle tile with superellipse continuous corners
- Multi-tier ambient & direct drop shadows
- High-contrast Apple-style canvas for maximum clarity in both Light and Dark mode
- Generates .icns using macOS native iconutil
"""

import os
import sys
import math
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFilter

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

LOGO_SOURCE = "/Users/kobet/.gemini/antigravity-cli/brain/4b465a35-f035-47fe-8298-5f2ab88edd73/.user_uploaded/uploaded_media_1794298766858.png"
if not os.path.exists(LOGO_SOURCE):
    LOGO_SOURCE = os.path.join(PROJECT_ROOT, "src", "assets", "logo-icon.png")

print(f"Using source logo: {LOGO_SOURCE}")
raw_logo = Image.open(LOGO_SOURCE).convert("RGBA")

# Ensure alpha channel is clean
bbox = raw_logo.getbbox()
logo = raw_logo.crop(bbox)

# -------------------------------------------------------------------------
# 1. Generate Master 1024x1024 App Icon (Apple HIG Squircle)
# -------------------------------------------------------------------------
def create_master_icon(output_path):
    canvas_size = 1024
    sq_size = 824
    sq_radius = 185
    sq_x = (canvas_size - sq_size) // 2  # 100
    sq_y = 92  # lifted slightly for bottom drop shadow

    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

    # Supersampled mask for ultra-smooth continuous corners
    ss = 4
    mask_ss = Image.new("L", (sq_size * ss, sq_size * ss), 0)
    draw_ss = ImageDraw.Draw(mask_ss)
    draw_ss.rounded_rectangle([0, 0, sq_size * ss - 1, sq_size * ss - 1], radius=sq_radius * ss, fill=255)
    sq_mask = mask_ss.resize((sq_size, sq_size), Image.Resampling.LANCZOS)

    # 1. macOS Tile Drop Shadow (Ambient + Direct)
    shadow_soft = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    s_tile1 = Image.new("RGBA", (sq_size, sq_size), (0, 0, 0, 75))
    shadow_soft.paste(s_tile1, (sq_x, sq_y + 26), mask=sq_mask)
    shadow_soft = shadow_soft.filter(ImageFilter.GaussianBlur(30))

    shadow_med = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    s_tile2 = Image.new("RGBA", (sq_size, sq_size), (0, 0, 0, 60))
    shadow_med.paste(s_tile2, (sq_x, sq_y + 12), mask=sq_mask)
    shadow_med = shadow_med.filter(ImageFilter.GaussianBlur(14))

    shadow_close = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    s_tile3 = Image.new("RGBA", (sq_size, sq_size), (0, 0, 0, 80))
    shadow_close.paste(s_tile3, (sq_x, sq_y + 4), mask=sq_mask)
    shadow_close = shadow_close.filter(ImageFilter.GaussianBlur(5))

    canvas = Image.alpha_composite(canvas, shadow_soft)
    canvas = Image.alpha_composite(canvas, shadow_med)
    canvas = Image.alpha_composite(canvas, shadow_close)

    # 2. Tile Gradient Background (Crisp Developer Canvas)
    tile = Image.new("RGBA", (sq_size, sq_size), (0, 0, 0, 0))
    for y in range(sq_size):
        t = y / float(sq_size)
        t_curved = math.sin(t * math.pi / 2)
        r = int(255 * (1 - t_curved) + 232 * t_curved)
        g = int(255 * (1 - t_curved) + 238 * t_curved)
        b = int(255 * (1 - t_curved) + 246 * t_curved)
        for x in range(sq_size):
            tile.putpixel((x, y), (r, g, b, 255))
    tile.putalpha(sq_mask)

    # Subtle inner border stroke (1.5px)
    border_img = Image.new("RGBA", (sq_size * ss, sq_size * ss), (0, 0, 0, 0))
    draw_b = ImageDraw.Draw(border_img)
    draw_b.rounded_rectangle([0, 0, sq_size * ss - 1, sq_size * ss - 1], radius=sq_radius * ss, outline=(15, 23, 42, 38), width=2 * ss)
    border_res = border_img.resize((sq_size, sq_size), Image.Resampling.LANCZOS)
    tile = Image.alpha_composite(tile, border_res)

    canvas.paste(tile, (sq_x, sq_y), mask=sq_mask)

    # 3. Logo Placement & Lighting
    # Scaled to ~636 px height inside 824 px tile
    target_h = 636
    scale = target_h / float(logo.height)
    target_w = int(logo.width * scale)
    logo_scaled = logo.resize((target_w, target_h), Image.Resampling.LANCZOS)

    lx = sq_x + (sq_size - target_w) // 2
    ly = sq_y + (sq_size - target_h) // 2 - 2

    # Drop shadow for the logo mark
    logo_shadow = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    logo_alpha = logo_scaled.getchannel("A")

    l_sh1 = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 50))
    logo_shadow.paste(l_sh1, (lx, ly + 8), mask=logo_alpha)
    logo_shadow = logo_shadow.filter(ImageFilter.GaussianBlur(10))

    logo_shadow_contact = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    l_sh2 = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 70))
    logo_shadow_contact.paste(l_sh2, (lx, ly + 3), mask=logo_alpha)
    logo_shadow_contact = logo_shadow_contact.filter(ImageFilter.GaussianBlur(3))

    canvas = Image.alpha_composite(canvas, logo_shadow)
    canvas = Image.alpha_composite(canvas, logo_shadow_contact)

    # Paste logo mark
    canvas.paste(logo_scaled, (lx, ly), mask=logo_alpha)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    canvas.save(output_path, "PNG")
    print(f"✓ Master icon saved to: {output_path}")
    return canvas

# -------------------------------------------------------------------------
# 2. Generate Apple .icns & Asset Catalog
# -------------------------------------------------------------------------
def generate_all_icons(master_img):
    macos_res = os.path.join(PROJECT_ROOT, "macos", "Resources")
    appiconset_dir = os.path.join(macos_res, "Assets.xcassets", "AppIcon.appiconset")
    temp_iconset = "/tmp/KobeanAppIcon.iconset"
    
    os.makedirs(appiconset_dir, exist_ok=True)
    os.makedirs(temp_iconset, exist_ok=True)

    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    for sz, filename in sizes:
        resized = master_img.resize((sz, sz), Image.Resampling.LANCZOS)
        # Save to xcassets
        resized.save(os.path.join(appiconset_dir, filename), "PNG")
        # Save to iconset for iconutil
        resized.save(os.path.join(temp_iconset, filename), "PNG")

    # Generate .icns via iconutil
    icns_path = os.path.join(macos_res, "AppIcon.icns")
    res = subprocess.run(["iconutil", "-c", "icns", temp_iconset, "-o", icns_path], capture_output=True, text=True)
    if res.returncode == 0:
        print(f"✓ Generated Apple ICNS: {icns_path} ({os.path.getsize(icns_path):,} bytes)")
    else:
        print(f"✗ iconutil failed: {res.stderr}")

    # Also update buildResources for electron / shared compatibility
    build_res = os.path.join(PROJECT_ROOT, "buildResources")
    master_img.save(os.path.join(build_res, "icon.png"), "PNG")
    shutil.copyfile(icns_path, os.path.join(build_res, "icon.icns"))
    print("✓ Updated buildResources/icon.png and buildResources/icon.icns")

# -------------------------------------------------------------------------
# 3. Generate In-App AppLogo Assets (Clean Transparent Silhouette)
# -------------------------------------------------------------------------
def generate_brand_logo():
    macos_res = os.path.join(PROJECT_ROOT, "macos", "Resources")
    
    # 1. Resources/AppLogo.png
    raw_logo.save(os.path.join(macos_res, "AppLogo.png"), "PNG")
    
    # 2. Assets.xcassets/AppLogo.imageset
    logo_imageset = os.path.join(macos_res, "Assets.xcassets", "AppLogo.imageset")
    os.makedirs(logo_imageset, exist_ok=True)
    
    # Generate 1x (64px), 2x (128px), 3x (192px)
    h_1x = 64
    w_1x = int(raw_logo.width * (h_1x / float(raw_logo.height)))
    img_1x = raw_logo.resize((w_1x, h_1x), Image.Resampling.LANCZOS)
    img_1x.save(os.path.join(logo_imageset, "logo.png"), "PNG")

    h_2x = 128
    w_2x = int(raw_logo.width * (h_2x / float(raw_logo.height)))
    img_2x = raw_logo.resize((w_2x, h_2x), Image.Resampling.LANCZOS)
    img_2x.save(os.path.join(logo_imageset, "logo@2x.png"), "PNG")

    h_3x = 192
    w_3x = int(raw_logo.width * (h_3x / float(raw_logo.height)))
    img_3x = raw_logo.resize((w_3x, h_3x), Image.Resampling.LANCZOS)
    img_3x.save(os.path.join(logo_imageset, "logo@3x.png"), "PNG")

    # Contents.json for AppLogo
    contents_json = """{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "logo.png",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "filename" : "logo@2x.png",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "filename" : "logo@3x.png",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
    with open(os.path.join(logo_imageset, "Contents.json"), "w") as f:
        f.write(contents_json)
    print("✓ Generated Assets.xcassets/AppLogo.imageset")

if __name__ == "__main__":
    master_icon_path = os.path.join(PROJECT_ROOT, "macos", "Resources", "AppIcon.png")
    master = create_master_icon(master_icon_path)
    generate_all_icons(master)
    generate_brand_logo()
    print("✨ All brand assets successfully generated!")
