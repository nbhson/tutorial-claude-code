---
name: deploy
description: Deploy staging/prod với checklist migrate + smoke test. Dùng khi user nói deploy/release/ship.
disable-model-invocation: true
allowed-tools: Bash, Read
---

# Deploy — nhận $ARGUMENTS (vd `/deploy staging`)

Deploy giống phóng tên lửa: đếm ngược checklist từng bước, lỗi một nút là hoãn phóng — không có "phóng thử cho biết" với prod.

## Steps
1. `git status --short` phải sạch. Bẩn → dừng, báo user commit/stash trước.
2. Chạy migration dry-run: `${CLAUDE_SKILL_DIR}/scripts/migrate.sh --dry-run $ARGUMENTS`
3. Deploy: `<lệnh deploy của team, vd ./deploy.sh $ARGUMENTS>`
4. Smoke test endpoints trong `references/endpoints.md`.
5. Ghi kết quả theo `examples/output.md`. Fail → in rollback plan, không tự retry prod.

## Constraints
- NEVER deploy prod khi dry-run đỏ. NEVER bỏ qua smoke test.
- ALWAYS ghi lại version + commit SHA sau deploy.

> **Tóm gọn 1 câu:** Deploy an toàn = repo sạch + dry-run xanh + smoke test đạt + ghi lại vết (version, SHA); prod đỏ thì in rollback plan, không tự retry.

## References
- `references/endpoints.md`, script `${CLAUDE_SKILL_DIR}/scripts/migrate.sh`, repo root `${CLAUDE_PROJECT_DIR}`.
- `${CLAUDE_SKILL_DIR}` = thư mục chứa skill này; `${CLAUDE_PROJECT_DIR}` = root repo (Claude Code tự set sẵn).
