# Không có Grafana? Grep console exporter vẫn ra (mức 2):
OTEL_TRACES_EXPORTER=console claude "làm task X" 2>&1 | grep -i "hook.*duration" | sort -k2 -n | tail -5
OTEL_METRICS_EXPORTER=console claude "làm task X" 2>&1 | grep -i "skill.*tokens" | sort -k2 -n | tail -5
