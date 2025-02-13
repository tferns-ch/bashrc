#!/bin/bash

update_all_repos() {
    local repo_dirs=(
        "$DEV_DIRECTORY"
        "$DOCKER_CHS_REPOS"
    )

    for dir in "${repo_dirs[@]}"; do
        echo "Scanning directory: $dir"
        for repo in "$dir"/*; do
            if [ -d "$repo/.git" ]; then
                echo "Updating repo: $repo"
                (
                    cd "$repo" || continue

                    git checkout -b temp-cleanup-branch

                    if git rev-parse --verify origin/main >/dev/null 2>&1; then
                        main_branch="main"
                    elif git rev-parse --verify origin/master >/dev/null 2>&1; then
                        main_branch="master"
                    else
                        echo "Unable to determine main branch for $repo"
                        continue
                    fi

                    git branch -D "$main_branch" 2>/dev/null

                    git fetch origin

                    git checkout -b "$main_branch" "origin/$main_branch"

                    git branch -D temp-cleanup-branch

                    echo "Repo $repo updated successfully"
                ) || echo "Failed to update repo: $repo"
            fi
        done
    done
}

seed_mongo() {
  container_id=$(docker ps -qf 'name=mongo')
  find "$DOCKER_CHS_REPOS" -type f -name '*.mongo.js' | while read -r file; do
    docker cp "$file" "$container_id":/tmp/$(basename "$file")
    docker exec "$container_id" mongo --quiet /tmp/$(basename "$file")
  done
}

seed_mongo_file() {
    if [ $# -eq 0 ]; then
        echo "Usage: seed_mongo_file <filename_without_extension>"
        return 1
    fi

    local file="$MONGO_SCRIPTS_DIR/$1.mongo.js"

    if [ ! -f "$file" ]; then
        echo "Error: File $file not found."
        return 1
    fi

    container_id=$(docker ps -qf 'name=mongo')

    if [ -z "$container_id" ]; then
        echo "Error: MongoDB container not found."
        return 1
    fi

    docker cp "$file" "$container_id":/tmp/$(basename "$file")
    docker exec "$container_id" mongo --quiet /tmp/$(basename "$file")

    echo "Seeded $file successfully."
}

ls_seed_mongo() {
    if [ ! -d "$MONGO_SCRIPTS_DIR" ]; then
        echo "Error: Directory $MONGO_SCRIPTS_DIR not found."
        return 1
    fi

    echo "Available MongoDB seed files:"
    ls -1 "$MONGO_SCRIPTS_DIR"/*.mongo.js | xargs -n 1 basename | sed 's/\.mongo\.js$//'
}

aws_login() {
  local skip_sso=false

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --skip-sso) skip_sso=true ;;
      *) echo "Unknown parameter passed: $1"; return 1 ;;
    esac
    shift
  done

  if [ "$skip_sso" = false ]; then
    aws sso login --sso-session "$CH_AWS_SSO_SESSION"
  fi

  for region in "${CH_AWS_REGIONS[@]}"; do
    for account in "${CH_AWS_ACCOUNTS[@]}"; do
      (
        aws ecr get-login-password --region "$region" --profile "$CH_AWS_PROFILE" | \
          docker login --username AWS --password-stdin "$account.dkr.ecr.$region.amazonaws.com"
      ) &
    done
  done

  wait
}

switch_java_8() {
    sdk use java "$JAVA_8_VERSION"
    echo "Switched to Java 8 ($JAVA_8_VERSION)"
}

switch_java_21() {
    sdk use java "$JAVA_21_VERSION"
    echo "Switched to Java 21 ($JAVA_21_VERSION)"
}

del_branches() {
    git branch | grep -v "\*" | grep -v "master" | grep -v "main" | xargs -n 1 git branch -D
}

bashrc_help() {
    echo "Available functions:"
    echo "-------------------"
    echo "seed_mongo: Seeds MongoDB containers with .mongo.js files from $DOCKER_CHS_REPOS"
    echo "seed_mongo_file <filename>: Seeds a specific .mongo.js file from $MONGO_SCRIPTS_DIR"
    echo "ls_seed_mongo: Lists available MongoDB seed files in $MONGO_SCRIPTS_DIR"
    echo "aws_login [--skip-sso]: Logs into AWS and ECR. Use --skip-sso to skip SSO login"
    echo "switch_java_8: Switches to Java 8 ($JAVA_8_VERSION) using SDKMAN"
    echo "switch_java_21: Switches to Java 21 ($JAVA_21_VERSION) using SDKMAN"
    echo "del_branches: Deletes all local git branches except master and main"
    echo "update_all_repos: Updates all Git repositories"
    echo "bashrc_help: Displays this help message"
}
