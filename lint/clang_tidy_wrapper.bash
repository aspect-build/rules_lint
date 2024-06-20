#!/usr/bin/env bash
# This is a wrapper for clang-tidy which gives us control over error handling
# Usage: clang_tidy_wrapper.bash <clang-tidy-path> <file1> <file2> ... -- <compiler-args>
#
# Controls:
# - CLANG_TIDY__VERBOSE: If set, be verbose
# - CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE: If set, write stdout and stderr to this file
# - CLANG_TIDY__EXIT_CODE_OUTPUT_FILE: If set, write the highest exit code 
# to this file and return success

# First arg is clang-tidy path
clang_tidy=$1
shift

if [[ -n $CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE ]]; then
    # Create the file if it doesn't exist
    touch $CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE
    # Clear the file if it does exist
    > $CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE
    if [[ -n $CLANG_TIDY__VERBOSE ]]; then
        echo "Output > ${CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE}"
    fi
fi
if [[ -n $CLANG_TIDY__EXIT_CODE_OUTPUT_FILE ]]; then
    if [[ -n $CLANG_TIDY__VERBOSE ]]; then
        echo "Exit Code -> ${CLANG_TIDY__EXIT_CODE_OUTPUT_FILE}"
    fi
fi

if [[ -n $CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE ]]; then
    out_file=$CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE
else
    out_file=$(mktemp)
fi
# include stderr in output file; it contains some of the diagnostics
command="$clang_tidy $@ $file > $out_file 2>&1"
if [[ -n $CLANG_TIDY__VERBOSE ]]; then
    echo "$@"
    echo "cwd: " `pwd`
    echo $command
fi
eval $command
exit_code=$?
if [[ -z $CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE ]]; then
    cat $out_file
fi
# distinguish between compile (fatal) errors and warnings-as-errors errors
fatal_error=0
if [ $exit_code -ne 0 ] && [ -s $out_file ]; then
    while read line
    do
        if [[ $line == *"clang-diagnostic-error"* ]]; then
            fatal_error=1
            break
        fi
    done < "$out_file"
fi
if [ $fatal_error -ne 0 ]; then
    cat $out_file
    rm $out_file
    if [[ -n $CLANG_TIDY__VERBOSE ]]; then
        echo "found clang-diagnostic-error (regarding as fatal)"
        echo "exit $exit_code"
    fi
    exit $exit_code
fi
if [[ -z $CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE ]]; then
    rm $out_file
fi

# if CLANG_TIDY__EXIT_CODE_FILE is set, write the max exit code to that file and return success
if [[ -n $CLANG_TIDY__EXIT_CODE_OUTPUT_FILE ]]; then
    if [[ -n $CLANG_TIDY__VERBOSE ]]; then  
        echo "echo $exit_code > $CLANG_TIDY__EXIT_CODE_OUTPUT_FILE"
        echo "exit 0"
    fi
    echo $exit_code > $CLANG_TIDY__EXIT_CODE_OUTPUT_FILE
    exit 0
fi

if [[ -n $CLANG_TIDY__VERBOSE ]]; then
    echo exit $exit_code
fi
exit $exit_code
