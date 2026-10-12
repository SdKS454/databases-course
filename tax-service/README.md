# Tax Service

Небольшое Jakarta Servlet-приложение для хранения расходов и отображения
рассчитанного налога. В таблице хранятся только расход и дата; текущий процент
запрашивается у первого сервиса при каждом открытии списка.

## Требования

- Java 21
- Maven 3.9+
- PostgreSQL
- Tomcat 10.1+ (Jakarta Servlet 6)
- Первый сервис с endpoint `GET /api/tax`

## PostgreSQL

Создайте базу данных и выполните SQL от пользователя, у которого есть права на
создание sequence и таблицы:

```sql
CREATE SEQUENCE tax_payment_id_seq;

CREATE TABLE tax_payment (
    id BIGINT PRIMARY KEY DEFAULT nextval('tax_payment_id_seq'),
    expense_amount NUMERIC(15, 2) NOT NULL CHECK (expense_amount > 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER SEQUENCE tax_payment_id_seq
    OWNED BY tax_payment.id;
```

Если sequence и таблица уже созданы, этот блок повторно выполнять не нужно.
Приложение использует именно `tax_payment` и `tax_payment_id_seq`.

## Переменные окружения

Перед запуском Tomcat задайте:

```bash
export DB_URL='jdbc:postgresql://127.0.0.1:5432/tax_service'
export DB_USER='tax_service'
export DB_PASSWORD='change-me'
export TAX_SERVICE_URL='http://127.0.0.1:8081/app1'
```

Пример для локальной PostgreSQL, если у вас уже есть стандартный пользователь
`postgres`:

```bash
export DB_URL='jdbc:postgresql://127.0.0.1:5432/tax_service'
export DB_USER='postgres'
export DB_PASSWORD='ВАШ_ПАРОЛЬ_POSTGRES'
```

Вариант с отдельной ролью `tax_service` требует предварительно создать её в
PostgreSQL:

```sql
CREATE ROLE tax_service LOGIN PASSWORD 'change-me';
CREATE DATABASE tax_service OWNER tax_service;
```

Затем подключитесь к базе `tax_service` под владельцем и выполните SQL создания
`tax_payment` из раздела выше. Ошибка `роль "tax_service" не существует` означает,
что в `DB_USER` указано имя, которого нет в PostgreSQL; это не ошибка WAR.

Важно: переменные должны быть доступны именно процессу Tomcat. Если Tomcat уже
запущен, `export` в другом терминале его не изменит — после настройки Tomcat
нужно перезапустить. Для запуска из текущего Linux/macOS терминала:

```bash
export DB_URL='jdbc:postgresql://127.0.0.1:5432/tax_service'
export DB_USER='tax_service'
export DB_PASSWORD='change-me'
export TAX_SERVICE_URL='http://127.0.0.1:8081/app1'
$CATALINA_HOME/bin/catalina.sh run
```

Для постоянного запуска Tomcat добавьте настройки в
`$CATALINA_BASE/bin/setenv.sh`:

```bash
#!/bin/sh
export DB_URL='jdbc:postgresql://127.0.0.1:5432/tax_service'
export DB_USER='tax_service'
export DB_PASSWORD='change-me'
export TAX_SERVICE_URL='http://127.0.0.1:8081/app1'
```

В IntelliJ IDEA добавьте эти значения в **Run/Debug Configuration →
Environment variables** для Tomcat. Дополнительно `DB_URL`, `DB_USER` и
`DB_PASSWORD` можно передать как JVM options:

```text
-DDB_URL=jdbc:postgresql://127.0.0.1:5432/tax_service
-DDB_USER=tax_service
-DDB_PASSWORD=change-me
```

Для `DB_*` приложение сначала использует environment variable, затем одноимённое
JVM system property; если не задано ни то ни другое, приложение останавливается
с явной ошибкой. `TAX_SERVICE_URL` по-прежнему задаётся environment variable.

`TAX_SERVICE_URL` — только базовый URL первого сервиса. Приложение добавляет
путь `/api/tax`, поэтому запрос выполняется по адресу:
`http://127.0.0.1:8081/app1/api/tax` для стандартного context path админки.

Ожидаемый успешный ответ первого сервиса:

```json
{
  "success": true,
  "percent": 13.00,
  "updatedAt": "2026-10-11T09:30:00+03:00",
  "message": null
}
```

Клиент также принимает минимальный ответ `{"percent": 13.0}`. Ответ должен иметь
HTTP 200, а `percent` должен быть числом от 0 до 100; при наличии поля
`success` оно не должно быть `false`.
Недоступность сервиса, не-200, неверный JSON или процент приводят к ошибке на
странице; fallback и кэширование не используются.

