# Custom toolchain file for Visual Studio 2026
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_VERSION 10.0)

# Specify the compilers
set(CMAKE_C_COMPILER "G:/visual studio/2026/VC/Tools/MSVC/14.39.33519/bin/Hostx64/x64/cl.exe")
set(CMAKE_CXX_COMPILER "G:/visual studio/2026/VC/Tools/MSVC/14.39.33519/bin/Hostx64/x64/cl.exe")

# Set the target architecture
set(CMAKE_GENERATOR_PLATFORM x64)

# Set the generator to Visual Studio 17 2022 (compatible with 2026)
set(CMAKE_GENERATOR "Visual Studio 17 2022" CACHE INTERNAL "")

# Set the toolset to v143 (Visual Studio 2022)
set(CMAKE_GENERATOR_TOOLSET "v143" CACHE INTERNAL "")

# Set the Windows SDK version to 10.0.26100.0 (Windows 11 SDK)
set(CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION "10.0.26100.0")
set(CMAKE_SYSTEM_VERSION "10.0")

# Set the C and C++ standards
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
