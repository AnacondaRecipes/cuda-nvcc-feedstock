@echo on
setlocal enableextensions enabledelayedexpansion
if errorlevel 1 exit 1

set "TARGETS_DIR="
if /I "%CROSS_TARGET_PLATFORM%" == "win-64" set "TARGETS_DIR=x64"
if /I "%CROSS_TARGET_PLATFORM%" == "win-arm64" set "TARGETS_DIR=arm64"
if not defined TARGETS_DIR (
    echo ERROR: Unsupported Windows cross target "%CROSS_TARGET_PLATFORM%".
    exit /b 1
)

sed -e "s/@targets_dir@/%TARGETS_DIR%/g" ^
    -e "s/@default_cudaarchs@/%DEFAULT_CUDAARCHS%/g" ^
    -e "s/@default_nvcc_gencode@/%DEFAULT_NVCC_GENCODE%/g" ^
    %RECIPE_DIR%\activate.bat > %RECIPE_DIR%\activate-replaced.bat
if errorlevel 1 exit 1

:: Activation script
mkdir %PREFIX%\etc\conda\activate.d
copy %RECIPE_DIR%\activate-replaced.bat %PREFIX%\etc\conda\activate.d\~cuda-nvcc_activate.bat
if errorlevel 1 exit 1

:: Deactivation script
mkdir %PREFIX%\etc\conda\deactivate.d
copy %RECIPE_DIR%\deactivate.bat %PREFIX%\etc\conda\deactivate.d\~cuda-nvcc_deactivate.bat
if errorlevel 1 exit 1
