# Build script for Windows using Visual Studio 2026

# Set paths
$vsPath = "G:\visual studio\2026"
$msBuildPath = "$vsPath\MSBuild\Current\Bin\MSBuild.exe"
$cmakePath = "$vsPath\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
$buildDir = "$PSScriptRoot\build\windows"

# Clean previous build
if (Test-Path $buildDir) {
    Remove-Item -Path $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

# Set environment variables
$env:Path = "$vsPath\VC\Auxiliary\Build;$env:Path"
$env:VCToolsVersion = "14.39.33519"
$env:WindowsSdkDir = "C:\Program Files (x86)\Windows Kits\10\"
$env:WindowsSdkVersion = "10.0.26100.0"

# Configure with CMake
& $cmakePath `
    -S "$PSScriptRoot\windows" `
    -B "$buildDir\x64" `
    -G "Visual Studio 17 2022" `
    -A x64 `
    -DCMAKE_SYSTEM_VERSION=10.0.26100.0 `
    -DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded$<$<CONFIG:Debug>:Debug>" `
    -DFLUTTER_TARGET_PLATFORM=windows-x64

if ($LASTEXITCODE -ne 0) {
    Write-Error "CMake configuration failed"
    exit 1
}

# Build with MSBuild
& $msBuildPath `
    "$buildDir\x64\ALL_BUILD.vcxproj" `
    /p:Configuration=Release `
    /p:Platform=x64 `
    /m

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

# Copy the built files to the Flutter build directory
$releaseDir = "$buildDir\x64\Release"
$flutterBuildDir = "$PSScriptRoot\build\windows\x64\runner\Release"

if (-not (Test-Path $flutterBuildDir)) {
    New-Item -ItemType Directory -Path $flutterBuildDir -Force | Out-Null
}

Copy-Item -Path "$releaseDir\*" -Destination $flutterBuildDir -Recurse -Force

Write-Host "Build completed successfully" -ForegroundColor Green
