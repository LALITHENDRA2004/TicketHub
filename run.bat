@echo off
rem Starts TicketHub locally without Docker: MySQL service, Spring Boot API (:8080) and Vite web (:5173).
rem Close the "TicketHub API" and "TicketHub Web" windows to stop. MySQL is left running.
setlocal
cd /d "%~dp0"

if not exist ".env" (
    copy ".env.example" ".env" >nul
    echo Created .env from .env.example.
    echo Set DB_USERNAME and DB_PASSWORD in .env to your MySQL login, then run this again.
    pause
    exit /b 1
)
for /f "usebackq eol=# tokens=1,* delims==" %%a in (".env") do set "%%a=%%b"
if not defined MYSQL_SERVICE set "MYSQL_SERVICE=MySQL80"

where java >nul 2>&1 || (echo Java not found on PATH. Install JDK 25. & pause & exit /b 1)
where npm >nul 2>&1 || (echo npm not found on PATH. Install Node 24. & pause & exit /b 1)

echo [1/3] MySQL (%MYSQL_SERVICE%)
rem Full paths: Git's Unix tools on PATH can shadow find and ping.
"%SystemRoot%\System32\sc.exe" query "%MYSQL_SERVICE%" | "%SystemRoot%\System32\findstr.exe" /c:"RUNNING" >nul
if errorlevel 1 (
    net start "%MYSQL_SERVICE%"
    if errorlevel 1 (
        echo Could not start the %MYSQL_SERVICE% service. Run this file as Administrator,
        echo or set MYSQL_SERVICE in .env to your MySQL service name.
        pause
        exit /b 1
    )
) else (
    echo MySQL is already running.
)

rem Redis and Mailpit are not installed locally; keep them out of /actuator/health.
set "MANAGEMENT_HEALTH_REDIS_ENABLED=false"
set "MANAGEMENT_HEALTH_MAIL_ENABLED=false"

echo [2/3] Backend
start "TicketHub API" /d "%~dp0backend" cmd /k .\mvnw.cmd spring-boot:run

echo [3/3] Frontend
if not exist "frontend\node_modules" (
    echo Installing frontend dependencies...
    pushd frontend
    call npm install
    popd
)
start "TicketHub Web" /d "%~dp0frontend" cmd /k npm run dev

echo Waiting for the API to report healthy (first run downloads Maven dependencies)...
for /l %%i in (1,1,100) do (
    curl -sf http://localhost:8080/actuator/health >nul 2>&1 && goto :up
    "%SystemRoot%\System32\ping.exe" -n 4 127.0.0.1 >nul
)
echo The API is not healthy after 5 minutes. Check the "TicketHub API" window for errors.
pause
exit /b 1

:up
echo.
echo TicketHub is running:
echo   Web        http://localhost:5173
echo   API health http://localhost:8080/actuator/health
echo   API docs   http://localhost:8080/swagger-ui.html
start "" http://localhost:5173
endlocal
