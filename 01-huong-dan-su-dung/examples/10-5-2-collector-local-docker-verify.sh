docker run -p 4317:4317 -p 4318:4318 -v ./otel-collector-config.yaml:/etc/otel.yaml \
  otel/opentelemetry-collector --config=/etc/otel.yaml
# → mở Claude Code session, làm 1 task nhỏ, xem collector log có spans về không
