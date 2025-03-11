create_command "mongo_seed" "Seed MongoDB with all .mongo.js files" _mongo_seed_impl
_mongo_seed_impl() {
    echo "Seeding MongoDB..."
    container_id=$(docker ps -qf 'name=mongo')
    [[ -z "$container_id" ]] && { echo "Error: MongoDB container not found"; return 1; }

    find "$DOCKER_CHS_REPOS" -type f -name '*.mongo.js' | while read -r file; do
        echo "Processing $file..."
        docker cp "$file" "$container_id:/tmp/$(basename "$file")"
        docker exec "$container_id" mongo --quiet "/tmp/$(basename "$file")"
    done
}

create_command "mongo_seed_file" "Seed MongoDB with a specific .mongo.js file" _mongo_seed_file_impl "$@"
_mongo_seed_file_impl() {
    [[ $# -eq 0 ]] && { echo "Usage: mongo_seed_file <filename_without_extension>"; return 1; }
    local file="$MONGO_SCRIPTS_DIR/$1.mongo.js"
    [[ ! -f "$file" ]] && { echo "Error: File $file not found"; return 1; }

    container_id=$(docker ps -qf 'name=mongo')
    [[ -z "$container_id" ]] && { echo "Error: MongoDB container not found"; return 1; }

    echo "Seeding $file..."
    docker cp "$file" "$container_id:/tmp/$(basename "$file")"
    docker exec "$container_id" mongo --quiet "/tmp/$(basename "$file")"
    echo "Seeded $file successfully"
}

create_command "mongo_list" "List available MongoDB seed files" _mongo_list_impl
_mongo_list_impl() {
    [[ ! -d "$MONGO_SCRIPTS_DIR" ]] && { echo "Error: $MONGO_SCRIPTS_DIR not found"; return 1; }
    echo "Available MongoDB seed files:"
    ls -1 "$MONGO_SCRIPTS_DIR"/*.mongo.js | xargs -n 1 basename | sed 's/\.mongo\.js$//'
}
