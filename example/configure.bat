:: run this on Windows to set up example for use
@echo Configuring example for Windows
:: aspect-cli doesn't support windows, so disable it
del %~dp0.bazeliskrc
:: ../.bazelversion syntax not supported by windows bazelisk
del %~dp0.bazelversion
copy %~dp0\..\.bazelversion %~dp0
