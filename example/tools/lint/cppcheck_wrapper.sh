~/.local/bin/cppcheckpremium/cppcheck \
    --check-level=exhaustive \
    --enable=warning,style,performance,portability,information \
    "$@"
