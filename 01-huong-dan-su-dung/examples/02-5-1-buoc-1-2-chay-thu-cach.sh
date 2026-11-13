claude plugin test <plugin-name>      # chạy thử cách ly: Mod nào load? hooks? permissions?
claude plugin validate <plugin-name> > /tmp/before.txt
# → đọc từng dòng: Mod nào? xin quyền gì? calls: nào? Có gì KHÔNG liên quan
#   chức năng quảng cáo? (vd: plugin format mà xin network?)
claude plugin details   # hỗ trợ: chi tiết plugin, gồm ước tính token cost
claude plugin eval      # hỗ trợ: đánh giá plugin trước khi tin — cần ≥2.1.269
