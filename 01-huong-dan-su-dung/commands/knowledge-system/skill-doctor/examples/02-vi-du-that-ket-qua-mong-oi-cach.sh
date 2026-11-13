/skill-doctor --cost
# → "run-e2e 4.2k (SKILL.md 180 dòng + 6 ví dụ thừa)
#    pdf-read 3.8k (nhúng cả spec 90 dòng vào SKILL)
#    10 skills còn lại <800 mỗi cái"

# Chữa:
# 1. pdf-read: chuyển spec sang file riêng, SKILL chỉ giữ cách gọi
# 2. run-e2e: cắt 6 ví dụ còn 2
