# /exit — Thoát Claude Code: đóng session, giữ nguyên auth và config

> Loại Built-in · Nhóm Auth · Nguy hiểm Không (chỉ đóng CLI; history + token + code giữ nguyên — muốn xoá auth phải `/logout`)

`/exit` (alias: `Ctrl+C` 2 lần, `/quit`, gõ `exit`) thoát hẳn Claude Code về shell. Token vẫn lưu, lần sau mở `claude` là vào ngay không cần login. Hiểu `/exit` là hiểu "đóng cửa đi về" — khác `/clear` (ở lại nhưng quên việc cũ) và `/logout` (về và rút chìa).

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/exit` | _(không có)_ | Thoát CLI ngay, lưu session để `/resume` được |
| `/quit` | alias | Y hệt `/exit` |
| `Ctrl+C` ×2 | phím | Thoát nhanh không cần gõ lệnh |
| `exit` (gõ thường) | alias | Thoát (khi không nhầm với lệnh shell) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: thoát chuẩn cuối ngày
/exit
# → "Session saved. Resume with: claude --resume (hoặc /resume)"
```

```bash
# Dạng 2: thoát nhanh tay đang bận
# Bấm Ctrl+C 2 lần liên tiếp
```

```bash
# Dạng 3: thoát rồi vào lại đúng session cũ
/exit
claude --resume
# → tiếp tục đúng chỗ hôm qua
```

---

## Cách nó hoạt động

### Cơ chế sâu: exit lưu gì rồi mới đóng?

1. **Checkpoint session:** CLI flush transcript (lịch sử chat) xuống `~/.claude/history/<session-id>.jsonl`, lưu working dir, model đang dùng, todos đang dở.
2. **Dọn tiến trình con:** kill các Bash background, MCP stdio server do session này spawn (trừ server dùng chung thì giữ).
3. **Không đụng auth/config:** token, settings, CLAUDE.md nguyên vẹn — nên mở lại là tiếp tục ngay.
4. **Cloud session pair thì sao?** `/exit` local không kill cloud session đang teleport — cloud vẫn chạy. Muốn dừng hẳn: vào cloud gõ `/exit` hoặc stop trên web.

### Sơ đồ exit vs các lệnh dễ nhầm

```text
/exit    → đóng CLI, giữ token + history (mai /resume)
/clear   → ở lại CLI, xoá context chat (quên việc cũ, vẫn là mình)
/logout  → ở lại CLI, xoá token (việc còn nhưng mất quyền gọi model)
/quit    → = /exit
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Đóng CLI? | Mất gì? | Dùng khi nào? |
|---|---|---|---|
| `/exit` | Có | Không mất gì | Nghỉ, chuyển máy |
| `/clear` | Không | Mất context chat hiện tại | Bắt đầu việc mới |
| `/logout` | Không | Mất auth | Đổi acc/trả máy |
| Đóng terminal (X) | Có (đột ngột) | Có thể mất checkpoint cuối | Tránh — luôn `/exit` trước |

> Quy tắc ngón tay cái:
>
> - **Nghỉ → `/exit`. Việc mới → `/clear`. Đổi người → `/logout`. Cả 3 đều rẻ, đừng đóng X terminal.**

---

## Ví dụ thực tế

### Kịch bản 1: Cuối ngày, mai làm tiếp đúng chỗ

```bash
# Đang dở task refactor, 18h rồi:
/exit
# → "Session abc123 saved."

# Sáng mai:
claude --resume
# → "Resumed session abc123 (47 messages). Tiếp tục?"
```

> Kết quả: không mất 1 chữ context hôm qua.

### Kịch bản 2: Thoát gấp khi lệnh chạy lâu

```bash
# Claude đang chạy test 10 phút, bạn phải đi họp:
# Bấm Ctrl+C 1 lần → huỷ lệnh đang chạy (ở lại session)
# Bấm Ctrl+C lần 2 → /exit luôn

# Sau họp:
claude --resume
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Đóng X terminal thay vì `/exit` | Checkpoint cuối chưa flush, resume thiếu vài message | Luôn `/exit` trước khi đóng terminal/tắt máy |
| Tưởng `/exit` là đăng xuất (máy share) | Token còn, người sau mở `claude` là dùng quota bạn | Máy share phải `/logout`, không phải `/exit` |
| Task background (test dài) đang chạy mà exit | Tiến trình con bị kill, test dở | Đợi xong hoặc `nohup` task ra ngoài trước |

### Tốn token?

- Không. Exit là thao tác local thuần.

### Version / provider

- Mọi bản đều có. `--resume` cần v2.x để ổn định.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/exit` + `--resume` | Nghỉ giữa task dài | Exit → mai resume |
| `/exit` + `/teleport` | Về nhà làm tiếp trên laptop | Teleport sang laptop → exit máy công ty |
| `/exit` + git commit | Checkpoint cả code + chat | Commit code → exit (mai resume + git log là đủ) |

Workflow chuẩn "cuối ngày (1 phút)":

```bash
# 1. Commit code dở (kẻo quên)
git add -A && git commit -m "WIP: refactor auth"
# 2. Thoát
/exit
# 3. Sáng mai: claude --resume
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `--resume` báo `no session found` | Hôm qua đóng X terminal, checkpoint hỏng | `claude --resume --list` xem còn gì; rút kinh nghiệm `/exit` |
| `Ctrl+C` 1 lần thoát luôn (không ở lại) | Bấm 2 lần quá nhanh | Dùng `/exit` gõ tay khi muốn chắc; 1 lần Ctrl+C = huỷ lệnh, đợi 1s rồi mới bấm tiếp nếu muốn thoát |
| Exit nhưng tiến trình node còn treo | MCP server con không dọn kịp | `ps aux \| grep claude` rồi kill tay; bản mới tự dọn tốt hơn |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../logout/README.md](../../auth-settings/logout/README.md) — thoát + xoá auth (nặng hơn exit)
  - [../login/README.md](../../auth-settings/login/README.md) — vào lại sau khi thoát lâu bị hết token
  - [../status/README.md](../../auth-settings/status/README.md) — vào lại thì status kiểm tra 3 giây
  - [../teleport/README.md](../../auth-settings/teleport/README.md) — mang session đi trước khi exit máy này
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md) — vòng đời session
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — thoát trên từng bề mặt
  - [../../10-permissions-modes-availability.md](../../../10-permissions-modes-availability.md) — resume có giữ permissions không

> Mẹo 1 dòng: _`/exit` trước khi đóng terminal — 2 giây hôm nay cứu 20 phút context ngày mai._
