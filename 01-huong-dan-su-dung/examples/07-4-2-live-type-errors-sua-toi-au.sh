# Sau mỗi change, hỏi thay vì chạy full tsc:
"get live type errors file apps/api/auth.ts (LSP diagnostics), chỉ lỗi mới do change vừa rồi."

# Gate trong hook Stop (khung — xem Tips 06): gọi tsc --noEmit cho file đổi
# (nhanh) thay vì full suite 4 phút mỗi turn-end:
TEST_SCOPE=auth ./hooks/test-gate.sh
