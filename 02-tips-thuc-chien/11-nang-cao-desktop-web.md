# Tips 11 — Nâng cao Desktop & Web: extension, computer use, artifacts, remote, voice

> **Bài này cho ai:** dev muốn mở rộng Claude Code ra bản Desktop và Web (extension, computer use, artifacts, remote, voice), hoặc tech lead chuẩn hóa cách dùng cho team.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)); nên đọc [bài 02 — Các bề mặt terminal/IDE/web/desktop](../01-huong-dan-su-dung/02-cac-be-mat-terminal-ide-web-desktop.md) trước vì mục 5 nói rõ cloud ≠ local.
> **Đọc xong bạn làm được:**
> - Chọn đúng 1 trong 5 tính năng cho việc thật, kèm gói cần có, chỗ bật và rủi ro 1 dòng.
> - Bật extension và computer use an toàn (profile Chrome riêng, allowlist staging), publish artifact riêng tư có thời hạn.
> - Phân biệt Remote Control với Web sessions, biết việc nào bắt buộc ở local, việc nào lên cloud được.
> - Tránh 8 bẫy desktop/web và tự chấm checklist hằng tháng.
> **Thời gian:** ~40 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Chrome extension | Lớp mở rộng của Chrome cho Claude đọc tab bạn đang mở thay vì copy-paste tay | Cài từ Chrome Web Store → Connect → tab staging hiện trong session |
| Computer use | Claude nhìn màn hình rồi bấm chuột, gõ phím hộ bạn | Desktop app → Settings → Computer use → Enable |
| Artifacts | Output (timeline, báo cáo, biểu đồ) đăng thành trang web riêng tư, người nhận mở link là xem + bấm được | Publish riêng tư + expiry 7 ngày → PM mở link không cần clone repo |
| Remote Control | Điều khiển từ xa máy đang chạy Claude, vẫn thấy hooks/MCP local | Desktop công ty → pair với điện thoại → làm tiếp ở nhà |
| Voice dictation | Nói thành chữ trong ô nhập prompt thay vì gõ | Bấm mic → nói → đọc lại transcript 3 giây rồi Enter |

---

## 1. Bản đồ 5 tính năng Desktop/Web

Bảng dưới là bản đồ chung của cả bài; các mục 2–6 mới đi vào cách bật, ví dụ copy-paste và rủi ro từng tính năng.

| Tính năng | Trạng thái | Bật ở đâu | Rủi ro 1 dòng |
|---|---|---|---|
| Chrome extension | Ổn định | Chrome Web Store → nối session | Đọc nhầm tab banking/mail → chỉ bật ở profile dev |
| Computer use | CLI research preview (w14/2026) + Desktop; background mode trên macOS từ w36/2026 | Desktop app settings → permissions | Bấm nhầm nút xóa/deploy → allowlist app + giám sát |
| Artifacts publish | Beta (w25/2026, mở rộng w29) | Session → Share/Publish riêng tư | Link lọt ra ngoài → riêng tư + expiry + không secrets |
| Remote Control / Web sessions | Ổn định (subscription) | Desktop/mobile pair / claude.ai + `/teleport` | Cloud ≠ local (hooks/MCP không theo) |
| Voice dictation | Mọi gói (mic máy) | OS + mic button trong input | Transcript sai từ khóa → gõ lại tên file/hàm |

> Tính năng lân cận cùng họ: in-app browser trên Desktop (w28/2026) thay thế extension khi không muốn cài thêm; iOS Simulator pane trên Desktop beta (w30/2026) cho dev mobile; `/design` artifacts artboards research preview (w34/2026) cho prototype UI. Cái nào ghi "preview/beta" thì kỳ vọng đổi API — đừng build quy trình team lên tính non-stable.

> Quy tắc: **chưa rõ gói + chỗ bật thì gõ `/` trong session và mở settings — đừng tin memory.**

---

## 2. Chrome extension: browser nối session

