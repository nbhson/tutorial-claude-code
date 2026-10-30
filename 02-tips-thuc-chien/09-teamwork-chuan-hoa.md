# Tips 09 — Teamwork: chuẩn hóa Claude Code cho cả team

> **Bài này cho ai:** dev và tech lead muốn cả team dùng Claude Code giống nhau — commit gì, phân phối plugin thế nào, chạy PR flow + review + đo lường ra sao.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)); nên đọc [Tips 06 — Hooks](./06-hooks-recipes.md) trước vì 3 hook mẫu ở mục 3 lấy đúng recipes của Tips 06.
> **Đọc xong bạn làm được:**
> - Chọn đúng cái gì commit vào git chung, cái gì để riêng từng máy, kèm `settings.json` + `CLAUDE.md` + `.mcp.json` copy-paste ngay.
> - Đóng gói skills/hooks/agents/MCP thành plugin, cài 1 phát là cả team + mọi repo đồng bộ.
> - Chạy đủ flow PR từ plan tới merge kèm checklist dán thẳng vào PR, và đo 4 chỉ số chống drift.
> **Thời gian:** ~35 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| `settings.json` | File cấu hình của repo (model, hooks, quyền) — commit là cả team giống nhau | Khung `hooks` ở mục 3 |
| `CLAUDE.md` | Sổ tay dự án, model đọc lại mỗi turn, giữ <200 dòng | Mục "Luật hay sai nhất (≤10 dòng)" |
| `AGENTS.md` | Nội quy chéo công cụ (Cursor, Codex...); Claude Code đọc được trực tiếp, commit chung | File nằm ở repo root |
| Hook | Lệnh tự chạy ngoài model: 0 token, không bị thuyết phục, không mệt | `hooks/branch-protect.sh` chặn push thẳng main |
| Plugin | Gói skills + hooks + agents + MCP đóng lại, cài 1 lần là dùng ở mọi repo | `/plugin` → Browse → cài `team-claude-standard` |
| Drift (lệch chuẩn) | Quy tắc vẫn nằm đó nhưng mỗi máy/mỗi người một kiểu | Máy A có hook, máy B không → push thẳng main |
| Routine | Việc giao agent chạy định kỳ rồi báo lại, khác hook chặn ngay tại chỗ | Sync docs sau merge, rà phụ thuộc hàng tuần |

---

## 1. Vì sao phải chuẩn hóa?

- Người A `CLAUDE.md` 50 dòng, người B 600 dòng → cùng prompt, output khác nhau, mỗi người khăng khăng "Claude của mình đúng".
- Hooks branch-protect chỉ máy A có → máy B push thẳng main, sập prod. Skills `/deploy` 3 bản khác nhau → deploy 3 kiểu, rollback không ai biết.

```text
Lớp 1 (repo): settings.json + .claude/ + .mcp.json + CLAUDE.md — commit, mọi người giống nhau.
Lớp 2 (phân phối): plugin (skills+hooks+agents+MCP) — cài 1 phát đồng bộ ≥2 repo.
Lớp 3 (tổ chức): cấu hình quản lý server + chính sách (policy) Team/Enterprise — khóa cái không được đổi.
```

---

## 2. Cái gì commit, cái gì không

| Commit (`settings.json`, `.claude/`, `.mcp.json`, `CLAUDE.md`) | Không commit (`settings.local.json`, `~/.claude/`, secrets) |
|---|---|
| Lệnh đã kiểm chứng, phong cách code, luật kiến trúc | Sở thích cá nhân, cấu hình ghi đè riêng từng người |
| Skills/agents/hooks chuẩn team (đã test) | API tokens (chỉ qua env vars) |
| MCP servers project-scope (URL không secret) | Tokens/headers bí mật, webhook URL có secret |
| `CLAUDE.md` gọn <200 dòng + `@import` docs | Ghi chép cá nhân, plan nháp, sổ chi phí `.claude/ledger/` (gitignore) |

> Team dùng chung Cursor/Codex thì để nội quy chung ở `AGENTS.md` (commit), `CLAUDE.md` chỉ giữ notes riêng của Claude ([bài 03 — CLAUDE.md & AGENTS.md](../01-huong-dan-su-dung/03-claude-md-memory-rules.md)).

