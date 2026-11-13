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

> **Cách đọc bảng này:** quét cột "Trạng thái" trước để biết cái nào an tâm dùng (Ổn định), cái nào cần thận trọng (preview/beta); cột "Rủi ro 1 dòng" là điều phải nhớ trước khi bật — mỗi dòng 1 tính năng, không cần đọc cả bảng cùng lúc.

> Quy tắc: **chưa rõ gói + chỗ bật thì gõ `/` trong session và mở settings — đừng tin memory.**

> **Tóm gọn 1 câu:** 5 tính năng Desktop/Web = 5 cây cầu ra khỏi terminal — mỗi cây có tải trọng (trạng thái) và lề (rủi ro) riêng, nhìn bảng 30 giây là biết đường nào đi được.

---

## 2. Chrome extension: browser nối session

Mục này nói về cách cho Claude "mượn mắt" xem tab Chrome bạn đang mở — thay vì bạn copy-paste nội dung trang vào chat.

Extension nối tab browser với Claude session: đọc trang đang mở, trích form/log, thao tác web lặp (fill form test, so sánh UI sau deploy). Dùng khi việc nằm trên web (dashboard, docs nội bộ, trang staging) mà copy-paste tay thì lâu. Hãy hình dung như thuê trợ lý ngồi cạnh nhìn cùng màn hình: bạn lướt tới đâu, trợ lý đọc tới đó.

> 📄 **Code ví dụ:** [`examples/01-2-chrome-extension-browser-noi-session.sh`](examples/01-2-chrome-extension-browser-noi-session.sh)

- **Hợp:** đọc trang staging dài → tóm tắt; fill form test lặp 20 lần; so sánh UI trước/sau deploy (kèm screenshot).
- **Cấm:** tab banking/mail cá nhân; trang có secrets (token hiện trên màn hình); bấm nút thanh toán/xóa production.

> 📄 **Code ví dụ:** [`examples/02-2-chrome-extension-browser-noi-session.sh`](examples/02-2-chrome-extension-browser-noi-session.sh)

Rủi ro & giới hạn:

- Tab nhầm: extension đọc đúng tab đang focus — focus nhầm tab mail là lộ. Fix: profile Chrome dev riêng, chỉ mở tabs việc.
- Trang dynamic (infinite scroll, auth hết hạn): đọc thiếu. Fix: scroll/load xong mới hỏi, auth lại rồi mới trích.
- Không thay `curl`/Playwright MCP cho scrape định kỳ — extension cho việc tay, pipeline thì dùng MCP/CI.

> **Tóm gọn 1 câu:** Extension = Claude nhìn cùng màn hình Chrome với bạn — tiện cho việc tay trên web, nhưng nhớ: nó đọc đúng tab đang focus, nên tab cá nhân phải tách profile riêng.

---

## 3. Computer use: Claude bấm máy hộ (hàng rào an toàn bắt buộc)

Mục này nói về tính năng cho Claude trực tiếp cầm chuột và bàn phím — mạnh nhất trong 5 tính năng và cũng cần hàng rào chặt nhất, giống cho người lái thử cầm vô-lăng: phải giới hạn đường chạy.

Computer use cho Claude nhìn màn hình + bấm chuột/gõ phím hộ: mở app, click qua flow, chụp lỗi GUI. Hiện có qua **CLI research preview (w14/2026)** và **Desktop app** (background computer use trên macOS từ w36/2026); bật trong Desktop app settings. Chạy tốt nhất trên máy phụ/máy ảo — không phải máy đang chứa secrets production.

> 📄 **Code ví dụ:** [`examples/03-3-computer-use-claude-bam-may-ho-hang.sh`](examples/03-3-computer-use-claude-bam-may-ho-hang.sh)

Hàng rào an toàn bắt buộc (4 lớp):

```text
1. Máy: chạy trên máy ảo/phụ hoặc user riêng — không phải máy chính chứa SSH prod.
2. Allowlist app: chỉ Chrome-dev + Terminal-staging. Cấm click ngoài allowlist.
3. Giám sát: bạn nhìn màn hình khi Claude bấm (không đi cà phê khi Claude đang bấm).
4. Phạm vi: chỉ môi trường staging/test. Production thì xem thôi, bấm thì người bấm.
```

