# Mashreq Typography Specification

## Семейство

В приложение встроены пять реальных начертаний 29LT Bukra:

| Swift weight | PostScript name | Файл | Назначение |
|---|---|---|---|
| `light` | `29LTBukra-Light` | `29LTBukra-Light.ttf` | пояснения, metadata, вторичный текст |
| `regular` | `29LTBukra-Regular` | `29LTBukra-Regular.ttf` | основной текст |
| `medium` | `29LTBukra-Medium` | `29LTBukra-Medium.ttf` | поля и навигационные подписи |
| `semibold` | `29LTBukra-SemiBold` | `29LTBukra-SemiBold.ttf` | кнопки, секции и суммы |
| `bold` | `29LTBukra-Bold` | `29LTBukra-Bold.ttf` | крупные суммы и success-заголовки |

## Шкала размеров

`MashreqTextSize` хранит все используемые размеры: **9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 23 и 28 pt**. Экранный текст задаётся только через:

```swift
.font(.mashreq(size: MashreqTextSize.body, weight: .regular))
```

## Геометрия и цвет

- основной текст: `#1C1C1E`;
- обычный текст: `#2C2C2E`;
- вторичный текст: `#858589`;
- основной orange: `#FF5F00`;
- тёмный orange: `#E54D00`;
- высота основных CTA: `60 pt`;
- основной горизонтальный отступ: `22 pt`;
- межстрочные интервалы заданы локально только там, где они видны в референсе.

## Правило дальнейшей настройки

Сначала меняйте родительскую геометрию и значения `MashreqTextSize`. Локальные `offset` допустимы только после overlay-проверки и не должны компенсировать неверную метрику шрифта или высоту контейнера.
