# Triệu chứng: tool github gọi mãi không về
# Metrics: mcp.tool_latency timeout 100% server github, các server khác ok
# → token hết hạn, không phải model dở
/mcp
# → github-mcp đỏ → reconnect hoặc disable tạm, task tiếp tục bằng Read/Grep local
# Verify: span latency về <2s hoặc server disabled, turn hết treo
