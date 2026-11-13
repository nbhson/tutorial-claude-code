# FAQ 03 — Permissions & modes (quyền hạn, chế độ & headless)

> **Bài này cho ai:** bạn cần dựng phanh cho Claude Code, chọn permission mode đúng việc, hoặc đang kẹt deny lúc headless mà không hiểu vì sao.
> **Cần gì trước:** đã cài và đăng nhập Claude Code ([FAQ 01](01-tai-khoan-pricing-cai-dat.md)); đọc qua [bài 10 — permissions & modes](../01-huong-dan-su-dung/10-permissions-modes-availability.md) càng tốt, không bắt buộc.
> **Đọc xong bạn làm được:**
> - Dựng phanh 3 lớp allow / ask / deny ở đúng file settings và xem bản merged bằng `/permissions`.
> - Xoay 5 permission mode bằng Shift+Tab, biết lúc nào giữ `plan`, lúc nào nới `auto`, khi nào `bypassPermissions` hợp lệ.
> - Chạy headless `-p` với allowlist không bị kẹt deny, viết `PreToolUse` hook deny thắng cả `bypassPermissions`.
> **Thời gian:** ~15 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Permission | Quyền Claude được tự làm việc gì mà không phải hỏi bạn | `/permissions` hiện bảng allow/ask/deny |
| allow / ask / deny | 3 mức: tự chạy luôn / hỏi 1 câu rồi chạy / cấm hẳn | `"deny": ["Bash(rm -rf:*)"]` trong settings.json |
| Permission mode | Mức "tin tưởng" của cả session, xoay bằng Shift+Tab | `plan` chỉ đọc, `bypassPermissions` bỏ hết câu hỏi |
| Headless | Chế độ `-p` cho CI/scripts: không ai bấm Yes → mọi `ask` thành deny | `claude -p "review PR"` |

## Mục lục

