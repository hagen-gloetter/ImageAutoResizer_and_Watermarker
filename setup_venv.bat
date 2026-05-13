@echo off
REM setup_venv.bat — Erstellt ein Python-venv und installiert alle Abhängigkeiten.
REM
REM Usage:
REM   setup_venv.bat           -- erstellt .venv im Projektverzeichnis
REM   setup_venv.bat myenv     -- erstellt ein venv mit benutzerdefiniertem Namen

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "VENV_NAME=%~1"
if "%VENV_NAME%"=="" set "VENV_NAME=.venv"
set "VENV_PATH=%SCRIPT_DIR%%VENV_NAME%"
set "REQ_FILE=%SCRIPT_DIR%requirements.txt"

echo === ImageAutoResizer ^& Watermarker — venv Setup ===
echo.

REM --- Python finden ---
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python 3 nicht gefunden.
    echo Bitte installieren: https://www.python.org/downloads/
    exit /b 1
)

REM Python-Version pruefen
for /f "tokens=*" %%i in ('python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"') do set "PY_VERSION=%%i"
for /f "tokens=*" %%i in ('python -c "import sys; print(sys.version_info.minor)"') do set "PY_MINOR=%%i"

if %PY_MINOR% lss 10 (
    echo Error: Python ^>= 3.10 erforderlich, gefunden: %PY_VERSION%
    exit /b 1
)
echo Python %PY_VERSION% gefunden.

REM --- venv erstellen ---
if exist "%VENV_PATH%" (
    echo venv existiert bereits: %VENV_PATH%
    set /p "answer=Neu erstellen? (j/N) "
    if /i "!answer!"=="j" (
        rmdir /s /q "%VENV_PATH%"
        python -m venv "%VENV_PATH%"
        echo venv neu erstellt.
    ) else (
        echo Bestehendes venv wird weiterverwendet.
    )
) else (
    python -m venv "%VENV_PATH%"
    echo venv erstellt: %VENV_PATH%
)

REM --- Aktivieren ---
call "%VENV_PATH%\Scripts\activate.bat"
echo venv aktiviert.

REM --- pip aktualisieren ---
echo.
echo pip aktualisieren...
pip install --upgrade pip --quiet

REM --- Abhaengigkeiten installieren ---
if exist "%REQ_FILE%" (
    echo Installiere Abhaengigkeiten aus %REQ_FILE% ...
    pip install -r "%REQ_FILE%"
) else (
    echo Warning: requirements.txt nicht gefunden
    pip install "Pillow>=10.0" "pillow-heif>=0.10.0"
)

REM --- Zusammenfassung ---
echo.
echo === Setup abgeschlossen ===
echo.
echo Aktivieren:   %VENV_NAME%\Scripts\activate.bat
echo Starten:      python python\watermarker_v2.py ^<bildordner^>
echo Deaktivieren: deactivate
echo.

endlocal