> 📄 **Code ví dụ:** [`examples/04-3-computer-use-claude-bam-may-ho-hang.sh`](examples/04-3-computer-use-claude-bam-may-ho-hang.sh)

Rủi ro & giới hạn:

- Bấm nhầm không undo được (xóa, refund, deploy). Fix: staging-only + allowlist + người giám sát. App update UI là flow gãy (nút đổi chỗ) → viết steps theo intent + screenshot verify mỗi bước.
- Chậm + tốn tokens (mỗi step 1 screenshot). Fix: chỉ dùng khi không còn API/CLI nào làm được (API > CLI > computer use).

> **Tóm gọn 1 câu:** Computer use là "trợ lý cầm chuột hộ" — chỉ đưa vô-lăng khi không còn cách điều khiển nào khác, và luôn có người ngồi cạnh nhìn.

---

## 4. Artifacts: publish output thành trang web riêng tư (beta)

Artifacts (**beta từ w25/2026, mở rộng w29**) biến output (code, doc, chart, timeline) thành trang web riêng tư, tương tác được để chia sẻ: người nhận mở link, bấm/lọc/tìm mà không cần chạy repo. Dùng khi cần chia sẻ cho người không code (PM, on-call, khách): incident timeline, audit report, prototype UI (kèm `/design` artboards — research preview w34/2026), dashboard mini.

> 📄 **Code ví dụ:** [`examples/05-4-artifacts-publish-output-thanh-trang-web-rieng.sh`](examples/05-4-artifacts-publish-output-thanh-trang-web-rieng.sh)

Rủi ro & giới hạn:

- Link lọt ra ngoài + chứa secrets = lộ. Fix: riêng tư + expiry ngắn + grep secrets trước publish (`grep -ri "sk-\|token\|password"`).
- Data cũ (publish 1 lần, log chạy tiếp) → ghi rõ "data tới giờ X" + republish. Tương tác nặng (chart 10K rows inline) → tổng hợp trước (top 20), raw log để link.

**Kiểm tra nhanh:** on-call mở link thấy ngay deploy 14:32 → api 5xx 14:35 → rollback 15:50. Không ai phải grep log 2000 dòng.

> **Tóm gọn 1 câu:** Artifacts là "biên bản họp đóng gói thành trang web": người không code mở link là hiểu, còn bạn phải giữ nó riêng tư, có hạn dùng và không dính secret.

---

## 5. Remote Control vs Web sessions

Mục này phân biệt 2 cách "đi làm từ xa" hay nhầm lẫn: một cái điều khiển máy nhà bạn từ xa, một cái chạy hẳn trên cloud của Anthropic — đồ đạc theo mỗi kiểu một khác.

| Khía cạnh | Remote Control (điều khiển máy mình từ xa) | Web sessions (session chạy trên cloud) |
|---|---|---|
| Chạy ở đâu / thấy gì | Máy bạn (local), điều khiển từ xa — thấy đúng repo/hooks/MCP local | Cloud claude.ai — chỉ thấy phần đã sync lên cloud |
| Bật ở đâu | Desktop/mobile app → Remote Control → pair (`claude remote-control`; device card hiện trên điện thoại) | claude.ai → sessions/new hoặc `/teleport` từ local; Desktop còn `/resume` mở lại session CLI (w35/2026) |
| Cần gói | Pro/Max (tùy bản) | Subscription (không phải API-only) |
| Hợp khi | Về nhà làm tiếp máy công ty, ra quán check job | Việc nhẹ, không cần hooks/MCP local, chia sẻ link |
| Rủi ro | Mất điện thoại = mất điều khiển → khóa + revoke | Quên cloud ≠ local: hooks/MCP local không theo |

> **Cách đọc bảng này:** đọc theo từng dòng khía cạnh (chạy đâu, bật đâu, hợp khi nào, rủi ro gì) và so 2 cột bên phải cạnh nhau — chọn cột nào khớp việc của bạn thì theo luôn dòng đó xuống.

> 📄 **Code ví dụ:** [`examples/06-5-remote-control-vs-web-sessions.sh`](examples/06-5-remote-control-vs-web-sessions.sh)

