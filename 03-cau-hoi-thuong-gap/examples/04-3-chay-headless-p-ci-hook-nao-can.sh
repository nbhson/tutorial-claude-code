# ✅ Hook headless-safe: đọc stdin, in JSON, thoát
#!/bin/bash
input=$(cat)
echo "$input" | grep -q 'rm -rf' && echo '{"decision":"block","reason":"deny rm-rf"}' && exit 0
echo '{"decision":"approve"}'

# ❌ TRONG HOOK: read -p "chắc không?"; vim file; open browser...
