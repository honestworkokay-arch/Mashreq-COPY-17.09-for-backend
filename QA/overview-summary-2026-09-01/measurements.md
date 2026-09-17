# Overview account summary — измерения

Дата: 1 сентября 2026.

## Источники

- `reference/account-summary-reference.png` — `358 × 102 px`.
- `reference/account-summary-and-row-reference.png` — `351 × 189 px`.
- `before/overview-before.png` — нативный iPhone 17 Pro Simulator до правки.
- `after/overview-after-v3-fraction.png` — финальный нативный iPhone 17 Pro Simulator.

## Геометрия SwiftUI

| Параметр | До | После |
| --- | ---: | ---: |
| Высота контейнера | `107 pt` | `102 pt` |
| Заголовок | `18 pt semibold` | `14 pt semibold` |
| Подписи | `14 pt light` | `12 pt light` |
| Первая сумма | `20 pt semibold` | `19 pt` целая / `12 pt` копейки |
| Вторая сумма | `17 pt semibold` | `14 pt` целая / `10 pt` копейки |
| Leading inset | `16 pt` | `20 pt` |
| Trailing inset | `16 pt` | `17 pt` |

## Координаты видимых пикселей в нормализованном 1x-кропе

| Элемент | После | Референс |
| --- | --- | --- |
| `1 Account` — верх | `y=20` | `y=20` |
| `Available Balance` — верх | `y=54` | `y=54` |
| Первая сумма — верх | `y=51` | `y=51` |
| `Current Balance` — верх | `y=76` | `y=76` |
| Вторая сумма — верх | `y=76` | `y=76` |
| `View all` — площадь глифа | `191 px` | `189 px` |

## Дробная часть суммы

- Верхняя целая часть: `19 pt semibold`.
- Верхние копейки после точки: `12 pt semibold`.
- Нижняя целая часть: `14 pt semibold`.
- Нижние копейки после точки: `10 pt semibold`.
- Целая и дробная части выровнены по `firstTextBaseline`; правый край всей
  суммы сохраняет прежнее выравнивание.
- Новый runtime-кадр:
  `after/overview-after-v3-fraction.png`.
- Нормализованный кроп:
  `after/account-summary-after-v3-fraction-1x.png`.
- Сравнение до/после/референс:
  `after/account-summary-fraction-comparison.png`.
- 50% overlay:
  `after/account-summary-overlay-50-v3-fraction.png`.

## Результат

`passed`

Проверки: iPhone 17 Pro Simulator build/install/launch, runtime screenshot с
уменьшенными копейками,
Generic ARM64 `iphoneos` build без подписи и `git diff --check` — passed.

Нет открытых P0, P1 или P2 расхождений в запрошенной геометрии текста.
Различаются только тестовые значения суммы; eye-asset сохранён по основному
Overview-референсу и не входит в scope изменения текста.
