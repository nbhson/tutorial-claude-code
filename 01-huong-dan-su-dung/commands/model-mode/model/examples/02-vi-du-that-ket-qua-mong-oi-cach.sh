# Bước 1: đang dùng sonnet, context 30%
/model opus

# Bước 2: giao bài khó, yêu cầu suy luận sâu
Hãy phân tích race condition trong src/queue/worker.ts.
Vẽ timeline 2 workers cùng dequeue 1 job, chỉ ra dòng nào thiếu lock,
rồi đề xuất fix bằng mutex hoặc atomic compare-and-swap.
