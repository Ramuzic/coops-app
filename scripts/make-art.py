#!/usr/bin/env python3
"""Makes the app icon and splash screens for iPhone and Android.

  python3 scripts/make-art.py                     # placeholder art: a barn red "CC" tile
  python3 scripts/make-art.py --logo logo.png     # the real logo (square PNG, 1024 or bigger)

Writes resources/ and every icon and splash file already in the iOS and Android
projects, keeping each file's size. Needs Pillow (pip install pillow).
The splash background is cream #fef6e7 so it fades straight into the site.
"""
import argparse
import glob
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CREAM = (0xFE, 0xF6, 0xE7)
BARN = (0xCF, 0x42, 0x38)

FONTS = [
    "/usr/share/fonts/truetype/google-fonts/Poppins-Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/Library/Fonts/Arial Bold.ttf",
]


def font(size):
    for f in FONTS:
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def tile(size):
    """The placeholder mark: a barn red rounded square with CC, on transparent."""
    s = size * 4  # draw big, then shrink for smooth edges
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.22), fill=BARN + (255,))
    f = font(int(s * 0.46))
    box = d.textbbox((0, 0), "CC", font=f)
    w, h = box[2] - box[0], box[3] - box[1]
    d.text(((s - w) / 2 - box[0], (s - h) / 2 - box[1]), "CC", font=f, fill=CREAM + (255,))
    return im.resize((size, size), Image.LANCZOS)


def square(img):
    w, h = img.size
    m = min(w, h)
    return img.crop(((w - m) // 2, (h - m) // 2, (w - m) // 2 + m, (h - m) // 2 + m))


def mark(logo, size):
    """What sits in the middle of icons and splashes."""
    if logo is None:
        return tile(size)
    return square(logo).resize((size, size), Image.LANCZOS)


def flat(img):
    """No transparency (the App Store refuses icons with an alpha channel)."""
    bg = Image.new("RGB", img.size, CREAM)
    bg.paste(img, mask=img.split()[3] if img.mode == "RGBA" else None)
    return bg


def full_icon(logo, size):
    """Square icon. The logo fills it; the placeholder tile sits on cream."""
    if logo is not None:
        return flat(mark(logo, size))
    im = Image.new("RGBA", (size, size), CREAM + (255,))
    t = tile(int(size * 0.72))
    im.alpha_composite(t, ((size - t.width) // 2, (size - t.height) // 2))
    return flat(im)


def foreground(logo, size):
    """Android adaptive icon front layer (the project insets it, so fill the canvas)."""
    if logo is not None:
        return mark(logo, size).convert("RGBA")
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    t = tile(int(size * 0.80))
    im.alpha_composite(t, ((size - t.width) // 2, (size - t.height) // 2))
    return im


def round_icon(logo, size):
    s = size * 4
    base = full_icon(logo, s).convert("RGBA")
    m = Image.new("L", (s, s), 0)
    ImageDraw.Draw(m).ellipse([0, 0, s - 1, s - 1], fill=255)
    base.putalpha(m)
    return base.resize((size, size), Image.LANCZOS)


def splash(logo, w, h):
    im = Image.new("RGBA", (w, h), CREAM + (255,))
    side = int(min(w, h) * (0.18 if w == h else 0.26))
    m = mark(logo, side).convert("RGBA")
    im.alpha_composite(m, ((w - side) // 2, (h - side) // 2))
    return im.convert("RGB")


def save(img, path):
    img.save(path, "PNG", optimize=True)
    print("wrote", os.path.relpath(path, ROOT), img.size)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--logo", help="square PNG logo; without it a placeholder is drawn")
    ap.add_argument("--icon", help="full square app icon (1024 PNG, no transparency); used for the app icons, the logo stays on the splash")
    a = ap.parse_args()
    logo = None
    if a.logo:
        logo = Image.open(a.logo)
        logo.load()
        logo = logo.convert("RGBA")
        if min(logo.size) < 512:
            print("warning: the logo is small (%dx%d), icons may look soft" % logo.size, file=sys.stderr)

    r = lambda *p: os.path.join(ROOT, *p)

    icon = None
    if a.icon:
        icon = Image.open(a.icon)
        icon.load()
        icon = flat(icon.convert("RGBA").resize((1024, 1024), Image.LANCZOS)).convert("RGBA")
    ic_full = (lambda size: flat(icon.resize((size, size), Image.LANCZOS))) if icon is not None else (lambda size: full_icon(logo, size))
    ic_fg = (lambda size: icon.resize((size, size), Image.LANCZOS)) if icon is not None else (lambda size: foreground(logo, size))
    def ic_round(size):
        if icon is None:
            return round_icon(logo, size)
        s4 = size * 4
        base = icon.resize((s4, s4), Image.LANCZOS)
        m = Image.new("L", (s4, s4), 0)
        ImageDraw.Draw(m).ellipse([0, 0, s4 - 1, s4 - 1], fill=255)
        base.putalpha(m)
        return base.resize((size, size), Image.LANCZOS)

    # resources/ (the source files @capacitor/assets would use)
    save(ic_full(1024), r("resources", "icon.png"))
    save(ic_full(1024), r("resources", "icon-only.png"))
    save(ic_fg(1024), r("resources", "icon-foreground.png"))
    save(Image.new("RGB", (1024, 1024), CREAM), r("resources", "icon-background.png"))
    save(splash(logo, 2732, 2732), r("resources", "splash.png"))
    save(splash(logo, 2732, 2732), r("resources", "splash-dark.png"))

    # iPhone
    save(ic_full(1024), r("ios", "App", "App", "Assets.xcassets", "AppIcon.appiconset", "AppIcon-512@2x.png"))
    for p in glob.glob(r("ios", "App", "App", "Assets.xcassets", "Splash.imageset", "*.png")):
        w, h = Image.open(p).size
        save(splash(logo, w, h), p)

    # Android
    res = r("android", "app", "src", "main", "res")
    for p in glob.glob(os.path.join(res, "mipmap-*", "*.png")):
        w, _ = Image.open(p).size
        name = os.path.basename(p)
        if name == "ic_launcher.png":
            save(ic_full(w), p)
        elif name == "ic_launcher_round.png":
            save(ic_round(w), p)
        elif name == "ic_launcher_foreground.png":
            save(ic_fg(w), p)
        elif name == "ic_launcher_background.png":
            save(Image.new("RGB", (w, w), CREAM), p)
    for p in glob.glob(os.path.join(res, "drawable*", "splash.png")):
        w, h = Image.open(p).size
        save(splash(logo, w, h), p)


if __name__ == "__main__":
    main()
