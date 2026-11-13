# Triệu chứng: model quên chỉ thị đầu session, nói linh tinh.
/debug
# → "Context 92% — file legacy/dump.sql 40k token đang chiếm nửa."
# Nguyên nhân: bạn Read nhầm file dump vào context.

# Fix: /clear rồi làm tiếp, đừng Read file dump nữa (dùng head/Grep thay).
