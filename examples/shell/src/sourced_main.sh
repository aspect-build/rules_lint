#!/bin/bash

source src/sourced_dep.sh

message="$(sourced_message "${1:-world}")"
printf '%s\n' "$message"