**Quy tắc branch cho config:** config chuẩn team đổi → PR riêng, 1 reviewer, ghi rõ version Claude đã test. Không sửa `settings.json` trực tiếp trên main khi đang hotfix. Secrets xoay → revoke + chuyển env, không commit "fix token" lên git.

---

## 3. Ví dụ: settings + CLAUDE.md + MCP chuẩn team

### Ví dụ 1 — `settings.json` team (copy-paste khung)

```json
{
  "model": "sonnet",
  "effort": "medium",
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/lint-on-write.sh" }] }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/branch-protect.sh" }] }
    ],
    "Stop": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/cost-cap.sh" }] }
    ]
  }
}
```

### Ví dụ 2 — `CLAUDE.md` team (khung <100 dòng)

```markdown
# Project X — 1 đoạn mô tả + stack

## Route model
- Explore → haiku. Implement → sonnet. Security/arch → opus + reviewer fresh.

## Luật hay sai nhất (≤10 dòng)
- Test: `pnpm --filter <pkg> test` xanh mới done. Lint: `pnpm lint` 0 error.
- NEVER push main, NEVER force-push, NEVER sửa generated/schema khi chưa duyệt.

## Workflow
- >1 file → plan mode + plan.md trước. Mỗi phase verify + gate.
- PR nontrivial → reviewer fresh + /verify (user-visible).

## Đọc thêm
- Kiến trúc: @docs/architecture.md — DB: @docs/db-conventions.md — Hooks: hooks/README.md
```

### Ví dụ 3 — `.mcp.json` project-scope (không secret)

```json
{
  "mcpServers": {
    "repo-docs": { "url": "https://docs.internal/mcp", "transport": "http" },
    "ci": { "url": "https://ci.internal/mcp", "transport": "http" }
  }
}
```

```bash
# Secrets qua env, không commit:
export CI_MCP_TOKEN="..."       # mỗi người tự export
export SLACK_WEBHOOK_URL="..."  # cost-cap hook đọc env này
```

---

## 4. Gói phân phối: plugin hay hơn copy-paste dotfiles

Bộ setup chuẩn (skills + hooks + agents + MCP) dùng ≥2 repo → đóng **plugin** (trình quản lý `/plugin`). Đồng nghiệp cài 1 phát là đồng bộ.

```bash
/plugin
# → Browse hiện trước các components (skills/hooks/agents/MCP) để soát rồi mới cài
# → cài plugin team (vd team-claude-standard), mọi repo hưởng cùng bộ
```

```text
team-claude-standard/
  commands/ (plan, review, ship, deploy, issues)
  agents/ (explorer, planner, reviewer, tester — mô tả gọn)
  skills/ (5 skills ở Tips 07) — hooks/ (3 hooks + README version)
  .mcp.json (servers không secret) — README.md (cài sao, version Claude nào, ai duyệt)
```

Quy trình phát hành: PR vào repo plugin (kèm bằng chứng test 3 ca lint, 4 ca push) → maintainer review + version + changelog → cả team `/plugin update` → `/doctor` xác nhận → ghi team log.

Tổ chức lớn: managed settings + policy Team/Enterprise — khóa `bypass`, khóa push main, pin model cho CI.

---

## 5. Quy trình PR với Claude (đề xuất)

```bash
# 1. Plan (Session A): /plan → duyệt plan.md, commit plan
# 2. Implement (Session B fresh, từng phase): "Đọc plan.md, chỉ làm Phase 1, verify rồi dừng"
# 3. Tự đọc diff trước khi nhờ review: /diff; git diff --stat
#    → tự bắt lỗi hiển nhiên (debug log quên xóa, file lọt ngoài scope)
# 4. Reviewer fresh: prompt reviewer ở Tips 04 (SEVERITY + verdict). Fix HIGH.
# 5. Verify chạy thật (nếu user-visible): /verify
# 6. Ship thành PR: /ship
# 7. CI: review job hẹp
claude -p "Review diff trong PR này, scope src/payments/**. Finding = bug/security/test-gap. Verdict PASS/NEEDS-FIX." --permission-mode dontAsk
```

---

## 6. Walkthrough: từ feature tới merge trong team 3 người

