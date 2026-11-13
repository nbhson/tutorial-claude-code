# Cách 1: subscription (khuyên dùng cho dev tay)
claude login        # → mở browser, sign-in claude.ai

# Cách 2: API key (khuyên dùng cho CI/máy phụ)
export ANTHROPIC_API_KEY="sk-ant-xxxx"
claude -p "ping" --output-format json
