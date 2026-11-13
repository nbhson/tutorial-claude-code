mkdir -p .claude/skills/deploy
cat > .claude/skills/deploy/SKILL.md <<'EOF'
---
name: deploy
description: Deploy staging/prod với checklist migrate + smoke test. Dùng khi user nói deploy/release/ship.
---
# Deploy
Nhận `$ARGUMENTS` (vd `/deploy staging`).
1. `git status --short` phải sạch.
2. Chạy `${CLAUDE_SKILL_DIR}/scripts/migrate.sh --dry-run $ARGUMENTS`
EOF
