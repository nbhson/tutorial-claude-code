# Mức 1 — OTLP về collector local/team (xem 5.2):
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
export OTEL_METRICS_EXPORTER="otlp" OTEL_TRACES_EXPORTER="otlp"

# Mức 2 — in ra console/file khi chưa có collector (grep được ngay — mục 6):
export OTEL_TRACES_EXPORTER="console" OTEL_METRICS_EXPORTER="console"

# Mức 3 — team collector: endpoint team cung cấp, secrets qua env (không hardcode):
export OTEL_EXPORTER_OTLP_ENDPOINT="https://otel.team.internal:4318"
export OTEL_EXPORTER_OTLP_HEADERS="authorization=Bearer ${OTEL_TOKEN}"
