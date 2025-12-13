@echo off
setlocal enabledelayedexpansion

:: Set Visual Studio 2026 path
set "VS2026_PATH=E:\visual studio\2026"
set "MSBUILD_PATH=%VS2026_PATH%\MSBuild\Current\Bin\MSBuild.exe"
set "CMAKE_PATH=%VS2026_PATH%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"

:: Clean previous build
if exist "build\windows\x64" rmdir /s /q "build\windows\x64"
mkdir "build\windows\x64"

:: Configure with CMake
"%CMAKE_PATH%" ^
  -S . ^
  -B "build/windows/x64" ^
  -G "Visual Studio 17 2022" ^
  -A x64 ^
  -DFLUTTER_TARGET_PLATFORM=windows-x64

if %ERRORLEVEL% neq 0 (
    echo CMake configuration failed
    exit /b 1
)

:: Build with MSBuild
"%MSBUILD_PATH%" ^
  "build/windows/x64/ALL_BUILD.vcxproj" ^
  /p:Configuration=Release ^
  /p:Platform=x64 ^
  /m

if %ERRORLEVEL% neq 0 (
    echo Build failed
    exit /b 1
)

echo Build completed successfully

:: Copy the built files to the Flutter build directory
xcopy /E /I /Y "build\windows\x64\Release\*" "..\build\windows\x64\runner\Release\"

pause
