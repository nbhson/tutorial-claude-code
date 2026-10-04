# /copy — Copy đoạn hội thoại ra clipboard để paste nhanh sang Slack/PR/docs

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (chỉ đọc + ghi clipboard, không xóa/sửa code hay history)

`/copy` là "chụp nhanh 1 đoạn": copy phần hội thoại (hoặc câu trả lời cuối) ra clipboard hệ điều hành để paste vào Slack, PR, docs mà không cần xuất cả file như `/export`.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/copy` | _(không có)_ | Copy đoạn liên quan/câu trả lời gần nhất ra clipboard |

Không có flag `--last/--all` chính thức — muốn phạm vi cụ thể thì dặn bằng lời.

Ví dụ gọi từng dạng:

```bash
# Dạng 1: copy nhanh câu cuối
/copy
# → paste (Cmd/Ctrl+V) sang Slack
```

```bash
# Dạng 2: copy kèm chỉ định phạm vi (dặn bằng lời)
/copy
# rồi nhắn: "Chỉ copy quyết định Postgres+Drizzle + 5 dòng code handler, dạng markdown."
```

```bash
# Dạng 3: copy trước khi clear (giữ ý hay)
/copy
/clear
```

```bash
# Dạng 4: copy snippet để đưa vào PR mô tả
/copy
# → paste vào ô PR description trên GitHub
```

---

## Cách nó hoạt động

1. **Lấy đoạn từ transcript:** câu trả lời gần nhất (hoặc đoạn bạn vừa chỉ định) được render ra markdown/text.
2. **Ghi clipboard OS:** qua API clipboard của terminal/IDE/Desktop. CLI qua SSH không clipboard có thể fallback in ra để bạn copy tay.
3. **Không tạo file:** khác `/export` (ghi file). `/copy` chỉ ở clipboard — tắt máy/paste đè là mất.
4. **Giữ format:** code blocks giữ nguyên ``` fences để paste vào Slack/GitHub vẫn đẹp.

| Lệnh | Đích | Khi nào dùng |
|---|---|---|
| `/copy` | Clipboard (tạm, nhanh) | Paste 1 đoạn vào chat/PR |
| `/export` | File (lâu dài) | Bàn giao, lưu docs, audit |

---

## Ví dụ thực tế

### Kịch bản 1: Fix xong — copy giải pháp gửi Slack team

```bash
# Model vừa đưa patch mutex 20 dòng, team đang hóng trong Slack
/copy
# → sang Slack paste: code + giải thích giữ nguyên format
# → nhanh hơn chụp màn hình, đồng đội copy code được luôn
```

### Kịch bản 2: Copy quyết định vào PR description

```bash
# Vừa chốt kiến trúc với model, cần ghi vào PR
/copy
# rồi dặn: "Chỉ copy phần quyết định + lý do, dạng 5 bullets."
# → paste vào GitHub PR, reviewer hiểu ngay vì sao chọn Postgres
```

---

## Rủi ro & lưu ý

- **Mất gì:** không mất gì trong session. Nhưng clipboard là tạm — paste đè là mất. Đoạn quan trọng, dài hạn → `/export` thay vì `/copy`.
- **Tốn token:** 0.
- **Version/bề mặt:** v2.1.x CLI/IDE/Web/Desktop. Qua SSH/headless không clipboard → fallback in text ra terminal để copy tay.
- **Rò rỉ secret:** đoạn copy có thể chứa key/token đã chat → kiểm tra trước khi paste vào kênh share rộng. Với secrets, copy tay từng dòng sạch thay vì cả đoạn.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/copy` → paste Slack/PR | Chia sẻ nhanh |
| `/copy` → `/clear` | Giữ ý hay rồi mới xóa |
| `/copy` vs `/export` | Ngắn/tạm → copy; dài/lưu → export |
| `/todos` → `/copy` | Copy trạng thái todos gửi sếp |

```bash
/todos
/copy
# → paste todos vào daily standup channel
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Paste ra trắng/không có gì | Clipboard qua SSH không khả dụng / quyền OS chặn | Copy tay từ output fallback; cấp quyền clipboard cho terminal/IDE |
| Copy cả đoạn dài 500 dòng | Không giới hạn phạm vi | Dặn rõ: "chỉ copy 20 dòng patch + 3 bullets giải thích" rồi `/copy` |
| Format vỡ khi paste vào Slack | Slack cần markdown/plain khác nhau | Paste dưới dạng code block hoặc dùng `/export` lấy file khi cần format chuẩn |
| Muốn lưu lâu dài | Clipboard là tạm | Dùng `/export` ra file + commit vào docs |
| Paste nhầm secret lên kênh chung | Đoạn chat chứa key | Thu hồi (revoke) key, xóa tin nhắn, lần sau không paste secret vào chat |

---

## Tham khảo

- Lệnh liên quan:
  - [../export/README.md](../export/README.md) — xuất file lâu dài
  - [../clear/README.md](../clear/README.md) — copy trước khi xóa
  - [../todos/README.md](../todos/README.md) — copy tiến độ gửi team
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../10-permissions-modes-availability.md` — quyền truy cập clipboard trên từng nền
  - `../11-git-worktrees-checkpoints.md` — checkpoints (copy quyết định kèm checkpoint nào?)

> Mẹo 1 dòng: _đoạn nào đáng paste 2 nơi trở lên thì `/export` luôn — clipboard chỉ cho việc 1 lần._
