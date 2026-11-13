# Workflow chuẩn tầng 3:
# 1. Dev xong → tầng 0 sạch, tầng 1 /security-review sạch (fix hết critical/high).
# 2. Mở PR → Code Review (agent pre-review + assign người).
# 3. Người review business logic + approve. Không approve khi còn findings
#    critical/high chưa fix hoặc chưa ghi risk-acceptance.
# 4. Merge → tầng 4 CI chạy cửa cuối (mục 6).
# Không thành bottleneck: PR < 400 dòng diff; PR kèm output /security-review;
# findings máy fix hết mới gọi người.