**Nhân sự:** An (senior, plan + review), Bình (dev, implement), Chi (QA, verify). Feature refund 3 phases.

- **Ngày 1 — An plan (30 phút):** `/plan` → plan.md 3 phases + gate → commit + draft PR "plan: refund". Bình + Chi góp ý 1 vòng qua lại (không họp). An chốt plan v2.
- **Ngày 2 — Bình implement (3 sessions fresh):** `git worktree add ../repo-worktrees/refund -b feat/refund` → Phase 1/2a/2b+3, mỗi phase tester haiku chạy focused test, xanh mới push.
- **Ngày 3 — Review + merge:** Bình `/diff` tự đọc → reviewer opus fresh → 1 HIGH (thiếu idempotency) → fix → re-review PASS. Chi `/verify` (refund 2 lần cùng key, chỉ trừ 1 lần) → dán demo log. An review người thật 10 phút → squash merge → remove worktree. Routine sync docs tự chạy.

Tổng: 0 cuộc họp trực tiếp, ~5 lượt góp ý, không lần nào phải `/rewind` vì gate mỗi phase bắt sớm.

---

## 7. Review code theo chuẩn của team

- **Mọi PR nontrivial đều qua reviewer fresh-context trước khi người thật vào.** Người viết không tự duyệt bài của mình ([Tips 04](./04-verification-done-that.md), [Tips 05](./05-parallel-agents.md)).
- **PR lớn/rủi ro cao → `/ultrareview`** (fleet bug-hunting agents trên cloud — **public preview từ w17/2026**; bản CI: `claude ultrareview`, w18): 3+ agent soi correctness/security/hiệu năng, lead tổng hợp. Chậm, đắt — chỉ dùng cho PR lớn.

```bash
/code-review      # review chuẩn 1 agent, chạy background subagent (w30/2026)
/ultrareview      # multi-agent nặng (public preview) — chỉ PR lớn/rủi ro cao
```

Kết quả review ghi thẳng vào checklist PR mục 8 (HIGH = 0 hoặc đã fix + re-review). Chỉnh chuẩn (calibration): cho reviewer chấm 3 diff lịch sử repo để biết mức độ khó tính có ổn không (false-positive ~15% chấp nhận được cho review tự làm; người thật lọc nốt).

---

## 8. Bảng vai trò + checklist PR

| Vai | Làm gì với Claude | Không làm gì |
|---|---|---|
| Planner (senior) | `/plan`, duyệt plan.md, chỉnh chuẩn reviewer | Không implement hộ (mất tách context) |
| Implementer | Session fresh từng phase, tester haiku | Không tự review bài mình |
| Reviewer (agent + người) | Fresh subagent soi + người thật chốt HIGH | Không coi style là HIGH |
| QA/Verifier | `/verify` chạy thật, test chập chờn ghi `FLAKY` | Không đoán nguyên nhân flaky bừa |
| Maintainer config | Duyệt plugin/settings/hooks PR, pin version | Không sửa config thẳng main |

Checklist PR (copy vào mẫu PR): plan.md đã duyệt (nếu >1 file)? Test xanh (log đính kèm)? `git diff --stat` chỉ chạm scope cho phép? Reviewer fresh HIGH = 0 (hoặc đã fix + re-review)? User-visible → `/verify` pass (demo log)? Changelog + docs sync? Worktree đã remove sau merge?

---

## 9. Chống lệch chuẩn (drift) & đo lường

**Chuẩn sống, không thành giấy:**

- Routine sync docs sau merge: nhắc sync `docs/` + `CLAUDE.md` nếu API/luật đổi (định kỳ, không phải hook chặn ngay).
- Rà phụ thuộc hàng tuần: agent đọc lockfile + lỗ hổng, mở PR nâng version (người duyệt).
- Phân tích CI fail qua đêm: job `claude -p` đọc log CI fail, tóm tắt 5 gạch đầu dòng + nghi ngờ root cause (người thật quyết cách sửa).

**Đo lường:** `/insights` (nếu có — báo cáo thói quen coding) và `/stats` (nếu có — usage cá nhân). Bảng phân tích (Team/Enterprise): bill theo người/repo, tỉ lệ retry, tỉ lệ review đạt. Hàng tháng: `/doctor` toàn team + prune skills/MCP + hook >5s thì tối ưu; ghi `docs/team-log.md`.

