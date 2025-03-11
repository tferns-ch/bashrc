# bashrc

Personal shell configuration scripts for my laptop, mainly used for Companies House development. Makes setting up new machines quick and painless.

*Note: `variables.sh` contains obfuscated sensitive info - update when setting up new machine.*

Add to `~/.bashrc`:
```bash
dependencies=(
    "$HOME/bashrc/variables.sh"
    "$HOME/bashrc/environment.sh"
)

for file in "${dependencies[@]}"; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done

for file in ~/bashrc/*.sh; do
    [[ " ${dependencies[@]} " =~ " ${file} " ]] && continue
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
```
