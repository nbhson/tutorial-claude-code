claude plugin validate awesome-reviewer
# → hooks: tool.call(Read) [chỉ đọc — lành]
# → calls: $.fs.read (src/**), $.model.complete
# → red flags: NONE (không mạng, không shell, không env)
# → KẾT LUẬN: xanh. Cài được.

claude plugin test awesome-reviewer --no-hooks
# → lõi chạy OK (đọc + chấm, không cần hooks)
