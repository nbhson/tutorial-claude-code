# 1. Plan (Session A): /plan → duyệt plan.md, commit plan
# 2. Implement (Session B fresh, từng phase): "Đọc plan.md, chỉ làm Phase 1, verify rồi dừng"
# 3. Tự đọc diff trước khi nhờ review: /diff; git diff --stat
#    → tự bắt lỗi hiển nhiên (debug log quên xóa, file lọt ngoài scope)
# 4. Reviewer fresh: prompt reviewer ở Tips 04 (SEVERITY + verdict). Fix HIGH.
# 5. Verify chạy thật (nếu user-visible): /verify
# 6. Ship thành PR: /ship
# 7. CI: review job hẹp
claude -p "Review diff trong PR này, scope src/payments/**. Finding = bug/security/test-gap. Verdict PASS/NEEDS-FIX." --permission-mode dontAsk