Extension nối tab browser với Claude session: đọc trang đang mở, trích form/log, thao tác web lặp (fill form test, so sánh UI sau deploy). Dùng khi việc nằm trên web (dashboard, docs nội bộ, trang staging) mà copy-paste tay thì lâu.

```bash
# Bật (3 bước):
# 1. Cài extension từ Chrome Web Store (profile Chrome dev riêng — không phải profile banking)
# 2. Mở extension → Connect → đăng nhập đúng tài khoản Claude
# 3. Trong Claude Code session: gõ /ide hoặc settings → thấy browser-tab connected
```

- **Hợp:** đọc trang staging dài → tóm tắt; fill form test lặp 20 lần; so sánh UI trước/sau deploy (kèm screenshot).
- **Cấm:** tab banking/mail cá nhân; trang có secrets (token hiện trên màn hình); bấm nút thanh toán/xóa production.

```bash
# Prompt mẫu (copy-paste):
"Đọc tab staging đang mở (orders page), liệt kê 5 orders fail sáng nay: id + lỗi + 1 dòng guess. Không bấm nút gì, chỉ đọc."
# → verify: đối chiếu 2 orders đầu bằng mắt trước khi tin cả 5
```

Rủi ro & giới hạn:

- Tab nhầm: extension đọc đúng tab đang focus — focus nhầm tab mail là lộ. Fix: profile Chrome dev riêng, chỉ mở tabs việc.
- Trang dynamic (infinite scroll, auth hết hạn): đọc thiếu. Fix: scroll/load xong mới hỏi, auth lại rồi mới trích.
- Không thay `curl`/Playwright MCP cho scrape định kỳ — extension cho việc tay, pipeline thì dùng MCP/CI.

---

## 3. Computer use: Claude bấm máy hộ (hàng rào an toàn bắt buộc)

Computer use cho Claude nhìn màn hình + bấm chuột/gõ phím hộ: mở app, click qua flow, chụp lỗi GUI. Hiện có qua **CLI research preview (w14/2026)** và **Desktop app** (background computer use trên macOS từ w36/2026); bật trong Desktop app settings. Chạy tốt nhất trên máy phụ/máy ảo — không phải máy đang chứa secrets production.

```bash
# Bật:
# Desktop app → Settings → Computer use → Enable → cấp Accessibility/Screen Recording (macOS)
# → allowlist: chỉ cho 2-3 apps việc (Terminal staging, Chrome dev) — cấm Finder banking, password manager
# (allowlist = danh sách app computer use được bấm vào; ngoài danh sách là không bấm)

# Kiểm tra trong session: gõ / → thấy computer-use commands mới dùng (không thấy = gói/provider bạn vắng)
```

Hàng rào an toàn bắt buộc (4 lớp):

```text
1. Máy: chạy trên máy ảo/phụ hoặc user riêng — không phải máy chính chứa SSH prod.
2. Allowlist app: chỉ Chrome-dev + Terminal-staging. Cấm click ngoài allowlist.
3. Giám sát: bạn nhìn màn hình khi Claude bấm (không đi cà phê khi Claude đang bấm).
4. Phạm vi: chỉ môi trường staging/test. Production thì xem thôi, bấm thì người bấm.
```

```bash
# Prompt mẫu có hàng rào (copy-paste):
"Mở Chrome-dev, vào staging.acme.test/orders, chụp screenshot 5 orders fail. Chỉ đọc + chụp, KHÔNG bấm nút Refund/Delete/Cancel. Xong dừng và báo."
# → verify: xem screenshots có đủ 5 không, có nút nào bị bấm nhầm không (check audit log staging)
```

Rủi ro & giới hạn:

- Bấm nhầm không undo được (xóa, refund, deploy). Fix: staging-only + allowlist + người giám sát. App update UI là flow gãy (nút đổi chỗ) → viết steps theo intent + screenshot verify mỗi bước.
- Chậm + tốn tokens (mỗi step 1 screenshot). Fix: chỉ dùng khi không còn API/CLI nào làm được (API > CLI > computer use).

---

## 4. Artifacts: publish output thành trang web riêng tư (beta)

