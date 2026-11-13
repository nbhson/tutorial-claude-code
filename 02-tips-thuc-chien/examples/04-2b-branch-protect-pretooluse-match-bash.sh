run() { echo "{\"tool_input\":{\"command\":\"$1\"}}" | ./hooks/branch-protect.sh; echo "[$1] exit=$?"; }
run "git push -f origin feat/x"; run "git push --force origin feat/x"; run "git push --force-with-lease origin feat/x"; run "git push origin HEAD:main"
# Cả 4 phải exit=2. Đối chứng (phải exit=0 — chứng minh không substring "main" bừa):
run "git push origin feat/my-main-fix"; run "git status"
