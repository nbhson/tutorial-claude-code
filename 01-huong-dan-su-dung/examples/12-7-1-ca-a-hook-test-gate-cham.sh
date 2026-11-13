# Triệu chứng: mọi turn-end đều "treo" vài phút
# Metrics: hook test-gate p99 240s, các hook khác <2s → thủ phạm rõ
# Fix: focused scope (env TEST_SCOPE), full suite để CI:
TEST_SCOPE=auth ./hooks/test-gate.sh
time TEST_SCOPE=auth ./hooks/test-gate.sh
# → p99 240s → 20s. Verify: metrics turn sau hook <30s