- [Sơ đồ nhanh](#sơ-đồ-nhanh)
- [Bảng tổng hợp: allow / ask / deny + 3 files + 5 modes](#bảng-tổng-hợp-allow--ask--deny--3-files--5-modes)
- [1. allow / ask / deny viết ở đâu?](#1-allow--ask--deny-viết-ở-đâu)
- [2. Shift+Tab xoay modes thế nào? `auto` giờ mặc định ra sao?](#2-shifttab-xoay-modes-thế-nào-auto-giờ-mặc-định-ra-sao)
- [3. Hook vs permission rule — ai thắng?](#3-hook-vs-permission-rule--ai-thắng)
- [4. Rules có chặn được lệnh lách không?](#4-rules-có-chặn-được-lệnh-lách-không)
- [5. Headless `-p` bị deny hàng loạt — fix + allowlist thế nào?](#5-headless--p-bị-deny-hàng-loạt--fix--allowlist-thế-nào)
- [6. 3 settings files merge thế nào?](#6-3-settings-files-merge-thế-nào)
- [7. Khi nào dùng `--dangerously-skip-permissions`?](#7-khi-nào-dùng---dangerously-skip-permissions)
- [Vẫn lỗi thì sao? (permissions/modes)](#vẫn-lỗi-thì-sao-permissionsmodes)

---

## Sơ đồ nhanh

```mermaid
flowchart LR
  A[defaults] --> B[project settings.json]
  B --> C[local settings.local.json]
  C --> D[managed policy org]
  D -->|deny thắng mọi allow| E{Tool nguy hiểm?}
  E -->|allow| F[Chạy luôn]
  E -->|ask| G[Hỏi 1 lần]
  E -->|deny| H[Chặn cứng]
```

## Bảng tổng hợp: allow / ask / deny + 3 files + 5 modes

Mục này gom cả 3 tầng quyền (từng lệnh, từng file, cả session) vào một bảng để tra nhanh trước khi đọc sâu từng câu.

| Khái niệm | Tóm tắt 1 dòng | Xem ở đâu |
|---|---|---|
| `allow` | Được chạy luôn, không hỏi | `/permissions` |
| `ask` | Hỏi từng lần (mặc định cho sửa/xoá/chạy) | `/permissions` |
| `deny` | Cấm luôn, hook allow cũng không nới được | `/permissions` merged |
| `.claude/settings.json` | Share team, commit git | Team baseline |
| `.claude/settings.local.json` | Cá nhân, không commit | Sở thích + allowlist riêng |
| Managed policy (org) | Admin ép, thắng mọi cái local | Team/Enterprise |
| `default` / `acceptEdits` | Hỏi như thường / tự sửa file, lệnh vẫn hỏi | Shift+Tab |
| `plan` | Chỉ đọc + trình plan, không sửa | Task lớn, duyệt trước |
| `auto` | Classifier duyệt quyền thay bạn — mặc định session mới trên Pro/Max/Team từ 14/08/2026 | Task tin cậy |
| `bypassPermissions` | Bỏ hỏi (chỉ CI sandbox) | Không dùng máy dev |

> **Cách đọc bảng này:** nửa trên (3 dòng đầu) là 3 mức quyền từng lệnh, nửa dưới là nơi ghi quyền (3 files) và chế độ cả session (5 modes) — khi phân vân "mình đang ở mức nào", tra dòng tương ứng rồi bấm vào cột "Xem ở đâu" để kiểm chứng trên máy thật.

Thứ tự merge (thắng dần): **defaults < project < local < managed**. Managed deny mà local allow → allow vô ích.

---

## 1. allow / ask / deny viết ở đâu?

> **Hỏi ngắn gọn:** muốn cấm Claude chạy `rm -rf`, hay cho nó tự chạy test không cần hỏi, thì ghi rule vào đâu?
>
> **Trả lời 1 câu:** Ghi vào 3 chỗ (2 settings file + managed policy của org) rồi mở `/permissions` xem bản merged — đừng đoán file nào đang thắng.

- `.claude/settings.json` — team baseline, commit git (VD: deny `rm -rf`, deny `.env`).
- `.claude/settings.local.json` — cá nhân, không commit (VD: allow thêm `pnpm`).
- Managed policy — org ép từ xa (VD: cấm `curl ... | bash`), local không gỡ được.

> 📄 **Code ví dụ:** [`examples/01-1-allow-ask-deny-viet-o-au.json`](examples/01-1-allow-ask-deny-viet-o-au.json)

PR nào xóa mất rule `deny rm -rf` khỏi `.claude/settings.json` → `/doctor` (mục permissions) báo đỏ, CI của team chặn merge (setup 5 lệnh đầu repo xem [FAQ 01 câu 6](01-tai-khoan-pricing-cai-dat.md#6-repo-mới-5-lệnh-setup-đầu--copy-templatesclaudemd)).

**Đào sâu:** [lệnh `/permissions`](../01-huong-dan-su-dung/commands/model-mode/permissions/README.md) · [câu 6 — merge thế nào](#6-3-settings-files-merge-thế-nào)

> **Tóm gọn 1 câu:** Quyền viết ở 3 tầng giống 3 vòng khóa: vòng nào chốt sau (local > project > defaults) và vòng của tổ chức (managed) thì luôn chốt nhất — xem bản đã khóa hết (`/permissions`) thay vì đoán từng vòng.

---

## 2. Shift+Tab xoay modes thế nào? `auto` giờ mặc định ra sao?

> **Hỏi ngắn gọn:** bấm Shift+Tab thấy hiện plan rồi acceptEdits — mấy chế độ đó là gì, sao session mới mở đã ở mode `auto`?
>
> **Trả lời 1 câu:** Shift+Tab xoay vòng 5 permission mode; **từ 14/08/2026, `auto` là mode mặc định cho session mới trên Pro/Max/Team** — classifier server-side duyệt quyền thay bạn, nằm giữa "hỏi từng bước" và bỏ hết câu hỏi.

```text
default ── hỏi như thường (làm task lạ)
acceptEdits ── tự sửa file, lệnh nguy hiểm vẫn hỏi (refactor nhiều file)
plan ── chỉ đọc + trình plan, KHÔNG sửa (task lớn, muốn duyệt trước)
auto ── classifier duyệt quyền thay bạn (mặc định session mới Pro/Max/Team từ 14/08/2026)
bypassPermissions ── bỏ hỏi TẤT CẢ (CHỈ CI sandbox, KHÔNG máy dev)
```

`auto` chặn cứng destructive git và `rm -rf` trên biến chưa resolve, có hard deny rules; thấy nó từ chối việc hợp lệ thì mở `/permissions` xem deny ẩn hoặc đổi mode bằng Shift+Tab.

Gõ `/plan` cũng vào được plan mode. Task "refactor auth 20 files" → vào `plan` trước, duyệt plan 5 phút, rồi sang `acceptEdits` cho chạy. Đừng vào `acceptEdits` ngay với task chưa hiểu.

Riêng cloud session: chỉ có `acceptEdits` / `plan` (`auto` tùy bản), **không có `bypassPermissions`** — cloud chạy xa tay bạn, bypass là tự sát. Script CI/cloud định dùng `--permission-mode bypassPermissions` → đổi sang `dontAsk` + allowlist rõ ([FAQ 10](10-ci-sdk-routines-web.md)).

**Đào sâu:** [lệnh `/plan`](../01-huong-dan-su-dung/commands/model-mode/plan/README.md) · [bài 10 — permissions & modes theo provider](../01-huong-dan-su-dung/10-permissions-modes-availability.md)

> **Tóm gọn 1 câu:** 5 mode là 5 mức "tin tưởng trao chìa nhà": hỏi từng bước, trao chìa sửa file, chỉ cho xem nhà (plan), nhờ quản gia duyệt thay (`auto`), và giao cả chùm chìa (bypass) — giao cả chùm thì chỉ khi nhà đó không có gì mất.

---

## 3. Hook vs permission rule — ai thắng?

> **Hỏi ngắn gọn:** mình viết hook deny mà permission lại allow — cái nào mới chặn được Claude thật sự?
>
> **Trả lời 1 câu:** Hook `PreToolUse` deny thắng mọi thứ kể cả `bypassPermissions`; ngược lại hook allow không nới được gì cả.

- **`PreToolUse` hook deny THẮNG TẤT CẢ**, kể cả `bypassPermissions` — hook là phanh tay độc lập.
- **Hook allow KHÔNG nới được** deny của settings hay `ask` của org. Hooks chỉ siết thêm.

| Cặp đấu | Ai thắng? |
|---|---|
| Hook deny vs `bypassPermissions` | Hook deny thắng |
| Hook allow vs settings deny | Settings deny thắng (allow vô ích) |
| Managed deny vs local allow | Managed thắng |
| Permission allow vs `ask` mặc định | Allow thắng (trong cùng level) |

> **Cách đọc bảng này:** mỗi dòng là một "đấu vật" giữa hai cơ chế — cột phải luôn nêu người thắng; quy luật chung: chặn luôn mạnh hơn cho phép, và tầng càng cao (hook/org) càng mạnh tầng dưới.

Việc critical (push main, xóa DB) → hook deny + settings deny cả hai:

> 📄 **Code ví dụ:** [`examples/02-3-hook-vs-permission-rule-ai-thang.sh`](examples/02-3-hook-vs-permission-rule-ai-thang.sh)

> 📄 **Code ví dụ:** [`examples/03-3-hook-vs-permission-rule-ai-thang.json`](examples/03-3-hook-vs-permission-rule-ai-thang.json)

**Đào sâu:** [FAQ 05 — hooks](05-hooks-faq.md) · [bài 07 — hooks tự động hóa](../01-huong-dan-su-dung/07-hooks-tu-dong-hoa.md)

> **Tóm gọn 1 câu:** Hook là phanh tay gắn ngoài hệ thống điện của xe — mất điện (bypass) phanh vẫn ăn, nhưng phanh tay chỉ dừng được xe chứ không đạp ga hộ được.

---

## 4. Rules có chặn được lệnh lách không?

> **Hỏi ngắn gọn:** mình đã deny `rm -rf` rồi — model có chạy được lệnh tương tự mà vẫn lọt qua rule không?
>
> **Trả lời 1 câu:** Không chắc chắn — rule permission chỉ match chuỗi lệnh, không phải bộ phân tích bảo mật của shell.

```text
deny "Bash(rm -rf:*)"  →  lách bằng `rm -R -f`, `python -c 'shutil.rmtree(...)'`, `./my-rm.sh`
deny "Read(.env)"      →  lách bằng `cat .env` qua Bash, `cp .env /tmp/x`
```

Rule chặn "người ngay"; chặn "kẻ gian" (lách cố ý) → hook kiểm tra sâu + OS sandbox (container không sudo, secrets mount read-only) song song với rules.

Rule permission giống cửa khóa cáp số: khóa được cửa chính, nhưng cửa sổ thì vẫn còn — muốn an toàn thật thì phải khóa cả cửa sổ (sandbox), chứ không khóa thêm 5 cái cửa nữa là đủ.

**Đào sâu:** [lệnh `sandbox`](../01-huong-dan-su-dung/commands/auth-settings/sandbox/README.md) · [FAQ 09 — bảo mật & riêng tư](09-bao-mat-quyen-rieng-tu.md)

> **Tóm gọn 1 câu:** Rule chặn theo chuỗi chứ không hiểu ý đồ — chặn được người vô ý, chặn không nổi người cố ý lách; muốn chắc thì thêm sandbox.

---

## 5. Headless `-p` bị deny hàng loạt — fix + allowlist thế nào?

> **Hỏi ngắn gọn:** chạy `claude -p` trên CI thấy subagent nào cũng bị deny, viết allowlist sao cho không kẹt giữa chừng?
>
> **Trả lời 1 câu:** `-p` không hiện prompt → mọi `ask` thành deny; fix bằng allowlist hẹp đúng việc script cần — đừng `allow Bash(*)` cho gọn, đó là mở toang.

> 📄 **Code ví dụ:** [`examples/04-5-headless-p-bi-deny-hang-loat-fix.sh`](examples/04-5-headless-p-bi-deny-hang-loat-fix.sh)

Background agent cần `git push` → headless deny (vì `ask`). Headless giống máy bán hàng tự động: không có nhân viên đứng cạnh để hỏi "bán chứ?" — không được lập trình sẵn thì mặc định từ chối. Fix: hoặc allow rõ `Bash(git push origin feat/*:*)`, hoặc tách bước push cho người bấm tay. Luôn chạy tay 1 lần với đúng allowlist trước khi gắn vào cron/CI.

**Đào sâu:** [FAQ 10 — CI, SDK, routines, Web](10-ci-sdk-routines-web.md) · [FAQ 08 — lỗi thường gặp](08-loi-thuong-gap-troubleshooting.md)

> **Tóm gọn 1 câu:** Headless là cửa hàng không có nhân viên: `ask` nào không được ghi sẵn menu thì tự hiểu là "không bán" — muốn chạy được thì ghi rõ allowlist trước, đừng để máy tự đoán.

---

## 6. 3 settings files merge thế nào?

> **Hỏi ngắn gọn:** đã allow rồi mà sao nó vẫn hỏi / vẫn deny — có phải rule ở chỗ khác thắng không?
>
> **Trả lời 1 câu:** Có — merge theo thứ tự defaults → project → local → managed, cùng key thì file đứng sau thắng, nhưng managed deny / org `ask` luôn thắng local allow.

Bản merged mới là thứ chạy thật — xem nó tại `/permissions`, đừng mở từng file đoán.

> 📄 **Code ví dụ:** [`examples/05-6-3-settings-files-merge-the-nao.sh`](examples/05-6-3-settings-files-merge-the-nao.sh)

Local bạn `allow Bash(curl:*)` nhưng managed deny → `/permissions` hiện deny → đừng mất 30 phút debug "sao allow rồi vẫn hỏi". Hỏi admin org.

**Đào sâu:** [lệnh `/permissions`](../01-huong-dan-su-dung/commands/model-mode/permissions/README.md) · [FAQ 09 — bảo mật & riêng tư](09-bao-mat-quyen-rieng-tu.md)

> **Tóm gọn 1 câu:** Ba file settings chồng lên nhau như 3 lớp áo — lớp ngoài cùng của tổ chức luôn che được lớp trong; đoán lung tung từng lớp chỉ mất thời gian, mở `/permissions` xem lớp cuối là xong.

---

## 7. Khi nào dùng `--dangerously-skip-permissions`?

> **Hỏi ngắn gọn:** có lúc nào an toàn khi chạy `--dangerously-skip-permissions` trên máy mình không?
>
> **Trả lời 1 câu:** Gần như không — chỉ CI sandbox cô lập: container dùng 1 lần, không secrets thật, không network ra ngoài.

Hook deny vẫn thắng flag này, nhưng permission hỏi thì bỏ hết — 1 lệnh `rm -rf` ngáo là đi cả máy. Mỗi khi định thêm flag vào script local hay docker dev thường trực → đó là dấu hiệu cần viết allowlist (xem [câu 5](#5-headless--p-bị-deny-hàng-loạt--fix--allowlist-thế-nào)).

> 📄 **Code ví dụ:** [`examples/06-7-khi-nao-dung-dangerously-skip-permissions.sh`](examples/06-7-khi-nao-dung-dangerously-skip-permissions.sh)

Mở 1 session "sạch" để soi nghi vấn (mods/hooks ngoài không load) → dùng `claude --safe-mode`; chạy ở chế độ giới hạn thêm → `--restricted`.

**Đào sâu:** [FAQ 09 — bảo mật & riêng tư](09-bao-mat-quyen-rieng-tu.md) · [bài 10 — permissions & modes theo provider](../01-huong-dan-su-dung/10-permissions-modes-availability.md)

> **Tóm gọn 1 câu:** `--dangerously-skip-permissions` là tháo toàn bộ ổ khóa ra một lần — chỉ làm trong nhà kho trống không mang gì giá trị (CI sandbox), tuyệt đối không phải nhà đang ở.

---

## Vẫn lỗi thì sao? (permissions/modes)

1. `/permissions` — xem merged rules (deny ẩn? managed thắng?).
2. `/hooks` — có hook deny nào chặn không (hook thắng bypass).
3. `claude doctor` + `/status` — version cũ? duplicate install? mode `auto` có tùy bản/provider.
4. Trust dialog — frontmatter hooks project cần trust folder (xem [FAQ 05 câu 2](05-hooks-faq.md#2-folder-đã-trust-chưa)).
5. `/debug` — session vẫn lạ → chẩn đoán sâu; `/bug` kèm `/status` + `claude doctor`.

> 📄 **Code ví dụ:** [`examples/07-van-loi-thi-sao-permissions-modes.sh`](examples/07-van-loi-thi-sao-permissions-modes.sh)

**Tham khảo chéo:** [lệnh `/permissions`](../01-huong-dan-su-dung/commands/model-mode/permissions/README.md) · [lệnh `/hooks`](../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md) · [FAQ 05](05-hooks-faq.md) (hook vs rule) · [FAQ 09](09-bao-mat-quyen-rieng-tu.md) (bảo mật) · [FAQ 10](10-ci-sdk-routines-web.md) (CI headless)

> Mẹo 1 dòng: _merged xem ở /permissions, hook deny thắng bypass, và bypass chỉ sống trong CI sandbox._
