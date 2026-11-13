# Login ADC trước:
gcloud auth application-default login --project my-team-123
# → browser OK

/setup-vertex
# → project my-team-123 [Yes] → region asia-southeast1 [Yes]
# → auth ADC [Yes] → model sonnet [Yes]
# → test "hello" → "Hello! (via Vertex, 1.4s)" ✓
