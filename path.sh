#!/bin/bash

paths_to_add=(
    "$USER_HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    "$USER_HOME/.companies_house_config/bin"
)

for new_path in "${paths_to_add[@]}"; do
    if [[ ":$PATH:" != *":$new_path:"* ]]; then
        PATH="$PATH:$new_path"
    fi
done

export PATH
