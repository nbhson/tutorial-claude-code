# /recap — Tóm tắt context khi quay lại session sau break

> Loại Built-in · Nhóm Session & Context · Mức rủi ro Không (chỉ đọc + tóm tắt, không sửa gì)
> **Nói nôm na:** `/recap` sinh context summary khi bạn quay lại session sau giờ nghỉ/ngắt quãng: đang làm gì, tới đâu, quyết định gì đã chốt, việc dở nào còn lại. Sinh ra để khỏi cuộn 200 tin nhắn đọc lại từ đầu. Hiểu `/recap` là hiểu "đồng nghiệp trực thay tóm tắt ca cho bạn lúc quay lại".

## Khi nào dùng

- Dùng `/recap` khi quay lại session sau giờ nghỉ và không muốn cuộn 200 tin nhắn đọc lại.
- Dùng `/recap` ngay đầu buổi làm tiếp, rồi `/todos` để nắm việc còn dở.
- Không dùng `/recap` cho session mới vài tin — chẳng có gì để tóm, đọc trực tiếp nhanh hơn.

## Cách gọi

```bash
`/recap`
`/recap --short`
`/recap --decisions`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Tối qua 23h nghỉ giữa chừng, sáng mở máy:
/recap
# → "Tối qua: refactor payments.
#    Xong: tách stripe.ts riêng, test 12/12 PASS.
#    Dở: webhook verify signature (mới research, chưa code).
#    Chốt: giữ public API, không đụng test cũ.
#    Tiếp: code webhook verify → /verify → /security-review."

```

Kết quả mong đợi:

- Claude trả đúng việc của /recap (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Recap chung chung ("đang refactor") | Session mới 5 tin, chưa có gì để tóm | Session ngắn thì khỏi recap; đọc trực tiếp 5 tin |
| Recap sót todo quan trọng | Todo tạo muộn, nằm sâu trong tool log | Luôn `/todos` sau recap; ghi todo ngay khi phát sinh, đừng để trong đầu |
| Recap ghi "đã xong" cái chưa xong | Model suy từ câu "OK để đó" nhầm thành done | Đọc kỹ mục done, gạch cái chưa xong; dặn rõ "chưa xong, mai làm" trước khi nghỉ |

## Tham khảo

- [../todos/README.md](../../session-context/todos/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../export/README.md](../../session-context/export/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /recap sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
