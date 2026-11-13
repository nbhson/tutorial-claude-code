# Khung khởi tạo plugin từ zero (copy-paste):
mkdir -p acme-standard/{.claude-plugin,skills/{deploy,review-pr},agents,hooks}
cat > acme-standard/.claude-plugin/plugin.json <<'EOF'
{
  "name": "acme-standard",
  "version": "0.1.0",
  "description": "Standard workflow team Acme.",
  "skills": ["skills/deploy", "skills/review-pr"]
}
EOF
# Rồi copy SKILL.md từ bài 05 vào skills/*/, hooks từ bài 07 vào hooks/.
