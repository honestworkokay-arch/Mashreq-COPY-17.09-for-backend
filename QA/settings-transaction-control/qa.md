# Settings & transaction control QA

Дата проверки: 2026-09-10  
Устройство: iPhone 17 Pro Simulator, iOS 26.4  
Прямой QA-маршрут: `--qa-screen settings`

## Проверено

- Экран Settings открывается через Services / More.
- Имя, фамилия, email и SMS-номер загружаются из `AppSession`.
- IBAN, account number и balance загружаются из того же источника.
- UAE IBAN проходит структурную проверку и MOD-97.
- Добавление debit-операции уменьшает баланс, credit/top-up увеличивает.
- Редактирование с включённым reconciliation применяет только разницу между старой и новой суммой.
- Refund создаёт отдельную credit-транзакцию и не удаляет исходное списание.
- Повторный refund той же операции блокируется.
- Delete удаляет строку истории, но не меняет баланс.
- Изменения профиля, счёта и операций сохраняются в UserDefaults.
- Изменённые profile/account values используются на Login, More, Accounts, Overview, payment source и OTP.

## Доказательства

- `swiftc -typecheck`: успешно, без ошибок.
- `xcodebuild ... build`: `BUILD SUCCEEDED`.
- Runtime screenshot after spacing correction: `settings-final.png`.

## Ограничение

Email и SMS-номер управляют локальными демонстрационными данными и OTP-маской. Реальная отправка email/SMS не подключена к внешнему провайдеру.