Artifacts (**beta từ w25/2026, mở rộng w29**) biến output (code, doc, chart, timeline) thành trang web riêng tư, tương tác được để chia sẻ: người nhận mở link, bấm/lọc/tìm mà không cần chạy repo. Dùng khi cần chia sẻ cho người không code (PM, on-call, khách): incident timeline, audit report, prototype UI (kèm `/design` artboards — research preview w34/2026), dashboard mini.

```bash
# Publish (trong session hỗ trợ artifacts):
# 1. Nhờ Claude render artifact (html/react single-file, data inline, không gọi backend lạ)
# 2. Bấm Share/Publish → chế độ Private + đặt expiry (7 ngày) → copy link
# 3. Gửi link + ghi chú "data tới 10:00 04/10, không chứa secrets"

# Prompt mẫu (copy-paste):
"Từ deploy.log + alerts.txt, render artifact incident timeline 02/10: trục giờ 14:00-16:00, mỗi event 1 card (giờ + service + lỗi + link run), filter theo service, không hiện secrets/token. Publish private, expiry 7 ngày."
```

Rủi ro & giới hạn:

- Link lọt ra ngoài + chứa secrets = lộ. Fix: riêng tư + expiry ngắn + grep secrets trước publish (`grep -ri "sk-\|token\|password"`).
- Data cũ (publish 1 lần, log chạy tiếp) → ghi rõ "data tới giờ X" + republish. Tương tác nặng (chart 10K rows inline) → tổng hợp trước (top 20), raw log để link.

**Kiểm tra nhanh:** on-call mở link thấy ngay deploy 14:32 → api 5xx 14:35 → rollback 15:50. Không ai phải grep log 2000 dòng.

---

## 5. Remote Control vs Web sessions

| Khía cạnh | Remote Control (điều khiển máy mình từ xa) | Web sessions (session chạy trên cloud) |
|---|---|---|
| Chạy ở đâu / thấy gì | Máy bạn (local), điều khiển từ xa — thấy đúng repo/hooks/MCP local | Cloud claude.ai — chỉ thấy phần đã sync lên cloud |
| Bật ở đâu | Desktop/mobile app → Remote Control → pair (`claude remote-control`; device card hiện trên điện thoại) | claude.ai → sessions/new hoặc `/teleport` từ local; Desktop còn `/resume` mở lại session CLI (w35/2026) |
| Cần gói | Pro/Max (tùy bản) | Subscription (không phải API-only) |
| Hợp khi | Về nhà làm tiếp máy công ty, ra quán check job | Việc nhẹ, không cần hooks/MCP local, chia sẻ link |
| Rủi ro | Mất điện thoại = mất điều khiển → khóa + revoke | Quên cloud ≠ local: hooks/MCP local không theo |

```bash
# Remote Control (về nhà làm tiếp):
# Desktop công ty: Enable Remote Control → pair với điện thoại
# → từ nhà: mở app → thấy đúng session/repo công ty (hooks/MCP còn nguyên)

# Web session (việc nhẹ, chia sẻ):
# Local: /teleport (đẩy session lên cloud) → về nhà mở claude.ai tiếp
# → cần hooks/MCP local thì ở lại Remote, không thì Web đủ
```

Rủi ro & giới hạn chung:

- Cloud ≠ local (bẫy số 9 của [Tips 10](./10-debugging-power-moves.md)): config/hooks/MCP/secrets local không tự lên cloud. Cái gì cần trên cloud thì cấu hình cloud-scope + test trên cloud trước.
- Pair/device lạ: revoke ngay khi mất máy, kiểm tra sessions đang mở (`/teleport` list) rồi kill cái lạ.
- Web session không thay CI: việc định kỳ thì routines/schedule, việc nặng thì local + computer use.

---

## 6. Voice dictation: nói thành prompt

Nói → thành text prompt trong session (mic button hoặc phím OS). Hợp khi đang đi bộ, tay bận, hoặc brainstorm dài nói nhanh hơn gõ. Đây là **nhập liệu**, không phải kênh discuss.

