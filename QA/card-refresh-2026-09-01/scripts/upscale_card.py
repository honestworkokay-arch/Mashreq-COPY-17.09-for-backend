#!/usr/bin/env python3
"""Готовит точные Retina-версии карточки без генеративной перерисовки."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "reference-inputs" / "mashreq-neo-debit-card-source.jpeg"
BEFORE = ROOT / "retired-assets" / "account-card-hero-before.jpg"
OUTPUT = ROOT / "generated"
PREVIEWS = ROOT / "previews"


def retina_variant(source: Image.Image, scale: int) -> Image.Image:
    """Увеличивает исходник точно в scale раз и мягко возвращает резкость."""
    size = (source.width * scale, source.height * scale)
    resized = source.resize(size, Image.Resampling.LANCZOS)
    if scale == 1:
        return resized
    return resized.filter(
        ImageFilter.UnsharpMask(radius=0.75 * scale, percent=58, threshold=3)
    )


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    if bold:
        candidates.insert(0, "/System/Library/Fonts/SFNSDisplay-Bold.otf")
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default()


def fit(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    """Вписывает изображение целиком, не меняя его пропорции."""
    canvas = Image.new("RGB", size, "#F4F4F4")
    copy = image.copy()
    copy.thumbnail((size[0] - 32, size[1] - 54), Image.Resampling.LANCZOS)
    x = (size[0] - copy.width) // 2
    y = 40 + (size[1] - 40 - copy.height) // 2
    canvas.paste(copy, (x, y))
    return canvas


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)

    with Image.open(SOURCE) as source_file:
        source = source_file.convert("RGB")

    variants = {}
    for scale in (1, 2, 3):
        variant = retina_variant(source, scale)
        path = OUTPUT / f"account-card-hero@{scale}x.png"
        variant.save(path, format="PNG", optimize=True)
        variants[scale] = variant

    # Мини-предпросмотр показывает старый ассет, точный источник и Retina-результат.
    with Image.open(BEFORE) as before_file:
        before = before_file.convert("RGB")

    panel_size = (420, 330)
    sheet = Image.new("RGB", (panel_size[0] * 3, panel_size[1]), "white")
    draw = ImageDraw.Draw(sheet)
    labels = (
        ("Было — 236×150 JPEG", before),
        ("Источник — 280×180 JPEG", source),
        ("Стало — 840×540 PNG @3x", variants[3]),
    )
    for index, (label, image) in enumerate(labels):
        x = index * panel_size[0]
        panel = fit(image, panel_size)
        sheet.paste(panel, (x, 0))
        draw.text((x + 18, 10), label, fill="#202020", font=font(17, bold=True))
        if index:
            draw.line((x, 0, x, panel_size[1]), fill="#D6D6D6", width=1)

    sheet.save(PREVIEWS / "account-card-hero-comparison.png", optimize=True)

    # Так оба ассета реально выглядят внутри существующего слота 236 × 142 pt на @3x.
    slot_size = (708, 426)
    label_height = 58
    slot_sheet = Image.new(
        "RGB", (slot_size[0] * 2 + 2, slot_size[1] + label_height), "white"
    )
    slot_draw = ImageDraw.Draw(slot_sheet)
    slot_labels = (
        ("Было в слоте 236 × 142 pt", before),
        ("Стало в слоте 236 × 142 pt", variants[3]),
    )
    for index, (label, image) in enumerate(slot_labels):
        x = index * (slot_size[0] + 2)
        rendered = ImageOps.fit(
            image, slot_size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5)
        )
        slot_sheet.paste(rendered, (x, label_height))
        slot_draw.text((x + 18, 16), label, fill="#202020", font=font(19, bold=True))
    slot_draw.rectangle(
        (slot_size[0], 0, slot_size[0] + 1, slot_sheet.height), fill="#D6D6D6"
    )
    slot_sheet.save(PREVIEWS / "account-card-hero-screen-slot.png", optimize=True)


if __name__ == "__main__":
    main()
