if /i not "%~1"=="elevated" (
    setlocal
    set "scriptPath=%~f0"
    powershell.exe -NoProfile -Command "Start-Process -FilePath $env:scriptPath -ArgumentList elevated -Verb RunAs -Wait"
    exit /b
)

"%SystemRoot%\System32\reg.exe" delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags" /v "{f1ee26ee-6e53-4e4b-a444-7e7bf3c455d4}" /f /reg:64
if errorlevel 1 exit /b 1
"%SystemRoot%\System32\rundll32.exe" "%SystemRoot%\System32\apphelp.dll",ShimFlushCache
