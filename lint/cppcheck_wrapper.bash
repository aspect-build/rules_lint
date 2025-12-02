#!/usr/bin/env bash
# This is a wrapper for cppcheck which gives us control over error handling
# Usage: cppcheck_wrapper.bash <cppcheck-path> <args>
#
# Controls:
# - CPPCHECK__VERBOSE: If set, be verbose
# - CPPCHECK__STDOUT_STDERR_OUTPUT_FILE: If set, write stdout and stderr to this file
# - CPPCHECK__EXIT_CODE_OUTPUT_FILE: If set, write the highest exit code 
# to this file and return success

# First arg is cppcheck path
cppcheck=$1
shift

if [[ -n $CPPCHECK__STDOUT_STDERR_OUTPUT_FILE ]]; then
    # Create the file if it doesn't exist
    touch $CPPCHECK__STDOUT_STDERR_OUTPUT_FILE
    # Clear the file if it does exist
    > $CPPCHECK__STDOUT_STDERR_OUTPUT_FILE
    if [[ -n $CPPCHECK__VERBOSE ]]; then
        echo "Output > ${CPPCHECK__STDOUT_STDERR_OUTPUT_FILE}"
    fi
fi
if [[ -n $CPPCHECK__EXIT_CODE_OUTPUT_FILE ]]; then
    if [[ -n $CPPCHECK__VERBOSE ]]; then
        echo "Exit Code -> ${CPPCHECK__EXIT_CODE_OUTPUT_FILE}"
    fi
fi

if [[ -n $CPPCHECK__STDOUT_STDERR_OUTPUT_FILE ]]; then
    out_file=$CPPCHECK__STDOUT_STDERR_OUTPUT_FILE
else
    out_file=$(mktemp)
fi
# include stderr in output file; it contains some of the diagnostics
command="$cppcheck $@ $file > $out_file 2>&1"
if [[ -n $CPPCHECK__VERBOSE ]]; then
    echo "$@"
    echo "cwd: " `pwd`
    echo $command
fi
eval $command
exit_code=$?
if [ $exit_code -eq 1 ] && [ -s $out_file ]; then
    echo "Error: " $exit_code
    echo "Something went wrong when running cppcheck. Maybe license file missing?"
fi
cat $out_file

if [[ -z $CPPCHECK__STDOUT_STDERR_OUTPUT_FILE ]]; then
    rm $out_file
fi
# if CPPCHECK__EXIT_CODE_FILE is set, write the max exit code to that file and return success
if [[ -n $CPPCHECK__EXIT_CODE_OUTPUT_FILE ]]; then
    if [[ -n $CPPCHECK__VERBOSE ]]; then  
        echo "echo $exit_code > $CPPCHECK__EXIT_CODE_OUTPUT_FILE"
        echo "exit 0"
    fi
    echo $exit_code > $CPPCHECK__EXIT_CODE_OUTPUT_FILE
    exit 0
fi

if [[ -n $CPPCHECK__VERBOSE ]]; then
    echo exit $exit_code
fi

exit $exit_code