## Сборка WAR

Из каталога `tax-service`:

```bash
mvn clean package
```

Результат сборки:

```text
target/tax-service.war
```

Для локальной среды с JDK 17, только для проверки исходников, можно временно
переопределить release:

```bash
mvn -Dmaven.compiler.release=17 clean package
```

Основная конфигурация POM рассчитана на Java 21.

## Развёртывание в Tomcat

Скопируйте WAR в каталог `webapps`:

```bash
cp target/tax-service.war "$CATALINA_BASE/webapps/"
```

При имени файла `tax-service.war` context path будет `/tax-service`.
После запуска Tomcat приложение доступно по адресу:

```text
http://localhost:8080/tax-service/tax-payments
```

При открытии корня приложения
`http://localhost:8080/tax-service/` `index.jsp` автоматически перенаправляет
на `/tax-payments`. В конфигурации запуска IntelliJ IDEA укажите URL:

```text
http://localhost:8080/tax-service/tax-payments
```

`web.xml` не требуется: сервлеты регистрируются аннотациями `@WebServlet`.
JSP-файлы находятся в `src/main/webapp/jsp` и доступны сервлетам через внутренние
forward-запросы.
Приложение использует только Spring JDBC (`JdbcTemplate`); Spring Application
Context и component scanning не используются. Зависимости Spring JDBC и
PostgreSQL упаковываются в WAR, а Servlet API предоставляется Tomcat.
Цепочка `DatabaseConfig -> TaxPaymentRepositoryJdbcImpl ->
TaxPaymentServiceImpl` создаётся вручную в `init(ServletConfig)` каждого
сервлета.

## URL и сценарий проверки

- `GET /login` — вход.
- `GET /register` — регистрация.
- `GET /logout` — выход и завершение сессии.

- `GET /tax-payments` — текущий процент, форма добавления и история расходов.
- `POST /tax-payments` — создать расход и перейти обратно к списку.
- `GET /tax-payments/edit?id=...` — открыть редактирование записи.
- `POST /tax-payments/edit` — изменить расход и перейти обратно к списку.

Перед первым запуском выполните `src/main/resources/auth-schema.sql` в базе
`tax_service`. ФИО принимается только кириллицей без пробелов и дефисов,
пароль — минимум 4 символа. Пароль хранится как учебный SHA-256 hex-хеш;
для production такой вариант использовать нельзя.

SQL можно выполнить так:

```bash
psql -U postgres -d tax_service \
  -f src/main/resources/auth-schema.sql
```

Проверка авторизации:

1. Откройте `/tax-service/` — приложение перенаправит на `/login`.
2. Перейдите по ссылке регистрации и заполните, например:
   `ivanov`, `Иван`, `Иванов`, `Иванович`, пароль `1234`.
3. После регистрации войдите с созданным логином и паролем.
4. Убедитесь, что `/tax-payments` открывается только после входа, а кнопка
   `Выйти` завершает сессию и возвращает на `/login`.
5. Введите некириллическое имя или имя с цифрами — регистрация должна быть
   отклонена с сообщением об ошибке.

Расходы разделяются по аккаунтам через `tax_payment.user_id`: каждый запрос
списка, создания и редактирования ограничен текущим пользователем. Старые
строки, созданные до этой миграции и имеющие `user_id IS NULL`, не показываются
новым пользователям; при необходимости их можно вручную назначить владельцу:

```sql
UPDATE tax_payment
SET user_id = (SELECT id FROM app_user WHERE login = 'ivanov')
WHERE user_id IS NULL;
```

Проверка динамического процента:

1. Соберите и задеплойте `tax-admin` из соседнего проекта в Tomcat как
   `app1.war`, чтобы context path был `/app1`.
2. Откройте `http://localhost:8080/app1/admin/login` и войдите с
   `admin` / `admin` (если переменные `ADMIN_LOGIN` и `ADMIN_PASSWORD` не
   переопределены).
3. Установите в админке `13`, задайте `TAX_SERVICE_URL` равным
   `http://localhost:8080/app1` и перезапустите `tax-service`.
4. Откройте `/tax-service/tax-payments`, добавьте расход `1000.00` и убедитесь,
   что в истории отображается налог `130.00`.
5. В админке измените процент на `20`, не меняя строку в `tax_payment`.
6. Обновите страницу списка второго сервиса и убедитесь, что та же запись
   показывает налог `200.00`. В таблице остаются только исходные расход и дата.

Быстрая проверка API админки:

```bash
curl -i http://localhost:8080/app1/api/tax
```

Ожидаются HTTP 200 и JSON с `"success":true` и текущим `"percent"`.
