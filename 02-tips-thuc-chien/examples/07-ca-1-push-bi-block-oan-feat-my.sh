# Triệu chứng: mọi git push đều "BLOCKED", kể cả branch thường
/hooks
echo '{"tool_input":{"command":"git push origin feat/my-main-fix"}}' | ./hooks/branch-protect.sh; echo "exit=$?"
# → exit=2: hook substring "main" bừa. Fix: thay bằng regex intent ở Tips 06 mục 2b.
# Test lại 4 ca: push force + HEAD:main (phải blocked) + feat/my-main-fix (phải pass).
