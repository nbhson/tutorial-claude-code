# scripts/guard-no-push-main.sh — chặn push main dù bypass
#!/bin/bash
input=$(cat)
echo "$input" | grep -q '"command": *"git push.*main' && echo '{"decision":"block","reason":"Cấm push main"}' && exit 0
echo '{"decision":"approve"}'
