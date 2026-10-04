# Tips 02 — Prompt Engineering Cho Claude Code (Viết Sao, Ra Vậy)

## 1. Giải phẫu prompt tốt (4 thành phần)

1. **Files nào**: chỉ file/thư mục liên quan (`auth/`, `/data/feedback.csv`...).
2. **Tìm/tạo gì**: end-state cụ thể, không phải activity ("top 5 complaints theo frequency" > "analyze data").
3. **Chi tiết nào**: columns, quotes, counts, segments...
4. **Format output nào**: markdown table, JSON, file path...

```
TỆ:  "Analyze this data"
TỐT: "Đọc /data/feedback-q3.csv. Tìm top 5 complaints theo frequency.
      Mỗi dòng: quote nguyên văn + count + segment. Output markdown table.
      Xong đối chiếu totals ở summary vs raw data, lệch thì fix trước khi show."
```

## 2. Ba gia vị nâng chất lượng 10x

- **Success criteria explicit**: "Done = `pnpm test auth` xanh + không file nào >300 dòng".
- **Cách verify**: "sau khi sửa, chạy X và dán log pass/fail" (Claude tự iterate trong cùng message).
- **Ràng buộc phủ định**: "đừng đụng `src/generated/`, đừng đổi schema, đừng commit main".

## 3. Mẫu prompt theo task

```text
BUG: "Tái hiện lỗi Y (steps...). Tìm root cause trong <module>, fix tối thiểu,
      thêm regression test, chạy focused test và dán kết quả."

FEATURE: "Trước khi làm gì, đọc <3 file liên quan> rồi trình plan gồm:
      files đụng, steps, risks, cách verify. Chờ tôi duyệt."

REFACTOR: "Tách file X (>500 dòng) thành modules <...>, giữ public API,
      chạy full test sau mỗi bước, dừng và báo nếu test đỏ."

RESEARCH: "Dùng subagent explore <phạm vi hẹp>. Trả về: files liên quan + flow hiện tại
      + 2 phương án (pros/cons). Chỉ files mày sẽ sửa/đọc để làm change."
```

## 4. Lỗi prompt phổ biến

| Sai | Sửa |
|---|---|
| "investigate auth" (không scope) | Khoanh module + câu hỏi cần trả lời + output format |
| Một prompt 5 việc không liên quan | Tách 5 prompts/sessions, mỗi cái 1 việc |
| Không cho cách verify | Luôn kèm check (test/lint/log/diff) |
| Mô tả solution thay vì problem | Mô tả problem + constraints, để Claude đề xuất solution trong plan mode |
| File >1000 dòng ném nguyên cho Claude | Tách nhỏ trước, hoặc bảo subagent tóm tắt từng phần |

## 5. Non-coders cũng dùng được

Cùng 1 công thức nhưng thay "files" bằng "nguồn" (data folder, docs...), thay "test" bằng "đối chiếu số liệu".
Bắt đầu bằng: *"Phỏng vấn tôi để hiểu project này, rồi tạo CLAUDE.md"* — Claude sẽ hỏi ngược lại,
bạn chỉ cần trả lời hội thoại.
