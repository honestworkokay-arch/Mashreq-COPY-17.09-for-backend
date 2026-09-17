#!/usr/bin/env python3
"""Измеряет два присланных кропа и подготавливает сравнимый кроп симулятора."""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
REFERENCE = ROOT / "reference" / "account-summary-reference.png"
BEFORE = ROOT / "before" / "overview-before.png"
AFTER = ROOT / "after" / "overview-after-v3-fraction.png"


def font(size: int) -> ImageFont.FreeTypeFont:
    for path in (
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def main() -> None:
    reference = Image.open(REFERENCE).convert("RGB")
    simulator = Image.open(BEFORE).convert("RGB")

    # Overview имеет горизонтальный inset 24 pt; скриншот iPhone 17 Pro снят @3x.
    # Верх summary-карточки измерен в полном кадре на y = 675 px.
    crop = simulator.crop((72, 675, 1134, 996))
    crop_1x = crop.resize((354, 107), Image.Resampling.LANCZOS)
    crop_1x.save(ROOT / "before" / "account-summary-before-1x.png", optimize=True)

    # Сравнение выводится в одном масштабе, без растягивания текста.
    sheet = Image.new("RGB", (760, 160), "#F3F3F3")
    sheet.paste(crop_1x, (16, 42))
    sheet.paste(reference, (386, 42))
    draw = ImageDraw.Draw(sheet)
    draw.text((16, 12), "Текущее приложение — 354 × 107 pt", fill="#222222", font=font(15))
    draw.text((386, 12), "Референс — 358 × 102 px", fill="#222222", font=font(15))
    sheet.save(ROOT / "before" / "account-summary-before-vs-reference.png", optimize=True)

    if AFTER.exists():
        after_screen = Image.open(AFTER).convert("RGB")
        after_crop = after_screen.crop((72, 675, 1134, 981)).resize(
            (354, 102), Image.Resampling.LANCZOS
        )
        after_crop.save(
            ROOT / "after" / "account-summary-after-v3-fraction-1x.png",
            optimize=True,
        )

        # Референс приводится только к ширине SwiftUI-контейнера для 50% overlay.
        normalized_reference = reference.resize((354, 102), Image.Resampling.LANCZOS)
        overlay = Image.blend(normalized_reference, after_crop, 0.5)
        overlay.save(
            ROOT / "after" / "account-summary-overlay-50-v3-fraction.png",
            optimize=True,
        )

        final_sheet = Image.new("RGB", (1126, 160), "#F3F3F3")
        final_sheet.paste(crop_1x, (16, 42))
        final_sheet.paste(after_crop, (386, 42))
        final_sheet.paste(normalized_reference, (756, 42))
        final_draw = ImageDraw.Draw(final_sheet)
        final_draw.text((16, 12), "До", fill="#222222", font=font(15))
        final_draw.text((386, 12), "После — уменьшенные копейки", fill="#222222", font=font(15))
        final_draw.text((756, 12), "Референс", fill="#222222", font=font(15))
        final_sheet.save(
            ROOT / "after" / "account-summary-fraction-comparison.png",
            optimize=True,
        )


if __name__ == "__main__":
    main()
