# Trong session:
/mcp                        # list + trạng thái + tools count
/mcp reconnect github       # nối lại 1 server
/mcp disable playwright     # tắt server nặng khi không cần
/mcp enable playwright      # bật lại

# CLI (ngoài session):
claude mcp list
claude mcp get github
claude mcp login linear     # đăng nhập OAuth server từ terminal (≥ Week 26/2026)
claude mcp logout linear
claude mcp remove old-server
claude mcp reset-project-choices   # xóa approvals project cũ khi đổi policy