| Chỉ số | Đo bằng gì | Mục tiêu |
|---|---|---|
| Tỉ lệ retry (số turn mới xong) | Bản ghi hội thoại + comment PR | Giảm 30%/quý |
| HIGH lọt production | Sự cố (incident) | = 0 |
| Bill/người/tuần | `/usage` + bảng phân tích | Giảm 20% sau chuẩn hóa |
| Thời gian review (mở PR → merge) | Mở PR → merge | <24h (nhờ reviewer agent trước) |

---

## 10. Bẫy thường gặp + cách sửa

| Bẫy | Triệu chứng | Cách sửa |
|---|---|---|
| Config mỗi máy 1 kiểu | Cùng repo, 2 máy ra 2 kết quả | Commit settings/.claude/.mcp.json + plugin |
| Commit secret lên git | Token trong history là lộ | Env vars + prompt hook check secret ([Tips 06](./06-hooks-recipes.md)) |
| Tự review bài mình | HIGH lọt | Bắt buộc reviewer fresh + người thứ 2 cho PR tiền/auth |
| PR 50 files không ai review nổi | Review qua loa, lọt bug | Chia phase/PR nhỏ, `/ultrareview` cho PR lớn |
| Plugin không version | Update gãy cả team | Version + changelog + `/doctor` sau update |
| Pin model cứng nhắc | Task nhỏ cũng opus, bill vọt | Route theo việc ([Tips 08](./08-tiet-kiem-cost-token.md)), pin chỉ CI |
| Không đo lường | Chuẩn hóa 3 tháng không biết hiệu quả | 4 chỉ số mục 9, review hàng tháng |

---

## 11. Bài tập

- **Bài 1 (20 phút):** `git ls-files | grep -E 'settings|CLAUDE|mcp|hooks'` — cái gì chuẩn team mà chưa commit? So `settings.local.json` vs `settings.json`, nâng cái đáng lên chuẩn team; xoay secret nếu có trong history.
- **Bài 2 (30 phút):** đóng 1 plugin mini (2 skills + 1 hook lint) theo khung mục 4, nhờ đồng nghiệp cài qua `/plugin` Browse; cả 2 chạy `/doctor` so lệch, gộp thành 1 README cài đặt.
- **Bài 3 (45 phút):** lấy 1 task nhỏ, chạy đủ flow mục 5; điền checklist PR mục 8 + mẫu kết luận review mục 7; đo thời gian review người thật (mục tiêu <15 phút).

> Đạt: sau 1 quý, 100% PR nontrivial qua reviewer fresh + 0 sự cố HIGH + bill/người giảm mà tốc độ merge tăng.

---

## 12. Tham khảo chéo

- [../01-huong-dan-su-dung/commands/knowledge-system/plugin/README.md](../01-huong-dan-su-dung/commands/knowledge-system/plugin/README.md) — trình quản lý plugin · [../01-huong-dan-su-dung/commands/code-repo/code-review/README.md](../01-huong-dan-su-dung/commands/code-repo/code-review/README.md) — review chuẩn · [../01-huong-dan-su-dung/commands/code-repo/ultrareview/README.md](../01-huong-dan-su-dung/commands/code-repo/ultrareview/README.md) — multi-agent PR lớn
- [../01-huong-dan-su-dung/commands/code-repo/diff/README.md](../01-huong-dan-su-dung/commands/code-repo/diff/README.md) — tự đọc diff · [../01-huong-dan-su-dung/commands/code-repo/verify/README.md](../01-huong-dan-su-dung/commands/code-repo/verify/README.md) — QA chạy thật · [../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md](../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md) — rà soát team hàng tháng
- [Tips 04](./04-verification-done-that.md) — reviewer + các mức verify · [Tips 05](./05-parallel-agents.md) — worktrees/batch · [Tips 06](./06-hooks-recipes.md) — commit hooks · [Tips 07](./07-thiet-ke-skills.md) — 5 skills + plugin · [Tips 08](./08-tiet-kiem-cost-token.md) — bill team + route model

> Mẹo 1 dòng: _chuẩn hóa = commit cái đáng commit, plugin cái dùng chung, review mọi PR nontrivial bằng reviewer fresh trước người thật._
