from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


# Скрипт механически извлекает присланные пользователем элементы.
# Никакие формы иконок не перерисовываются и не заменяются системными символами.
ROOT = Path(__file__).resolve().parents[3]
REFERENCE_DIR = ROOT / "QA/overview-refresh-2026-09-01/reference-inputs"
PREVIEW_DIR = ROOT / "QA/overview-refresh-2026-09-01/previews"
ASSETS_DIR = ROOT / "MashreqApp/Assets.xcassets"

GRADIENT_SOURCE = REFERENCE_DIR / "overview-gradient-reference.jpg"
ICONS_SOURCE = REFERENCE_DIR / "overview-icons-reference.jpg"
LOGO_SOURCE = REFERENCE_DIR / "neo-logo-reference.jpg"


def transparent_mark(source: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    """Удаляет только почти белый JPEG-фон, сохраняя исходный цвет и сглаживание."""
    crop = source.crop(box).convert("RGB")
    rgba = Image.new("RGBA", crop.size)
    src = crop.load()
    dst = rgba.load()

    for y in range(crop.height):
        for x in range(crop.width):
            red, green, blue = src[x, y]
            distance_from_white = max(255 - red, 255 - green, 255 - blue)
            alpha = max(0, min(255, int((distance_from_white - 3) * 255 / 22)))
            dst[x, y] = (red, green, blue, alpha)

    return rgba


def make_gradient() -> Image.Image:
    """Сохраняет весь переход до белой границы и подгоняет его под слот 402 × 306 pt."""
    source = Image.open(GRADIENT_SOURCE).convert("RGB")
    orange_region = source.crop((0, 0, 720, 610))
    # 1440 × 1096 имеет то же отношение сторон, что и хедер 402 × 306 pt.
    return orange_region.resize((1440, 1096), Image.Resampling.LANCZOS)


def make_logo() -> Image.Image:
    """Восстанавливает непрозрачный белый логотип из качественного светлого референса."""
    source = Image.open(LOGO_SOURCE).convert("L")
    darkness = ImageOps.invert(source).filter(ImageFilter.GaussianBlur(8))
    alpha = darkness.point(lambda value: 255 if value >= 2 else 0)
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.2)).crop((58, 186, 1208, 1094))

    result = Image.new("RGBA", alpha.size, (255, 255, 255, 0))
    result.putalpha(alpha)

    # На полном Overview между знаком и NEO заметно больше воздуха, чем в
    # техническом листе. Вставляем прозрачный интервал, не меняя сами контуры.
    split_y = 680
    added_gap = 120
    spaced = Image.new("RGBA", (result.width, result.height + added_gap), (255, 255, 255, 0))
    spaced.alpha_composite(result.crop((0, 0, result.width, split_y)), (0, 0))
    spaced.alpha_composite(
        result.crop((0, split_y, result.width, result.height)),
        (0, split_y + added_gap),
    )
    return spaced


def make_contact_sheet(
    gradient: Image.Image,
    logo: Image.Image,
    marks: dict[str, Image.Image],
) -> Image.Image:
    """Создаёт локальный мини-предпросмотр фактически экспортированных ассетов."""
    canvas = Image.new("RGB", (1200, 500), (255, 95, 0))
    canvas.paste(gradient.resize((660, 502), Image.Resampling.LANCZOS), (0, 0))

    logo_preview = logo.copy()
    logo_preview.thumbnail((155, 125), Image.Resampling.LANCZOS)
    canvas.paste(logo_preview, (45, 70), logo_preview)

    x_position = 680
    for name in ("chat", "notification", "profile"):
        circle = Image.new("RGBA", (135, 135), (0, 0, 0, 0))
        ImageDraw.Draw(circle).ellipse((3, 3, 131, 131), fill="white")
        mark = marks[name].copy()
        mark.thumbnail((88, 88), Image.Resampling.LANCZOS)
        circle.alpha_composite(mark, ((135 - mark.width) // 2, (135 - mark.height) // 2))
        canvas.paste(circle, (x_position, 70), circle)
        x_position += 165

    ImageDraw.Draw(canvas).rounded_rectangle((680, 245, 1170, 455), radius=20, fill="white")
    eye = marks["eye"].copy()
    eye.thumbnail((145, 90), Image.Resampling.LANCZOS)
    canvas.paste(eye, (740, 300), eye)
    plus = marks["plus"].copy()
    plus.thumbnail((115, 115), Image.Resampling.LANCZOS)
    canvas.paste(plus, (970, 280), plus)
    return canvas


def main() -> None:
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    icons = Image.open(ICONS_SOURCE).convert("RGB")

    # Координаты измерены в исходнике 1280 × 426, с безопасным полем для сглаживания.
    boxes = {
        "chat": (72, 144, 209, 276),
        "notification": (332, 99, 498, 274),
        "profile": (603, 166, 707, 254),
        "eye": (812, 148, 1006, 275),
        "plus": (1059, 115, 1241, 299),
    }
    marks = {name: transparent_mark(icons, box) for name, box in boxes.items()}
    gradient = make_gradient()
    logo = make_logo()

    outputs = {
        ASSETS_DIR / "OverviewHeaderChat.imageset/header-chat.png": marks["chat"],
        ASSETS_DIR / "OverviewHeaderNotifications.imageset/header-notifications.png": marks["notification"],
        ASSETS_DIR / "OverviewHeaderProfile.imageset/header-profile.png": marks["profile"],
        ASSETS_DIR / "OverviewEye.imageset/account-eye.png": marks["eye"],
        ASSETS_DIR / "OverviewAddMoneyPlus.imageset/add-money-plus.png": marks["plus"],
        ASSETS_DIR / "OverviewNeoLockup.imageset/neo-lockup.png": logo,
        ASSETS_DIR / "OverviewHeaderGradient.imageset/overview-header-gradient.png": gradient,
    }

    for path, image in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path, format="PNG", optimize=True)

    make_contact_sheet(gradient, logo, marks).save(
        PREVIEW_DIR / "overview-assets-contact-sheet.png",
        format="PNG",
        optimize=True,
    )


if __name__ == "__main__":
    main()
