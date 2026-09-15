@echo on
setlocal EnableExtensions

set "TEST_PLATFORM="
set "SYSTEM_TYPE="
REM Query the native Windows system type independently of process emulation.
for /f "delims=" %%A in ('powershell -NoProfile -NonInteractive -Command "(Get-CimInstance Win32_ComputerSystem).SystemType"') do set "SYSTEM_TYPE=%%A"
if /I "%SYSTEM_TYPE:~0,3%" == "x64" set "TEST_PLATFORM=win-64"
if /I "%SYSTEM_TYPE:~0,5%" == "ARM64" set "TEST_PLATFORM=win-arm64"

if not defined TEST_PLATFORM (
    echo ERROR: Unsupported Windows system type "%SYSTEM_TYPE%".
    exit /b 1
)

set "CAN_RUN_NVCC="
if /I "%TEST_PLATFORM%" == "%TARGET_PLATFORM%" set "CAN_RUN_NVCC=1"
REM Windows ARM64 can run x64 host tools through Prism.
if /I "%TEST_PLATFORM%" == "win-arm64" (
    if /I "%TARGET_PLATFORM%" == "win-64" (
        set "CAN_RUN_NVCC=1"
    )
)
if not defined CAN_RUN_NVCC (
    echo Skipping NVCC execution tests: host is %TEST_PLATFORM%, tools target %TARGET_PLATFORM%.
    exit /b 0
)

set "TARGETS_DIR="
set "EXPECTED_MACHINE="
if /I "%CROSS_TARGET_PLATFORM%" == "win-64" (
    set "TARGETS_DIR=x64"
    set "EXPECTED_MACHINE=8664 machine"
)
if /I "%CROSS_TARGET_PLATFORM%" == "win-arm64" (
    set "TARGETS_DIR=arm64"
    set "EXPECTED_MACHINE=AA64 machine"
)
if not defined TARGETS_DIR (
    echo ERROR: Unsupported Windows cross target "%CROSS_TARGET_PLATFORM%".
    exit /b 1
)

nvcc --version
if errorlevel 1 exit /b 1

cl /std:c++17 /Zc:preprocessor /Tp test.cpp /link cudart_static.lib /out:test_host.exe
if errorlevel 1 exit /b 1
dumpbin /headers test_host.exe | findstr /I /C:"%EXPECTED_MACHINE%" >nul
if errorlevel 1 (
    echo ERROR: test_host.exe does not target %CROSS_TARGET_PLATFORM%.
    exit /b 1
)

nvcc --verbose test.cu -o test_nvcc.exe
if errorlevel 1 exit /b 1
dumpbin /headers test_nvcc.exe | findstr /I /C:"%EXPECTED_MACHINE%" >nul
if errorlevel 1 (
    echo ERROR: test_nvcc.exe does not target %CROSS_TARGET_PLATFORM%.
    exit /b 1
)

cmake %CMAKE_ARGS% -S . -B .\build -G Ninja
if errorlevel 1 exit /b 1
cmake --build .\build -v
if errorlevel 1 exit /b 1
dumpbin /headers .\build\verify.exe | findstr /I /C:"%EXPECTED_MACHINE%" >nul
if errorlevel 1 (
    echo ERROR: CMake verify.exe does not target %CROSS_TARGET_PLATFORM%.
    exit /b 1
)

if /I "%TEST_PLATFORM%" == "%CROSS_TARGET_PLATFORM%" (
    REM These programs contain device code but do not launch a kernel, so they
    REM can run on GPU-less native CI hosts.
    test_host.exe
    if errorlevel 1 exit /b 1
    test_nvcc.exe
    if errorlevel 1 exit /b 1
    .\build\verify.exe
    if errorlevel 1 exit /b 1
) else (
    echo Cross-compiled executables were validated as %CROSS_TARGET_PLATFORM% and will not be run.
)
