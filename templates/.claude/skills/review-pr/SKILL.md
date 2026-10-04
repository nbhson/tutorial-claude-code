---
name: review-pr
description: Review PR/branch theo checklist correctness-security-tests. Dùng khi user nói review PR, review branch, /review-pr.
disable-model-invocation: false
allowed-tools: Bash, Read, Grep, Glob
---

# Review PR — nhận $ARGUMENTS (PR number hoặc branch)

> $ARGUMENTS là số PR (vd `123`) hoặc range branch (vd `main...HEAD`).
> Ví dụ gọi: `/review-pr 123` hoặc `/review-pr main...HEAD`.
> File này tiếng Việt để team dễ đọc; output review giữ tiếng Việt.

## Inputs (xác định $ARGUMENTS là gì)

1. Nếu `$ARGUMENTS` là số (vd `123`) thì lấy diff bằng GitHub CLI:
   ```bash
   # Lấy diff của PR số 123 (chạy thật, không đoán)
   gh pr diff 123
   gh pr view 123 --json title,body,baseRefName,headRefName
   ```
2. Nếu `$ARGUMENTS` là branch/range (vd `main...HEAD`) thì:
   ```bash
   # So sánh với nhánh base (chạy thật)
   git fetch origin --prune
   git diff main...HEAD --stat
   git diff main...HEAD
   ```
3. Nếu `$ARGUMENTS` rỗng → hỏi user: "Cho mình PR number hoặc branch range", rồi dừng.

## Steps (làm đúng thứ tự)

### Bước 1 — Lấy context (chỉ đọc, không sửa)

- Đọc title + body PR để biết mục tiêu thay đổi là gì.
- Lấy danh sách file đổi: `git diff --name-only` hoặc `gh pr diff --name-only`.
- Đọc từng file đổi bằng Read (không `cat` bằng Bash).

### Bước 2 — Checklist correctness (đúng logic?)

- [ ] Logic có khớp mô tả PR không? Có branch nào bị bỏ sót (null, empty, error path)?
- [ ] API contract có đổi mà không update caller/docs/test không?
- [ ] Migration có tương thích dữ liệu cũ không (nullable, default, backfill)?
- [ ] Có code chết, TODO không ticket, hoặc `console.log` debug quên xóa?

### Bước 3 — Checklist security (bảo mật)

- [ ] Input từ user có validate ở boundary (handler/controller) không?
- [ ] AuthZ: handler mới có check quyền (owner/role) trước khi đọc/ghi không?
- [ ] Có hardcode secret, token, connection string không?
- [ ] SQL/query có dùng parameter binding (không nối chuỗi)?
- [ ] Log có vô tình in PII/secret không?

### Bước 4 — Checklist tests (kiểm chứng)

- [ ] PR có test cho handler/logic mới không?
- [ ] Chạy focused test liên quan:
  ```bash
  # Chạy test focused cho package vừa đổi (thay tên package thật)
  pnpm --filter @acme/api test
  ```
- [ ] Nếu không chạy được test (thiếu env), ghi rõ `NOT-RUN: <lý do>`.

## Output format (bắt buộc theo mẫu này)

```markdown
## Kết quả review PR <số/range>

- Tóm tắt: <1-2 câu PR này làm gì>
- Files đã đọc: <n> files

### Findings
- [BLOCKER] `path/to/file.ts:42` — mô tả — gợi ý fix
- [SHOULD-FIX] `path/to/file.ts:88` — mô tả — gợi ý fix
- [NIT] `path/to/file.ts:10` — mô tả

### Checklist
- correctness: PASS/FAIL — <ghi chú 1 dòng>
- security: PASS/FAIL — <ghi chú 1 dòng>
- tests: PASS/NOT-RUN — <lệnh đã chạy + kết quả>

### Verdict
- APPROVE / REQUEST-CHANGES / NEEDS-TESTS
```

## Constraints

- NEVER approve khi còn BLOCKER hoặc tests chưa chạy mà không ghi NOT-RUN.
- NEVER sửa code giùm trong skill này — chỉ liệt kê findings.
- ALWAYS trích `file:line` cụ thể, không nói chung chung kiểu "code chưa tốt".
