/claude-api migrate src/llm_client.py
# → phát hiện: dùng client.completion (cũ) + max_tokens thiếu
# → diff: chuyển client.messages.create(model="claude-sonnet-5-5", max_tokens=1024, system=..., messages=[...])
# → duyệt diff → chạy pytest → xong
