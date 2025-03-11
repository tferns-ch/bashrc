create_command "update_repos" "Update all git repositories [--keep-local]" _update_repos_impl "$@"
_update_repos_impl() {
    echo "Updating repositories..."
    [[ "$1" == "--keep-local" ]] && local keep=true
    for dir in {"$DEV_DIRECTORY","$DOCKER_CHS_REPOS"}/*; do
        [[ ! -d "$dir/.git" ]] && continue
        (cd "$dir" && {
            echo -e "\nUpdating $(basename "$dir")..."
            if [[ "$keep" == true ]] && ! git diff-index --quiet HEAD --; then
                echo "Skipping: uncommitted changes"
                return
            fi
            git fetch origin
            for branch in develop main master; do
                if git rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
                    git checkout -f "$branch" && git reset --hard "origin/$branch"
                    break
                fi
            done
        })
    done
}

create_command "clean_git" "Clean git branches except master/main/develop" _clean_git_impl
_clean_git_impl() {
    git branch | grep -v -E "^\*|master|main|develop" | xargs git branch -D
}


