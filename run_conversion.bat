@echo off
setlocal

:: Set up log file
set "LOGFILE=IFCtoIDFconversion.log"
echo [INFO] Starting BIM2SIM conversion > "%LOGFILE%"

:: Check and assign parameters
set "IFC_FILE=%~1"
set "EPW_FILE=%~2"
set "EPLUS_PATH=%~3"

if "%IFC_FILE%"=="" (
    echo [ERROR] Missing IFC file path. >> "%LOGFILE%"
    exit /b 1
)
if "%EPW_FILE%"=="" (
    echo [ERROR] Missing EPW file path. >> "%LOGFILE%"
    exit /b 2
)
if "%EPLUS_PATH%"=="" set "EPLUS_PATH=/usr/local/EnergyPlus-9-4-0/"

:: Extract filenames
for %%F in ("%IFC_FILE%") do set "IFC_NAME=%%~nxF"
for %%F in ("%IFC_FILE%") do set "IFC_BASE=%%~nF"
for %%F in ("%EPW_FILE%") do set "EPW_NAME=%%~nxF"


:: Check if container "ep" exists
docker inspect ep >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [INFO] Container "ep" already exists. >> "%LOGFILE%"

    :: Check if it's running
    docker inspect -f "{{.State.Running}}" ep | findstr /i "true" >nul
    if %ERRORLEVEL%==0 (
        echo [INFO] Container "ep" is already running. >> "%LOGFILE%"
    ) else (
        echo [INFO] Starting existing container "ep". >> "%LOGFILE%"
        docker start ep >> "%LOGFILE%" 2>&1
        if %ERRORLEVEL% NEQ 0 (
            echo [ERROR] Failed to start existing container. >> "%LOGFILE%"
            exit /b 3
        )
    )
) else (
    echo [INFO] Creating and starting new container "ep". >> "%LOGFILE%"
    docker run -dit --name ep tmaile/epone:latest >> "%LOGFILE%" 2>&1 || (
        echo [ERROR] Failed to create new container. >> "%LOGFILE%"
        exit /b 3
    )
)

:: Attempt to clean /tmp folder inside container (log errors but continue)
docker exec ep sh -c "rm -rf /tmp/*" >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo [WARN] Some files in /tmp could not be deleted. >> "%LOGFILE%"
)

:: Copy files into container
docker cp "%IFC_FILE%" ep:/tmp/ >> "%LOGFILE%" 2>&1 || (
    echo [ERROR] Failed to copy IFC file. >> "%LOGFILE%"
    exit /b 4
)
docker cp "%EPW_FILE%" ep:/tmp/ >> "%LOGFILE%" 2>&1 || (
    echo [ERROR] Failed to copy EPW file. >> "%LOGFILE%"
    exit /b 5
)

:: Run conversion script
docker exec ep micromamba run -n base python /home/mambauser/bim2sim/bim2sim/convert_to_idf.py /tmp/%IFC_NAME% /tmp/%EPW_NAME% %EPLUS_PATH% >> "%LOGFILE%" 2>&1 || (
    echo [ERROR] Python script execution failed. >> "%LOGFILE%"
    exit /b 6
)

:: Find gensim output directory
for /f "delims=" %%G in ('docker exec ep sh -c "ls -d /tmp/gensim* 2>/dev/null"') do set "GENSIM_DIR=%%G"

if not defined GENSIM_DIR (
    echo [ERROR] gensim output directory not found. >> "%LOGFILE%"
    exit /b 7
)

:: Compose container and local paths
set "IDF_CONTAINER_PATH=%GENSIM_DIR%/export/EnergyPlus/SimResults/%IFC_BASE%/%IFC_BASE%.idf"
for %%F in ("%IFC_FILE%") do set "IFC_FOLDER=%%~dpF"
set "LOCAL_IDF_PATH=%IFC_FOLDER%%IFC_BASE%.idf"
set "LOCAL_LOGS_FOLDER=%IFC_FOLDER%logs"

:: Ensure logs folder exists
if not exist "%LOCAL_LOGS_FOLDER%" mkdir "%LOCAL_LOGS_FOLDER%"

:: Copy IDF file back to host
docker cp ep:%IDF_CONTAINER_PATH% "%LOCAL_IDF_PATH%" >> "%LOGFILE%" 2>&1 || (
    echo [ERROR] Failed to copy IDF file from container. >> "%LOGFILE%"
    exit /b 8
)
echo [INFO] IDF file copied to: %LOCAL_IDF_PATH% >> "%LOGFILE%"

:: Copy all other files to logs folder
docker cp ep:%GENSIM_DIR%/. "%LOCAL_LOGS_FOLDER%" >> "%LOGFILE%" 2>&1 || (
    echo [WARNING] Failed to copy log files from container. >> "%LOGFILE%"
)

:: Delete gensim directory inside container
docker exec ep sh -c "rm -rf %GENSIM_DIR%" >> "%LOGFILE%" 2>&1 || (
    echo [WARNING] Failed to remove gensim directory in container. >> "%LOGFILE%"
)

echo [SUCCESS] Conversion completed. >> "%LOGFILE%"


endlocal
exit /b 0
