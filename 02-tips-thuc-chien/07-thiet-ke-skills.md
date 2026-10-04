# Tips 07 — Thiết Kế Skills Đáng Tiền (Chuẩn SOP, Không Phải Ghi Chép)

## 1. Quy tắc 30 giây: skill tốt = SOP người mới đọc là làm được

Mỗi skill trả lời: **khi nào dùng + steps nào + check gì + output mẫu nào**. Thiếu 1 trong 4 → skill yếu.

## 2. Đặt tên + description (quyết định 50% skill có được dùng)

- Tên: động từ + đối tượng (`deploy`, `add-table`, `review-pr`). Thư mục = command (`/deploy`).
- `description`: câu đầu = **use case chính** ("Deploy staging/prod với checklist migrate... Dùng khi user nói deploy/release/ship").
  Listing truncate ~1536 ký tự — dồn cái quan trọng lên đầu.
- Mặc định cho Claude tự trigger; chỉ `disable-model-invocation: true` khi muốn gọi tay
  (deploy/ship/release...). Nhớ: từ v2.1.196 skill này cũng không fire từ scheduled task.

## 3. Cấu trúc SKILL.md chuẩn team

```markdown
# <Tên> — 1 dòng mục đích, nhận $ARGUMENTS gì

## Khi nào dùng / không dùng
## Steps (numbered, mỗi step có lệnh + check)
## Constraints (NEVER... / ALWAYS...)
## Output mẫu (copy từ examples/output.md)
## Tham khảo (references/*.md, scripts/*.sh với ${CLAUDE_SKILL_DIR})
```

Kèm: 1 example input/output, 1 script cho bước máy làm tốt hơn (migrate dry-run, gen changelog...),
dynamic line `` !`git branch --show-current` `` nếu cần data tươi.

## 4. Bộ skills mọi team nên có (5 cái)

| Skill | Nội dung |
|---|---|
| `/plan` | Sinh implementation plan chuẩn (deps, steps, verify) — dùng trước mọi feature nontrivial |
| `/review` | Multi-layer review (correctness, security, arch drift, edge, tests) |
| `/deploy` | Checklist deploy: preconditions → migrate dry-run → deploy → smoke → rollback plan |
| `/ship` | End-to-end: merge base → test → review diff → bump version → changelog → commit → push → PR |
| `/issues` | Biến ý thô thành issue/ticket chuẩn (repro, scope, acceptance criteria) |

## 5. Chống skill-rot (skills đống thành rác)

- Skill không ai gọi 1 tháng → xóa hoặc merge. Skill load sai lúc → sửa description/`when_to_use` cho hẹp lại.
- `skillOverrides` trong settings để tắt auto cho skill của người khác mà bạn không muốn.
- Review định kỳ cùng `/doctor` (nó flag unused skills vs context cost).
- Skills theo Agent Skills standard → test portability: cùng file chạy được ở Codex/Gemini/Copilot —
  tránh syntax Claude-only nếu team multi-tool.
