#!/usr/bin/bash
# This is a wrapper for clang-tidy which allows it to be run on a collection of files
# Usage: clang-tidy-target.bash <clang-tidy-path> <file1> <file2> ... -- <compiler-args>
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
fi

# Initialize arrays
file_args=()
clang_tidy_args=()
compiler_args=()
double_dash_found=0
add_matching_header=0

# read args into three arrays:
# 1. args that are not flags
# 2. args that are flags
# 3. any args after '--'

# Loop over all arguments
for arg in "$@"; do
    if [[ $double_dash_found -eq 1 ]]; then
        compiler_args+=("$arg")
    elif [[ $arg == "--" ]]; then
        double_dash_found=1
    elif [[ $arg == "--wrapper_add_matching_header" ]]; then
        add_matching_header=1
    elif [[ $arg == -* ]]; then
        clang_tidy_args+=("$arg")
    else
        file_args+=("$arg")
    fi
done

# Print arrays for testing
if  [[ -n $CLANG_TIDY__VERBOSE ]]; then
    echo "cwd: " `pwd`
    echo "File args: ${file_args[@]}"
    echo "Clang tidy args: ${clang_tidy_args[@]}"
    echo "Args after '--': ${compiler_args[@]}"
fi

# Iterate over file args and run clang-tidy on each file in file_args
max_code=0
for file in "${file_args[@]}"; do
    # if add_matching_header is set, form a regex that matches the source filename
    # without extension
    extra_arg=""
    if [[ -n $add_matching_header ]]; then
        filename=$(basename -- "$file")
        filename_no_ext="${filename%.*}"
        extra_arg=" -header-filter='.*/${filename_no_ext}\..*'"
    fi
    # Run clang-tidy on each file. Continue on error; we want to check all files.
    temp_file=$(mktemp)
    # include stderr in output file; it contains some of the diagnostics
    command="$clang_tidy ${clang_tidy_args[@]}${extra_arg} $file -- ${compiler_args[@]} $file > $temp_file 2>&1"
    if [[ -n $CLANG_TIDY__VERBOSE ]]; then
        echo $command
    fi
    eval $command
    exit_status=$?
    cat $temp_file >> $CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE
    # distinguish between compile (fatal) errors and warnings-as-errors errors
    fatal_error=0
    if [ $exit_status -ne 0 ] && [ -s $temp_file ]; then
        while read line
        do
            if [[ $line == *"clang-diagnostic-error"* ]]; then
                fatal_error=1
                break
            fi
        done < "$temp_file"
    fi
    if [ $fatal_error -ne 0 ]; then
        cat $temp_file
        rm $temp_file
        if [[ -n $CLANG_TIDY__VERBOSE ]]; then
            echo "found clang-diagnostic-error (regarding as fatal)"
            echo "exit $exit_status"
        fi
        exit $exit_status
    fi
    rm $temp_file
    # Store the 'worst' exit code.
    if [ $exit_status -gt $max_code ]; then
        max_code=$exit_status
    fi
done

# if CLANG_TIDY__EXIT_CODE_FILE is set, write the max exit code to that file and return success
if [[ -n $CLANG_TIDY__EXIT_CODE_OUTPUT_FILE ]]; then
    if [[ -n $CLANG_TIDY__VERBOSE ]]; then  
        echo "echo $max_code > $CLANG_TIDY__EXIT_CODE_OUTPUT_FILE"
        echo "exit 0"
    fi
    echo $max_code > $CLANG_TIDY__EXIT_CODE_OUTPUT_FILE
    exit 0
fi

if [[ -n $CLANG_TIDY__VERBOSE ]]; then
    echo exit $max_code
fi
exit $max_code