Rủi ro & giới hạn chung:

- Cloud ≠ local (bẫy số 9 của [Tips 10](./10-debugging-power-moves.md)): config/hooks/MCP/secrets local không tự lên cloud. Cái gì cần trên cloud thì cấu hình cloud-scope + test trên cloud trước.
- Pair/device lạ: revoke ngay khi mất máy, kiểm tra sessions đang mở (`/teleport` list) rồi kill cái lạ.
- Web session không thay CI: việc định kỳ thì routines/schedule, việc nặng thì local + computer use.

> **Tóm gọn 1 câu:** Remote Control là "chỉ tay từ xa vào máy nhà", Web sessions là "thuê bàn làm việc trên cloud" — máy nhà có gì cloud không có, nhớ điều đó là tránh 90% bỡ ngỡ.

---

## 6. Voice dictation: nói thành prompt

Mục này nói về cách thay gõ bằng nói — nhanh trong một số tình huống, nhưng có "mất tiếng" riêng cần biết.

Nói → thành text prompt trong session (mic button hoặc phím OS). Hợp khi đang đi bộ, tay bận, hoặc brainstorm dài nói nhanh hơn gõ. Đây là **nhập liệu**, không phải kênh discuss.

> 📄 **Code ví dụ:** [`examples/07-6-voice-dictation-noi-thanh-prompt.sh`](examples/07-6-voice-dictation-noi-thanh-prompt.sh)

Rủi ro & giới hạn:

- Transcript sai từ khóa (plan.md → "plan chấm md", `feat/my-main-fix` → "fit my main fix"). Fix: tên file/hàm/branch luôn gõ tay, chỉ nói phần mô tả. Ồn + mic mở = lệnh nhầm → chỗ yên, đọc lại transcript 3 giây mới Enter.
- Voice không thay review: nói nhanh thì càng phải verify (`/diff` + test) vì prompt nói thường lỏng hơn prompt gõ.

> **Tóm gọn 1 câu:** Voice là "ghi âm thành lệnh": nói cho phần mô tả, còn tên file/hàm/branch luôn gõ tay — vì mic không phân biệt được `plan.md` với "plan chấm md".

---

## 7. Ví dụ copy-paste: 3 ca dùng thật

Mục này ghép các tính năng ở mục 2–6 thành 3 tình huống đời thực: chia sẻ staging fail cho PM, chạy computer use có người nhìn, và chuyển máy giữa chừng bằng voice + teleport.

### Ca 1 — Extension + artifacts: staging fail → trang chia sẻ cho PM (15 phút)

> 📄 **Code ví dụ:** [`examples/08-ca-1-extension-artifacts-staging-fail-trang-chia.sh`](examples/08-ca-1-extension-artifacts-staging-fail-trang-chia.sh)

### Ca 2 — Computer use staging-only có giám sát (20 phút)

> 📄 **Code ví dụ:** [`examples/09-ca-2-computer-use-staging-only-co-giam.sh`](examples/09-ca-2-computer-use-staging-only-co-giam.sh)

### Ca 3 — Voice + teleport: về nhà làm tiếp không mất mạch (10 phút)

> 📄 **Code ví dụ:** [`examples/10-ca-3-voice-teleport-ve-nha-lam-tiep.sh`](examples/10-ca-3-voice-teleport-ve-nha-lam-tiep.sh)

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

> **Cách đọc bảng này:** bắt đầu từ cột "Việc" — tìm dòng khớp chuyện bạn cần làm; cột "Trạng thái / bật" cho biết tính năng đang ở giai đoạn nào và bật từ đâu, cột cuối là điều phải nhớ trước khi dùng.

> **Tóm gọn 1 câu:** Bảng này là bản đồ 7 chuyến đi của Desktop/Web — tra cột "Việc" trước, còn cột cuối là "điều kiện lên xe" đừng bao giờ bỏ qua.

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

> **Tóm gọn 1 câu:** 8 bẫy desktop/web đều xoay quanh 2 chữ "nhầm chỗ" — nhầm tab, nhầm máy, nhầm môi trường — tra bảng mục 8 trước khi dùng tính năng mới là né gần hết.

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
