"""Готовит точный Login background и прозрачный foreground из референсов."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


PROJECT = Path(__file__).resolve().parents[2]
ASSETS = PROJECT / "MashreqApp" / "Assets.xcassets"
PUBLIC_HERO = ASSETS / "LoginPublicHero.imageset" / "login-public-hero.jpg"
FACE_SCREEN = (
    ASSETS
    / "LoginFaceReferenceScreen.imageset"
    / "login-face-reference.png"
)
BACKGROUND_OUTPUT = (
    ASSETS
    / "LoginReferenceGradient.imageset"
    / "login-reference-gradient.png"
)
FOREGROUND_OUTPUT = (
    ASSETS
    / "LoginFaceContentOverlay.imageset"
    / "login-face-content-overlay.png"
)
PREVIEW_OUTPUT = Path(__file__).resolve().parent / "login-hero-static-preview.png"


def extend_gradient_upward(source: Image.Image, inset: int = 74) -> Image.Image:
    """Добавляет status-area сверху, не трогая исходную дугу и градиент."""

    source = source.convert("RGB")
    output = Image.new("RGB", (source.width, source.height + inset))
    pixels = output.load()
    source_pixels = source.load()
    # Для extrapolation используем только низкочастотный цветовой слой.
    # Это не затрагивает сам референс ниже status bar, но убирает усиление
    # вертикальных JPEG-полос при продолжении верхних строк вверх.
    smooth_source = source.filter(ImageFilter.GaussianBlur(18))
    # Дополнительно убираем 1 px JPEG-шум по горизонтали: иначе обратное
    # продолжение первых строк усиливает его в заметные вертикальные полосы.
    smooth_source = smooth_source.resize(
        (24, source.height),
        Image.Resampling.BILINEAR,
    ).resize(
        source.size,
        Image.Resampling.BICUBIC,
    )
    smooth_pixels = smooth_source.load()
    slope_sample = 36

    for x in range(source.width):
        top = smooth_pixels[x, 0]
        lower = smooth_pixels[x, slope_sample]
        slopes = tuple((lower[channel] - top[channel]) / slope_sample for channel in range(3))

        for y in range(inset):
            distance = inset - y
            pixels[x, y] = tuple(
                max(0, min(255, round(top[channel] - slopes[channel] * distance)))
                for channel in range(3)
            )

    # Первые 64 строки исходного hero мягко соединяем с продолжением status-area.
    # Нижняя дуга и вся основная площадь исходника остаются пиксельно неизменными.
    joined_source = source.copy()
    joined_pixels = joined_source.load()
    blend_height = 64
    for y in range(blend_height):
        amount = y / blend_height
        for x in range(source.width):
            original = source_pixels[x, y]
            smoothed = smooth_pixels[x, y]
            joined_pixels[x, y] = tuple(
                round(smoothed[channel] * (1 - amount) + original[channel] * amount)
                for channel in range(3)
            )

    output.paste(joined_source, (0, inset))
    return output


def extract_face_overlay(source: Image.Image) -> Image.Image:
    """Оставляет иллюстрацию, текст и pager без оранжевого screenshot-фона."""

    source = source.convert("RGB")
    source_top = 112
    source_bottom = 1198
    segment = source.crop((0, source_top, source.width, source_bottom))
    overlay = Image.new("RGBA", segment.size, (0, 0, 0, 0))

    # Кандидатная область охватывает оригинальную awareness-иллюстрацию.
    candidate = Image.new("L", segment.size, 0)
    draw = ImageDraw.Draw(candidate)
    draw.ellipse((284, 222, 606, 564), fill=255)
    draw.ellipse((265, 224, 414, 382), fill=255)
    draw.ellipse((224, 300, 438, 566), fill=255)
    draw.ellipse((480, 220, 648, 404), fill=255)
    draw.ellipse((474, 320, 658, 538), fill=255)

    # Оранжевую одежду сохраняем отдельной маской по форме фигуры. Сам жёлтый
    # круг определяется цветом; так вокруг него не появляется оранжевый ореол.
    core = Image.new("L", segment.size, 0)
    core_draw = ImageDraw.Draw(core)
    core_draw.ellipse((356, 270, 516, 426), fill=255)
    core_draw.polygon(
        (
            (390, 338),
            (500, 330),
            (558, 403),
            (548, 528),
            (487, 562),
            (364, 535),
            (344, 416),
        ),
        fill=255,
    )

    candidate_pixels = candidate.load()
    core_pixels = core.load()
    segment_pixels = segment.load()
    illustration_mask = Image.new("L", segment.size, 0)
    mask_pixels = illustration_mask.load()

    for y in range(segment.height):
        for x in range(segment.width):
            if candidate_pixels[x, y] == 0:
                continue

            red, green, blue = segment_pixels[x, y]
            looks_like_orange_background = (
                red > 225 and 55 < green < 174 and blue < 58
            )
            if core_pixels[x, y] or not looks_like_orange_background:
                mask_pixels[x, y] = 255

    illustration_mask = illustration_mask.filter(ImageFilter.MaxFilter(3))
    illustration_mask = illustration_mask.filter(ImageFilter.GaussianBlur(1.2))
    overlay.paste(segment.convert("RGBA"), (0, 0), illustration_mask)

    # Белая типографика извлекается независимо: фон не переносится в asset.
    text_mask = Image.new("L", segment.size, 0)
    text_mask_pixels = text_mask.load()
    text_regions = (
        (232, 552, 668, 632),
        (70, 620, 786, 900),
    )
    for left, top, right, bottom in text_regions:
        for y in range(top, bottom):
            for x in range(left, right):
                red, green, blue = segment_pixels[x, y]
                whiteness = min(red, green, blue)
                text_mask_pixels[x, y] = max(
                    0,
                    min(255, round((whiteness - 65) * 1.55)),
                )

    white_layer = Image.new("RGBA", segment.size, (255, 255, 255, 0))
    white_layer.putalpha(text_mask)
    overlay.alpha_composite(white_layer)

    # Pager содержит белую полосу и два полупрозрачных персиковых индикатора.
    pager_mask = Image.new("L", segment.size, 0)
    pager_mask_pixels = pager_mask.load()
    for y in range(965, 1040):
        for x in range(260, 600):
            red, green, blue = segment_pixels[x, y]
            alpha = max(0, min(255, round((blue - 18) * 4.1)))
            if red > 235 and green > 135:
                pager_mask_pixels[x, y] = alpha

    pager_layer = segment.convert("RGBA")
    pager_layer.putalpha(pager_mask)
    overlay.alpha_composite(pager_layer)
    return overlay


def main() -> None:
    BACKGROUND_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    FOREGROUND_OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    background = extend_gradient_upward(Image.open(PUBLIC_HERO))
    # 2× PNG сохраняет гладкую дугу и исключает дополнительное JPEG-сжатие.
    background_2x = background.resize(
        (background.width * 2, background.height * 2),
        Image.Resampling.LANCZOS,
    )
    background_2x.save(BACKGROUND_OUTPUT, optimize=True)

    foreground = extract_face_overlay(Image.open(FACE_SCREEN))
    foreground_2x = foreground.resize(
        (foreground.width * 2, foreground.height * 2),
        Image.Resampling.LANCZOS,
    )
    foreground_2x.save(FOREGROUND_OUTPUT, optimize=True)

    # Мини-предпросмотр воспроизводит только app-owned hero без системного chrome.
    preview_width = 588
    preview_background = background.resize(
        (preview_width, round(preview_width * background.height / background.width)),
        Image.Resampling.LANCZOS,
    ).convert("RGBA")
    content_top = round(preview_width * 74 / 585)
    content_height = round(preview_width * 738 / 585)
    preview_foreground = foreground.resize(
        (preview_width, content_height),
        Image.Resampling.LANCZOS,
    )
    preview_background.alpha_composite(preview_foreground, (0, content_top))
    preview_background.save(PREVIEW_OUTPUT, optimize=True)

    print(BACKGROUND_OUTPUT)
    print(FOREGROUND_OUTPUT)
    print(PREVIEW_OUTPUT)


if __name__ == "__main__":
    main()
