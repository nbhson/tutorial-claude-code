# Tên env chính xác xem README plugin — đừng đoán:
SECURITY_GUIDANCE_DISABLE_PER_EDIT=1   # tắt layer 1 (pattern match)
SECURITY_GUIDANCE_DISABLE_END_TURN=1   # tắt layer 2 (background review)
SECURITY_GUIDANCE_DISABLE_PRE_PUSH=1   # tắt layer 3 (commit/push review)
SECURITY_GUIDANCE_DISABLE_ALL=1        # master: tắt cả plugin 1 session
# ⚠ Tắt là NỢ security: ghi lý do + bật lại trong cùng ngày. Tắt master chỉ
# khi plugin BREAK workflow (bug) — kêu nhiều mà đúng thì sửa code, không tắt.
# CI (tầng 4) KHÔNG tắt theo — kill switch chỉ ảnh hưởng local session.
