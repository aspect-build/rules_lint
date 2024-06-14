:: aspect-cli doesn't support windows, so disable it
del %~dp0.bazeliskrc
:: ../.bazelversion syntax not supported by windows bazelisk
del %~dp0.bazelversion
copy %~dp0\..\.bazelversion %~dp0
