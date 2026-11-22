# SQL connection verified — 30/10/2026

SQL Server is connected successfully when AutoCar is started by Visual Studio under the interactive Windows user.

- Server: `LAPTOP-Q9QL0PUF`, TCP1433 is listening.
- Database: `AutoCarDB`; SQL Authentication configured only in ignored `AutoCar.Api/appsettings.Local.json`.
- `GET http://localhost:5180/health/database` returned `status: connected` with15 brands and78 seeded variants before integration tests.
- Web `http://localhost:5080/` returned200 and rendered car cards supplied by the API.
- Both project user settings had selected IIS Express, while the MVC client targeted API5180. Selected project launch profiles instead and applied shared profile **AutoCar API + Web** (`AutoCar.slnLaunch`).
- The restricted agent process still encounters Windows TLS/SChannel errors. This is distinct from the working applications launched by Visual Studio; it does not establish that the SQL password is wrong.

## Real integration checks performed

Login correct/incorrect, Customer403 on Admin operations, brand CRUD, car CRUD/update409 on stale versions, insufficient inventory409, pending orders, confirm/cancel/restore stock, manual payment, Completed transition and revenue increase all ran against SQL Server successfully. All five dashboard endpoints returned200.

The simultaneous-confirmation test returned204 and500. EF wraps the deadlock SqlException inside InvalidOperationException. Updated ErrorMiddleware to recognize the wrapped1205 error and return409. The changed solution builds with0 errors/warnings into `bin/Verification`; loading that fix into the existing Visual Studio processes and rerunning the full integration script is still pending. The agent cannot stop those higher-privilege processes. Do not label the complete integration suite as passed.

QA car records79/80 were hidden and Pending/Confirmed race orders3/4 were cancelled through the API. SQL retains80 total variants including2 hidden QA records; public catalog contains the original78. Completed QA order/payment and audit records remain for traceability. `docs/INTEGRATION_RESULTS.json` records the partial test run, including the failed race check.

To reload the latest code, close the running AutoCar.Api and AutoCar.Web console windows, select **AutoCar API + Web** in Visual Studio, then F5. Open `/health/database` for a safe connection/schema diagnosis. The endpoint does not expose passwords or connection strings. Development initialization errors now appear in health details without hiding the failure behind a terminated server process.

SQL login password and website account passwords are separate. Seeded website accounts use `Seed:Password` in the local configuration, not the SQL login password.
