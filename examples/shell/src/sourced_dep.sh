#!/bin/bash

sourced_message() {
    [ -z $1 ] && echo "missing value"
    printf 'hello %s\n' "$1"
}
