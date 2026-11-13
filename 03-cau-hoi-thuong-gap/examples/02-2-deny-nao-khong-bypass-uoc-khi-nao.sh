# Guard mẫu sống qua bypass:
#!/bin/bash
input=$(cat)
echo "$input" | grep -qE 'rm -rf|sudo ' && echo '{"decision":"block","reason":"critical blocked even with bypass"}' && exit 0
echo '{"decision":"approve"}'
