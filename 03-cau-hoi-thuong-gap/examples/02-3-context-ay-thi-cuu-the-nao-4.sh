# Cách 1 — /compact [focus] (nhẹ nhất, giữ session):
/context            # xem đã đầy bao nhiều %
/compact            # tóm tắt toàn bộ, giữ mạch
/compact auth-flow  # chỉ giữ focus auth, vứt phần còn lại

# Cách 2 — /clear + paste plan: bảo Claude xuất plan ra file trước, rồi:
/clear
# Paste lại plan + chỉ files cần cho phase tiếp theo
# Cách 3 — Rewind: double-Esc → chọn checkpoint trước khi context loãng
# Cách 4 — Phòng bệnh: "Dùng subagent Explore quét auth, trả 10 dòng tóm tắt"