```bash
# Bật:
# macOS: System Settings → Keyboard → Dictation → Enable (bấm Fn×2 để nói)
# Session: bấm mic → nói → kiểm tra transcript → Enter
# Prompt nói mẫu (ngắn, 1 ý 1 lần): "compact giữ plan chấm md phase hai, bỏ log test cũ"
# → kiểm tra transcript ra đúng "plan.md phase 2" mới Enter
```

Rủi ro & giới hạn:

- Transcript sai từ khóa (plan.md → "plan chấm md", `feat/my-main-fix` → "fit my main fix"). Fix: tên file/hàm/branch luôn gõ tay, chỉ nói phần mô tả. Ồn + mic mở = lệnh nhầm → chỗ yên, đọc lại transcript 3 giây mới Enter.
- Voice không thay review: nói nhanh thì càng phải verify (`/diff` + test) vì prompt nói thường lỏng hơn prompt gõ.

---

## 7. Ví dụ copy-paste: 3 ca dùng thật

### Ca 1 — Extension + artifacts: staging fail → trang chia sẻ cho PM (15 phút)

```bash
# 1. Extension đọc staging (chỉ đọc):
"Đọc tab staging orders, liệt kê 5 fail sáng nay: id + lỗi."
# 2. Render + publish riêng tư:
"Render artifact timeline 5 orders này (giờ + id + lỗi + link), publish private expiry 7 ngày."
# 3. Verify trước khi gửi: grep -ri "sk-\|Bearer\|password" artifact.html (phải 0 match) + mở link ẩn danh
# 4. Gửi PM link + 3 dòng tóm tắt (root cause guess + rollback + action tiếp)
```

### Ca 2 — Computer use staging-only có giám sát (20 phút)

```bash
"Mở Chrome-dev staging.acme.test, chụp 3 screenshots flow checkout (cart → pay → success). Chỉ đọc/chụp, không bấm Pay thật. Mỗi bước dừng 2s cho tôi nhìn."
# → ngồi nhìn Claude bấm. Xong: screenshots đủ 3? Có click lạ không? Audit log staging sạch?
```

### Ca 3 — Voice + teleport: về nhà làm tiếp không mất mạch (10 phút)

```bash
# Ở công ty (nói, kiểm tra transcript): "export conversation ra file, tóm tắt 5 bullets phase hiện tại"
/teleport
# → về nhà mở claude.ai: việc nhẹ làm trên web, việc cần hooks local thì Remote về máy công ty
```

---

## 8. Bảng tra nhanh: việc → tính năng → trạng thái → rủi ro

| Việc | Tính năng | Trạng thái / bật | Rủi ro nhớ 1 dòng |
|---|---|---|---|
| Đọc/tóm tắt trang staging | Chrome extension (hoặc in-app browser Desktop w28) | Chrome dev profile | Tab nhầm → profile dev riêng |
| Bấm flow GUI không có API | Computer use | CLI research preview (w14) + Desktop; background macOS w36 | Bấm nhầm prod → staging-only + giám sát |
| Chia sẻ timeline/report cho người không code | Artifacts publish | Beta w25/29 — riêng tư + expiry | Lộ secrets/link → grep + expiry |
| Prototype UI nhanh / mô phỏng iOS | `/design` artboards (w34) · iOS Simulator pane Desktop (w30) | Research preview w34 · beta w30 | Kỳ vọng đổi API |
| Về nhà làm tiếp máy công ty | Remote Control | `claude remote-control`, device card | Mất máy → revoke + kill session lạ |
| Việc nhẹ, chia sẻ link, không cần local | Web sessions/`/teleport` | Subscription cloud (`/resume` Desktop w35) | Cloud ≠ local → test cloud trước |
| Nói thay gõ khi bận tay | Voice dictation | Mọi gói, mic OS | Sai từ khóa → tên file gõ tay |

---

## 9. 8 bẫy desktop/web vẫn dính

