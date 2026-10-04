# /pr-comments — Xử lý comment review PR: kéo về, sửa từng cái, resolve

> Loại Skill (quy trình PR) · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ sửa code theo comment; nhưng Có nhẹ nếu auto-push — luôn review diff trước khi push)

`/pr-comments` (alias `/pr_comments`) kéo toàn bộ review comments của 1 PR (GitHub/GitLab) về local, liệt kê từng thread, cùng bạn sửa từng cái rồi resolve/reply hàng loạt. Khỏi alt-tab giữa browser và terminal, khỏi sót comment. Cần MCP GitHub hoặc `gh` CLI.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/pr-comments` | _(không có)_ | Kéo comments của PR ở nhánh hiện tại |
| `/pr-comments <số>` | PR number | Kéo comments của PR chỉ định |
| `/pr-comments --unresolved` | flag | Chỉ hiện thread chưa resolve |
| `/pr-comments --address` | flag | Vừa liệt kê vừa sửa luôn (khuyên dùng) |

```bash
# Dạng 1: PR ở nhánh hiện tại
/pr-comments

# Dạng 2: PR chỉ định
/pr-comments 248

# Dạng 3: chỉ việc còn tồn (standup sáng)
/pr-comments --unresolved

# Dạng 4: chế độ xử lý luôn (khuyên dùng)
/pr-comments --address
```

```bash
# Điều kiện cần (1 trong 2, copy-paste):
gh auth login          # cách 1: GitHub CLI
/mcp add github --url https://api.githubcopilot.com/mcp   # cách 2: MCP GitHub
```

---

## Cách nó hoạt động

### Cơ chế sâu: flow address-comments ra sao?

1. **Fetch:** gọi API lấy PR info + tất cả threads (file, dòng, người comment, resolved?) — qua `gh pr view --comments` hoặc `mcp__github__*`.
2. **Nhóm:** gom theo file (VD `api/auth.py: 3 threads`), sắp xếp unresolved trước, con người (senior) trước bot.
3. **Address từng thread (vòng lặp):** hiện comment → bạn chọn `fix` (model sửa code) / `skip` (biện minh) / `reply` (hỏi lại). Fix xong chạy test file đó ngay.
4. **Resolve + push:** hết threads → `git diff` review 1 lần → push → reply/resolve threads trên remote (1 lệnh, khỏi click từng cái).
5. **Khi nào KHÔNG auto-fix?** Comment mơ hồ ("chỗ này kỳ kỳ") → model hỏi lại thay vì đoán. Conflict giữa 2 reviewers → bạn quyết, không để AI chọn phe.

---

## Ví dụ thực tế

### Kịch bản 1: Sáng nhận 8 comments — xử gọn 20 phút

```bash
/pr-comments --address
# → 8 threads gom theo 3 file.
# Thread 1 (senior: "thiếu rate-limit ở /login") → fix → model thêm middleware + test → PASS
# Thread 2 (bot: "dòng 120 quá dài") → fix → format xong
# Thread 3 ("sao không dùng X?") → reply: "X chưa support py3.12, giữ Y" → resolve
# → git diff review → push → resolve hàng loạt. 8 → 0.
```

### Kịch bản 2: Lọc việc tồn trước standup

```bash
/pr-comments --unresolved
# → chỉ 2 threads chưa xong (6 đã resolve hôm qua) → tập trung 2 cái, standup báo số cụ thể
```

### Kịch bản 3: PR số chỉ định (review hộ đồng nghiệp)

```bash
# Đồng nghiệp nhờ xem PR 248:
/pr-comments 248
# → đọc comments người khác để lại, chạy thử code, bổ sung reply — không cần checkout tay (tool tự lấy diff)
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Fix mù mọi comment (kể cả sai) | Reviewer nhầm, AI nghe theo → code tệ đi | Comment vô lý thì reply biện minh + skip, không fix |
| Auto-push chưa review diff | Đẩy code chưa nhìn | Luôn `git diff` trước push; tách fix/comment còn tranh cãi ra commit riêng |
| Token GitHub quyền rộng | Tool đọc được cả repo private khác | Token chỉ `repo, read:org`; repo nội bộ nhạy cảm thì dùng `gh` + SSH |

- **Tốn token?** Fetch 20 threads ≈ 2-4k token. Fix mỗi thread + test ≈ 2-5k. PR 10 comments ≈ 20-40k — rẻ hơn họp 1 tiếng.
- **Version:** skill `pr-comments` v2.x (cần MCP GitHub hoặc `gh`). Tên gạch dưới `/pr_comments` là alias cũ.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/pr-comments` + `/verify` | Fix xong test ngay | Mỗi thread fix → test file đó |
| `/pr-comments` + `/agents` | 2 subagent fix song song 2 file khác nhau | Mẹ gộp + review diff |
| `/pr-comments` + `/plugin` (review toolkit) | Review + address cùng chuẩn | 1 bộ plugin lo cả 2 chiều |

```bash
# Workflow PR chuẩn: /pr-comments --address (sửa) → /verify (test full) → git diff (nhìn) → push
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Không kéo được comments | Chưa login `gh` / MCP github auth expired | `gh auth login` hoặc `/mcp reconnect github` |
| Hiện PR sai | Nhánh local không link PR nào | Truyền số rõ `/pr-comments 248` |
| Fix xong test fail | Sửa 1 chỗ vỡ chỗ khác | Chạy test file đó ngay sau mỗi fix, đừng dồn cuối |
| Resolve rồi mà web vẫn hiện | Thiếu quyền resolve / nhầm GitLab API | Kiểm tra quyền; GitLab dùng thread ID khác GitHub |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../verify/README.md](../../code-repo/verify/README.md) — test sau mỗi fix
  - [../agents/README.md](../../knowledge-system/agents/README.md) — fix song song nhiều file
  - [../mcp/README.md](../../knowledge-system/mcp/README.md) — MCP GitHub backend
  - [../plugin/README.md](../../knowledge-system/plugin/README.md) — review toolkit plugin
  - [../diff/README.md](../../code-repo/diff/README.md) — review diff trước push
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../../03-claude-md-memory-rules.md)
  - [../../05-skills-custom-commands.md](../../../05-skills-custom-commands.md)
  - [../../06-subagents-agent-teams-parallel.md](../../../06-subagents-agent-teams-parallel.md)
  - [../../07-hooks-tu-dong-hoa.md](../../../07-hooks-tu-dong-hoa.md)
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../../08-mcp-ket-noi-cong-cu-ngoai.md)
  - [../../09-plugins-marketplaces.md](../../../09-plugins-marketplaces.md)

> Mẹo 1 dòng: _unresolved trước, fix từng cái test ngay, diff rồi mới push._
