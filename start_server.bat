@echo off
REM Kanika's voice as an HTTP server: GPT-SoVITS api_v2 on http://127.0.0.1:9880
REM
REM   start_server.bat                  this machine only
REM   start_server.bat 0.0.0.0 9880     reachable from the network - NO AUTH,
REM                                     anyone who reaches the port can use it
REM
REM Leave this window open. First start spends ~45s loading models.

setlocal
if "%GSV_HOME%"=="" (set GSV=C:\GPT-SoVITS-v2pro-20250604) else (set GSV=%GSV_HOME%)
set HOST=127.0.0.1
if not "%~1"=="" set HOST=%~1
set PORT=9880
if not "%~2"=="" set PORT=%~2

if not exist "%GSV%\runtime\python.exe" (
    echo GPT-SoVITS not found at %GSV%
    echo Install it, or set GSV_HOME to where it is. See README.
    pause
    exit /b 1
)

REM A missing weight file does not stop the server: it quietly loads the generic
REM pretrained voice instead. So check before starting, not after.
for %%F in ("GPT_weights_v2Pro\kanika-e15.ckpt" "SoVITS_weights_v2Pro\kanika_e8_s288.pth" "GPT_SoVITS\configs\tts_infer_kanika.yaml" "voices\kanika\refs\conversational.wav") do (
    if not exist "%GSV%\%%~F" (
        echo Missing %GSV%\%%~F
        echo Run setup.ps1 first.
        pause
        exit /b 1
    )
)

REM The server prints Chinese progress text. If its output is not a console
REM window - redirected to a log, run as a service - Windows' default code page
REM cannot encode it and every request fails. UTF-8 makes that impossible.
set PYTHONIOENCODING=utf-8

REM cd first: the server resolves its config, weights and reference clips
REM relative to the GPT-SoVITS folder.
cd /d "%GSV%"
echo Kanika voice server on http://%HOST%:%PORT%  (Ctrl+C to stop)
"%GSV%\runtime\python.exe" api_v2.py -a %HOST% -p %PORT% -c GPT_SoVITS/configs/tts_infer_kanika.yaml
pause
