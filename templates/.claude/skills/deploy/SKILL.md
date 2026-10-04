---
name: deploy
description: Deploy staging/prod với checklist migrate + smoke test. Dùng khi user nói deploy/release/ship.
disable-model-invocation: true
allowed-tools: Bash, Read
---

# Deploy — nhận $ARGUMENTS (vd `/deploy staging`)

## Steps
1. `git status --short` phải sạch. Bẩn → dừng, báo user commit/stash trước.
2. Chạy migration dry-run: `${CLAUDE_SKILL_DIR}/scripts/migrate.sh --dry-run $ARGUMENTS`
3. Deploy: `<lệnh deploy của team, vd ./deploy.sh $ARGUMENTS>`
4. Smoke test endpoints trong `references/endpoints.md`.
5. Ghi kết quả theo `examples/output.md`. Fail → in rollback plan, không tự retry prod.

## Constraints
- NEVER deploy prod khi dry-run đỏ. NEVER bỏ qua smoke test.
- ALWAYS ghi lại version + commit SHA sau deploy.

## References
- `references/endpoints.md`, script `${CLAUDE_SKILL_DIR}/scripts/migrate.sh`, repo root `${CLAUDE_PROJECT_DIR}`.
