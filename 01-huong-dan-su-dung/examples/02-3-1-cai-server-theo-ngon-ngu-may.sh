# Mở repo và xác nhận server nhận project — file nào có thì server đó mới hiểu project:
ls tsconfig.json pyrightconfig.json go.mod Cargo.toml 2>/dev/null
# TypeScript: cần tsconfig.json ở root (npx tsc --init nếu chưa có)
# Python: pyrightconfig.json hoặc pyproject.toml · Go: go.mod · Rust: Cargo.toml
