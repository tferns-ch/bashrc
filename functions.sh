#!/bin/bash

LOG_DIR=~/bashrc/.logs
mkdir -p "$LOG_DIR"

log_cmd() {
    local timestamp=$(date +%s)
    local cmd_name=${1%% *}
    local log_file="$LOG_DIR/${cmd_name}_${timestamp}.log"
    tee -a "$log_file"
}

create_command() {
    local name=$1
    local help_text=$2
    local impl=$3

    declare -g "BASHRC_HELP_${name}=${name}: ${help_text}"

    eval "
        $name() {
            (
                $impl \"\$@\"
            ) 2>&1 | log_cmd \"$name\"
        }
    "
}

for func_file in ~/bashrc/functions/*.sh; do
    . "$func_file"
done

create_command "java8" \
    "Switch to Java 8" \
    'sdk use java "$JAVA_8_VERSION" && echo "Switched to Java 8"'
create_command "java21" \
    "Switch to Java 21" \
    'sdk use java "$JAVA_21_VERSION" && echo "Switched to Java 21"'

bashrc_help() {
    echo "Available commands:"
    compgen -v | grep '^BASHRC_HELP_' | while read -r var; do
        echo "    ${!var}"
    done
}
