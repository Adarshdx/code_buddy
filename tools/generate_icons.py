"""Generate PWA icons for Code-Buddy.

Output:
  web/favicon.png        (32x32, transparent border)
  web/icons/Icon-192.png (192x192)
  web/icons/Icon-512.png (512x512)
  web/icons/Icon-maskable-192.png (192x192, extra padding for Android maskable)
  web/icons/Icon-maskable-512.png (512x512, extra padding)
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BG = (13, 17, 23, 255)         # GitHub-style dark bg
BRAND = (88, 166, 255, 255)    # Code-Buddy primary
TEXT = (13, 17, 23, 255)       # dark text on brand
WEB = Path(__file__).resolve().parents[1] / "web"


def find_font(target_size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        "C:/Windows/Fonts/seguiemj.ttf",
        "C:/Windows/Fonts/SegoeUI.ttf",
        "C:/Windows/Fonts/segoeuib.ttf",  # bold
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/arial.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, target_size)
    return ImageFont.load_default()


def draw_icon(size: int, *, maskable: bool = False) -> Image.Image:
    img = Image.new("RGBA", (size, size), BG)
    draw = ImageDraw.Draw(img)

    # Outer card padding (maskable needs ~20% safe zone)
    pad = int(size * 0.2) if maskable else int(size * 0.08)
    inner = size - 2 * pad
    radius = int(inner * 0.18)
    draw.rounded_rectangle(
        [pad, pad, size - pad, size - pad],
        radius=radius,
        fill=BRAND,
    )

    text = "</>"
    font = find_font(int(inner * 0.42))
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (size - tw) // 2 - bbox[0]
    ty = (size - th) // 2 - bbox[1]
    draw.text((tx, ty), text, fill=TEXT, font=font)
    return img


def main() -> None:
    (WEB / "icons").mkdir(parents=True, exist_ok=True)

    draw_icon(192).save(WEB / "icons" / "Icon-192.png", optimize=True)
    draw_icon(512).save(WEB / "icons" / "Icon-512.png", optimize=True)
    draw_icon(192, maskable=True).save(WEB / "icons" / "Icon-maskable-192.png", optimize=True)
    draw_icon(512, maskable=True).save(WEB / "icons" / "Icon-maskable-512.png", optimize=True)
    draw_icon(64).resize((32, 32), Image.LANCZOS).save(WEB / "favicon.png", optimize=True)

    print("Wrote:")
    for path in [
        WEB / "favicon.png",
        WEB / "icons" / "Icon-192.png",
        WEB / "icons" / "Icon-512.png",
        WEB / "icons" / "Icon-maskable-192.png",
        WEB / "icons" / "Icon-maskable-512.png",
    ]:
        print(f"  {path.relative_to(WEB.parent)}  ({path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
