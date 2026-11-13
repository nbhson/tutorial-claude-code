# /debug xong: cứ gọi mcp__db__query là treo 180s, reconnect không hết, bản cũ không bị.
/bug --anonymize
# B1 mô tả: "mcp__db__query treo sau update 2.1.210, bản 2.1.205 OK. Tái hiện: /mcp add db ... rồi query bất kỳ."
# B3 review: kiểm tra không còn DSN/pass → Send
# → có link issue, dán vào PR nội bộ để team né bản lỗi