1. **Extension ở profile chính (lẫn banking/mail).** Đọc nhầm tab cá nhân. Fix: profile Chrome dev riêng.
2. **Computer use thẳng production.** 1 click refund/xóa không undo. Fix: staging-only + allowlist + ngồi nhìn.
3. **Artifact công khai + chứa secrets.** Link chia sẻ + token inline. Fix: riêng tư + expiry + grep secrets trước publish.
4. **Quên cloud ≠ local.** Web session thiếu hooks/MCP, tưởng bug. Fix: test cloud trước, cần local thì Remote.
5. **Voice transcript sai mà Enter luôn.** "plan chấm md" thành prompt rác. Fix: đọc transcript 3s, tên file gõ tay.
6. **Computer use không verify (tin screenshots).** Bấm thiếu bước mà không biết. Fix: screenshot mỗi bước + audit log.
7. **Remote session treo không kill.** Máy mất + session mở. Fix: list sessions (`/teleport`), kill lạ, revoke device.
8. **Build quy trình team lên tính preview/beta.** Tính năng đổi/gỡ là flow gãy cả team. Fix: preview/beta chỉ dùng cá nhân thử nghiệm; quy trình chính chỉ dựng trên tính ổn định.

**Checklist desktop/web mỗi tháng:** Extension còn ở profile dev? Computer use allowlist còn đúng 2–3 apps? Artifacts nào hết expiry + secrets nào lọt (grep 1 lần)? Cloud sessions nào còn mở (kill, revoke device lạ)? Voice transcript sai mấy lần — từ khóa nào phải gõ tay?

---

## 10. Bài tập

- **Bài 1 (15 phút — extension):** tạo profile Chrome dev riêng, cài extension, connect; đọc 1 trang staging dài → tóm tắt 5 bullets, đối chiếu 2 bullets đầu bằng mắt; thử 1 trang auth hết hạn, ghi lại hành vi.
- **Bài 2 (20 phút — artifacts):** lấy 1 log/report thật, render artifact timeline (riêng tư, expiry 7 ngày); grep secrets trước publish; mở link ẩn danh kiểm tra; gửi 1 đồng nghiệp không code — họ hiểu trong 2 phút không?
- **Bài 3 (20 phút — computer use + voice + remote):** computer use staging-only 1 flow 3 bước có giám sát (ghi lại 1 chỗ suýt bấm nhầm); nói 3 prompts bằng voice, đếm transcript sai; `/teleport` 1 session lên cloud, liệt kê hooks/MCP nào không theo — viết 3 dòng note cloud-vs-local.

> Đạt: sau 1 tháng, chia sẻ incident/report bằng link riêng tư thay vì paste log 2000 dòng + không có cú bấm nhầm prod nào.

---

## 11. Tham khảo chéo

- [../01-huong-dan-su-dung/commands/auth-settings/ide/README.md](../01-huong-dan-su-dung/commands/auth-settings/ide/README.md) — nối IDE/browser với session · [../01-huong-dan-su-dung/commands/auth-settings/teleport/README.md](../01-huong-dan-su-dung/commands/auth-settings/teleport/README.md) — đẩy session lên cloud · [../01-huong-dan-su-dung/commands/auth-settings/mobile/README.md](../01-huong-dan-su-dung/commands/auth-settings/mobile/README.md) — điều khiển từ điện thoại
- [../01-huong-dan-su-dung/commands/session-context/export/README.md](../01-huong-dan-su-dung/commands/session-context/export/README.md) — xuất conversation trước teleport/clear · [../01-huong-dan-su-dung/04-slash-commands-toan-tap.md](../01-huong-dan-su-dung/04-slash-commands-toan-tap.md) — index lệnh, gõ `/` kiểm tra availability · [../01-huong-dan-su-dung/10-permissions-modes-availability.md](../01-huong-dan-su-dung/10-permissions-modes-availability.md) — availability theo gói/provider
- [Tips 10](./10-debugging-power-moves.md) — cloud ≠ local, debug L1→L4 khi desktop/web lỗi

> Mẹo 1 dòng: _extension profile dev riêng, computer use staging-only có người nhìn, artifacts riêng tư + expiry + không secrets, cloud thì test trước khi tin._
