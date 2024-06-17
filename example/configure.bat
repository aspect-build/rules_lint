:: run this on Windows to set up example for use
@echo Configuring example for Windows
:: aspect-cli doesn't support windows, so disable it
del %~dp0.bazeliskrc
:: ../.bazelversion syntax not supported by windows bazelisk
del %~dp0.bazelversion
copy %~dp0\..\.bazelversion %~dp0
:: copy clang-tidy and clang-format
copy "%USERPROFILE%\Downloads\clang+llvm-18.1.6-x86_64-pc-windows-msvc.tar\clang+llvm-18.1.6-x86_64-pc-windows-msvc\bin\clang-tidy.exe" %~dp0tools\lint\
copy "%USERPROFILE%\Downloads\clang+llvm-18.1.6-x86_64-pc-windows-msvc.tar\clang+llvm-18.1.6-x86_64-pc-windows-msvc\bin\clang-format.exe" %~dp0tools\lint\
