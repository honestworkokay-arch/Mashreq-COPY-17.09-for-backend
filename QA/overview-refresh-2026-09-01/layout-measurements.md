# Overview layout measurements

Источник истины: `codex-clipboard-32165e05-206d-4b25-9a95-6d0d0eca0c76.png`,
`588 × 1280 px`. Для iPhone 17 Pro используется ширина `402 pt`, поэтому
коэффициент пересчёта равен `588 / 402 = 1.4626866 px/pt`.

| Элемент | Границы в референсе, px | Границы, pt | Реализация |
| --- | --- | --- | --- |
| NEO symbol | `x 53…136`, `y 122…163` | `x 36.2…93.0`, `y 83.4…111.4` | `59 × 57 pt`, leading `12 pt`, offset `-9 pt` |
| Chat circle | `x 360…409`, `y 132…181` | `x 246.1…279.6`, `y 90.2…123.7` | outer hit area `40 pt`, visible circle `34 pt` |
| Notification circle | `x 430…480`, `y 133…181` | `x 294.0…328.2`, `y 90.9…123.7` | center step from Chat `48 pt` |
| IA circle | `x 501…550`, `y 131…181` | `x 342.5…376.0`, `y 89.6…123.7` | trailing header inset `23 pt` |
| Accounts tab | `x 37…180`, `y 248…306` | `x 25.3…123.1`, `y 169.6…209.2` | width `98 pt`, height `42 pt`, inset `24 pt` |
| Orange boundary, sides | `y 424…425` | `y 289.9…290.6` | header frame `306 pt`, shape endpoint `288 pt` plus native raster edge |
| Summary card | approximately `x 35…553`, `y 331…491` | approximately `x 24…378`, `y 226…336` | scroll top and card geometry unchanged |

Vertical stack remains `83 pt top + 57 pt logo row + 26 pt gap`. This preserves
the tabs and overlapping account card positions while the new high-resolution
assets receive their own measured internal sizes.
