@echo on

:: Backup environment variables (only if the variables are set)
if defined INCLUDE (
    set "INCLUDE_CONDA_NVCC_BACKUP=%INCLUDE%"
) else (
    set "INCLUDE_CONDA_NVCC_BACKUP=UNSET"
)

if defined LIB (
    set "LIB_CONDA_NVCC_BACKUP=%LIB%"
) else (
    set "LIB_CONDA_NVCC_BACKUP=UNSET"
)

:: Append `targets` to search path to give exist includes preference
set "INCLUDE=%INCLUDE%;%LIBRARY_INC%\targets\@targets_dir@;%LIBRARY_INC%\targets\@targets_dir@\cccl"

:: `Library\lib\<arch>` is not on the default link path
if "%CONDA_BUILD%" == "1" (
    set "LIB=%LIB%;%LIBRARY_LIB%\@targets_dir@;%BUILD_PREFIX%\Library\lib\@targets_dir@"
) else (
    set "LIB=%LIB%;%CONDA_PREFIX%\Library\lib\@targets_dir@"
)

if "%CONDA_BUILD%" == "1" (
    :: Set good defaults for common target architectures according to host platform for common
    :: configuration environment variables
    if not defined CUDAARCHS (
        set "CUDAARCHS=@default_cudaarchs@"
        set "CUDAARCHS_BACKUP=UNSET"
    )
    if not defined NVCC_GENCODE (
        set "NVCC_GENCODE=@default_nvcc_gencode@"
        set "NVCC_GENCODE_BACKUP=UNSET"
    )
)
