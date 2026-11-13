/simplify api/auth.py:login
# Trước: if user: → if pw: → if not locked: → try: ... (sâu 5)
# Sau: 4 early-return (không user → raise; sai pw → raise...) + thân chính 10 dòng phẳng
# → test auth xanh → commit
