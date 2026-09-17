# Transaction details — visual QA

## Проверяемый экран

- Reference: `Фото 1.jpg` — Transaction details, Details tab.
- Reference: `Фото 2.jpg` — Your receipts, Fund transfer e-receipt, Repeat transfer.
- Current pre-fix capture: `codex-clipboard-0230abc5-e947-4a49-bf36-8b15523d0958.png` (1206 × 2622).
- Device class: iPhone 17 Pro.

## Измерения и исправления

| Область | До | Референс, приведённый к ширине текущего кадра | Исправление |
| --- | ---: | ---: | --- |
| Нижняя граница header | 336 px | ~308 px | высота `112 → 101 pt` |
| Нижняя граница табов | 684 px | ~475 px | верхний inset `112 → 42 pt`, tab height сохранён `55 pt` |
| Плотность details | заметно растянута | компактные пары label/value | межблочный шаг `27 → 18 pt`, label `11 pt`, value `13 pt` |
| Summary typography | date/reference крупнее референса | компактная вторичная типографика | date/reference `11 pt`, status `9 pt` |

## Data-flow QA

- Баланс, история, success, details и PDF используют один `CompletedTransfer`.
- Перевод списывается один раз: повторное появление success-экрана не создаёт дубль.
- Строка истории хранит `transferID`; tap открывает соответствующий перевод.
- Все реквизиты details и PDF читаются из завершённого перевода, а не из локальных строк View.
- Repeat transfer создаёт новый draft ID и не повторяет старое списание автоматически.

## Build proof

- Simulator build artifact compiled after the structural implementation and the first geometry pass: `MashreqApp.app`, bundle `com.madina.mashreqdemo`.
- The final calibration changes only two numeric layout constants (`top inset` and `tab height`); full target-source Swift type-check passes with no errors. Xcode's simulator/device service did not complete a second install/run operation.
- `project.pbxproj`: `plutil -lint` — OK.
- `git diff --check` — OK.

## Runtime proof boundary

Simulator iOS 26.4 загрузился, но сервис запуска приложения завис на системной операции. Повторные циклы остановлены. Поэтому новый post-fix screenshot и нажатие генерации PDF на runtime пока не зафиксированы; компиляция подтверждена, визуальная оценка основана на измерениях исходного и pre-fix кадров.

## Итог

- Projected visual similarity: **9/10** по измеренной геометрии и типографике.
- Runtime screenshot status: **blocked by simulator service**, не считается визуально подтверждённым pass.
