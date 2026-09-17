# Mashreq backend

Отдельный сервер для iOS-приложения:

- регистрация и вход;
- хранение пользователей, бенефициаров и операций в PostgreSQL;
- серверная генерация шестизначного OTP;
- OTP и банковские уведомления через SMTP email и Twilio SMS;
- PDF-квитанции через JasperReports 7;
- хранение неизменяемого PDF и его SHA-256 в PostgreSQL;
- отправка квитанции на зарегистрированный email.

## Архитектура

```text
iOS app
   │ HTTPS + Bearer token
   ▼
Spring Boot API
   ├── PostgreSQL: users, sessions, beneficiaries, transactions, receipts
   ├── JasperReports: JRXML → PDF
   ├── SMTP: OTP, уведомления, PDF-вложение
   └── Twilio: SMS OTP и уведомления
```

Секреты не находятся в исходном коде. Реальный пароль почты, который был передан в чате,
нужно заменить у провайдера и указать только в локальном `Backend/.env` или в защищённых
переменных production-сервера.

## Быстрый запуск

Требования для локального запуска без Docker: Java 21, Maven 3.6.3+ и PostgreSQL.
Самый короткий путь — Docker Compose.

```bash
cd Backend
cp .env.example .env
```

Заполните `.env`:

- `DB_PASSWORD` — пароль PostgreSQL;
- `OTP_PEPPER` — случайная строка длиной минимум 32 символа;
- `DELIVERY_MODE=console` для безопасной локальной проверки;
- `DELIVERY_MODE=live` только после заполнения SMTP и Twilio;
- `ALLOW_DEBUG_OTP=true` разрешается только локально вместе с `DELIVERY_MODE=console`.

Затем:

```bash
docker compose up --build
```

Проверка состояния:

```bash
curl http://127.0.0.1:8080/health
```

## Основные API

Все маршруты, кроме регистрации и входа, требуют:

```http
Authorization: Bearer <token>
Content-Type: application/json
```

### 1. Регистрация

`POST /v1/auth/register`

```json
{
  "firstName": "Alesia",
  "lastName": "Danylikevych",
  "mobileNumber": "+971501234567",
  "email": "customer@example.com",
  "iban": "AE180330000019101196666",
  "accountNumber": "019101196666",
  "password": "replace-with-a-strong-password"
}
```

Ответ содержит `token`, `expiresAt` и профиль пользователя. Пароль хранится только как
BCrypt-хэш, а сам bearer-токен — только как SHA-256-хэш.

### 2. Вход

`POST /v1/auth/login`

```json
{
  "email": "customer@example.com",
  "password": "replace-with-a-strong-password"
}
```

### 3. Отправка OTP

`POST /v1/otp/send`

```json
{
  "purpose": "TRANSFER",
  "channels": ["EMAIL", "SMS"]
}
```

Доступные `purpose`:

- `REGISTRATION`
- `LOGIN`
- `BENEFICIARY_ADDED`
- `TRANSFER`
- `DEBIT`
- `CREDIT`

OTP действует 5 минут, повторная отправка ограничена 60 секундами, число попыток — 5.
В базе хранится только HMAC-SHA256 digest кода.

### 4. Проверка OTP

`POST /v1/otp/verify`

```json
{
  "challengeId": "00000000-0000-0000-0000-000000000000",
  "code": "123456"
}
```

### 5. Добавление бенефициара

`POST /v1/beneficiaries`

```json
{
  "nickname": "Larisa",
  "fullName": "Atarshchikova Larisa",
  "bankName": "Mashreq Bank",
  "country": "United Arab Emirates",
  "swiftCode": "BOMLAEAD",
  "iban": "AE180330000019101196666"
}
```

После записи сервер отправляет SMS и email на контакты авторизованного пользователя.

### 6. Создание операции

`POST /v1/transactions`

```json
{
  "clientRequestId": "76042ac4-1167-4ac4-af30-1c9cf3bde2a5",
  "transactionType": "LOCAL_TRANSFER",
  "beneficiaryName": "Atarshchikova Larisa",
  "beneficiaryBank": "Mashreq Bank",
  "beneficiaryCountry": "United Arab Emirates",
  "beneficiarySwift": "BOMLAEAD",
  "beneficiaryIban": "AE180330000019101196666",
  "senderAccount": "019101196666",
  "currency": "AED",
  "amount": 152.00,
  "fee": 0.00,
  "purpose": "Personal transfer"
}
```

Сервер создаёт reference и время самостоятельно, сохраняет операцию, затем отправляет
email/SMS. `clientRequestId` генерируется iOS-клиентом один раз для одной операции и
защищает от дублирования при повторе сетевого запроса. Для пополнения и списания
используйте `ACCOUNT_CREDIT` и `ACCOUNT_DEBIT`.

### 7. Генерация JasperReports PDF

`POST /v1/transactions/{transactionId}/receipt`

Сервер:

1. читает операцию только текущего пользователя;
2. заполняет `src/main/resources/reports/fund_transfer_receipt.jrxml`;
3. формирует PDF через JasperReports;
4. сохраняет PDF, имя файла, версию шаблона и SHA-256;
5. возвращает metadata квитанции.

Повторный запрос для той же операции не создаёт дубликат — возвращает уже сохранённую
квитанцию.

### 8. Скачать PDF

`GET /v1/receipts/{receiptId}/pdf`

Ответ: `application/pdf`, `Content-Disposition: attachment` и заголовок
`X-Content-SHA256` для проверки целостности.

### 9. Отправить квитанцию

`POST /v1/receipts/{receiptId}/deliver`

```json
{
  "channels": ["EMAIL", "SMS"]
}
```

На email приходит PDF-вложение. SMS содержит reference и сообщает, что безопасное
скачивание PDF доступно в приложении.

## Что подключить в iOS

1. После регистрации/входа сохранить `token` в Keychain.
2. После подтверждения перевода вызвать `POST /v1/transactions`.
3. На экране успеха вызвать `POST /v1/transactions/{id}/receipt`.
4. Кнопка **Download receipt** вызывает `GET /v1/receipts/{id}/pdf`.
5. Кнопка **Email/SMS receipt** вызывает `/deliver`.

Не сохраняйте SMTP/Twilio credentials внутри Swift-приложения — они должны оставаться
только на сервере.

## Production checklist

- HTTPS и reverse proxy;
- `DELIVERY_MODE=live`;
- отдельный случайный `OTP_PEPPER` в secret manager;
- SMTP/Twilio credentials в secret manager;
- managed PostgreSQL с TLS, encryption at rest и резервными копиями;
- rate limit на `/auth`, `/otp/send` и `/otp/verify` на уровне API gateway;
- журналирование без паролей, OTP, токенов, полного IBAN и полного номера телефона;
- политика удаления персональных данных и PDF-квитанций;
- мониторинг неуспешных доставок из `message_deliveries`.
