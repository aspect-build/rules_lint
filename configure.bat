:: run this on Windows to set up example for use
@echo Configuring example for Windows
:: aspect-cli doesn't support windows, so disable it
del %~dp0.bazeliskrc
del %~dp0example\.bazeliskrc
:: ../.bazelversion syntax not supported by windows bazelisk
del %~dp0example\.bazelversion
copy %~dp0.bazelversion %~dp0example
:: copy clang-tidy and clang-format
copy "%USERPROFILE%\Downloads\clang+llvm-18.1.6-x86_64-pc-windows-msvc.tar\clang+llvm-18.1.6-x86_64-pc-windows-msvc\bin\clang-tidy.exe" %~dp0example\tools\lint\
copy "%USERPROFILE%\Downloads\clang+llvm-18.1.6-x86_64-pc-windows-msvc.tar\clang+llvm-18.1.6-x86_64-pc-windows-msvc\bin\clang-format.exe" %~dp0example\tools\lint\
