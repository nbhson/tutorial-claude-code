/hooks
# → list hooks: matcher (case-sensitive!), event (Pre/Post/Stop/Start), command path
# → kiểm tra: sai event? overlap updatedInput? script có +x không?

/mcp
# → servers nào bật? tools nào visible? server nào fail (đỏ)?
# → quá ~10 tools visible là accuracy giảm — prune server không dùng

/permissions
# → rules cho phép/chặn gì? Có rule nào chặn lệnh bạn cần?
# → đừng --dangerously-skip-permissions trên máy dev (chỉ CI sandbox)
