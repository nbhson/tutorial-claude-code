# 09 — Plugins và marketplaces: đóng gói cho team

> **Bài này cho ai:** dev đang giữ `.claude/` trong 1 repo và muốn chia sẻ skills, hooks, agents, MCP cho nhiều repo hoặc cả team.
> **Cần gì trước:** đã cài và đăng nhập Claude Code ([01](./01-cai-dat-va-xac-thuc.md)); nên lướt [05 — Skills](./05-skills-custom-commands.md) và [07 — Hooks](./07-hooks-tu-dong-hoa.md).
> **Đọc xong bạn làm được:** dùng `/plugin` + bộ lệnh `claude plugin ...` để tìm/cài/đánh giá plugin; quyết định khi nào cần plugin vs commit `.claude/`; tự viết plugin từ zero và publish lên marketplace; review plugin người khác trước khi cài.
> **Thời gian:** ~35 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na | Ví dụ |
|---|---|---|
| Plugin | Bộ đóng gói trọn gói: skills + agents + hooks + MCP (+ LSP) — cài 1 lần cả team giống nhau | `/plugin` → Install from path `./acme-standard` |
| Marketplace | Cái kệ chứa nhiều plugin, liệt kê trong `marketplace.json` | Add repo `git@github.com:acme/claude-plugins.git` rồi browse |
| `plugin.json` | Tờ khai hàng của plugin: tên, version, skills/hooks/MCP nào được nạp | `.claude-plugin/plugin.json` |
| Namespaced | Skill của plugin gọi theo `tên-plugin:tên-skill` — 2 plugin cùng tên không đè nhau | `/acme-standard:deploy` |
| `${CLAUDE_PLUGIN_DIR}` | Biến trỏ tới folder plugin đã cài, tránh hardcode path | `"command": "${CLAUDE_PLUGIN_DIR}/hooks/lint-on-write.sh"` |
| Mods | Plugin sửa giao diện Claude Code — yêu cầu tin cậy cao hơn, chỉ cài bản đã audit | Xem [16 — Mods](./16-mods-bao-mat-validate.md) |

---

## 1. Plugin là gì, vì sao team cần?

Mục này trả lời 2 câu: plugin thực chất là gì, và vì sao team nên quan tâm thay vì cứ copy `.claude/` từng repo.

Plugin là 1 unit cài được, bundle: **skills + hooks + subagents + MCP servers (+ LSP servers)** — thay vì mỗi teammate setup tay 4 thứ, cài 1 phát đồng bộ. Hãy hình dung plugin như "combo bữa trưa": thay vì gọi từng món (skill, hook, agent, MCP) rồi dọn lại đĩa mỗi repo, bạn order 1 set và mọi người ăn cùng menu.

```text
acme-standard/
  .claude-plugin/plugin.json   # manifest: khai skills/agents/hooks/mcpServers
  skills/deploy/SKILL.md       # → /acme-standard:deploy (namespaced)
  agents/explorer.md           # subagent kèm
  hooks/block-main-push.sh     # guard kèm, dùng ${CLAUDE_PLUGIN_DIR}
  .mcp.json                    # MCP kèm, dùng ${VAR} không secrets
```

`.claude/` commit theo repo chỉ giải quyết 1 repo. Team 10 repos + onboarding người mới mỗi tháng → mỗi repo setup lại = drift. Drift giống như mỗi chi nhánh một bản sao công thức nấu ăn chép tay: thời gian nào bản nào lệch nhau một chút. Plugin giải quyết cross-repo:

```text
Không plugin:  teammate mới → clone 5 repos → mỗi repo /mcp setup tay + copy hooks + hỏi "skill deploy ở đâu?"
Có plugin:     teammate mới → /plugin install acme-standard → 5 repos đều có /acme-standard:deploy, hooks guard, agents.
Update:        bump plugin version 1 nơi → cả team sync (thay vì sửa 5 repos).
```

- Skills của plugin **namespaced**: `/my-plugin:review` → nhiều plugin cùng tồn tại.
- Thêm `.claude-plugin/plugin.json` vào folder skill → nó load như plugin tên `@skills-dir`
  (trong project `.claude/skills/` cần accept workspace trust dialog trước).

**Kiểm tra nhanh:** install plugin từ path local rồi mở session mới: gõ `/` thấy lệnh `/acme-standard:deploy`; `/hooks` và `/mcp` thấy hooks/MCP đã load.

---

**Kiểm tra nhanh:** install plugin từ path local rồi mở session mới: gõ `/` thấy lệnh `/acme-standard:deploy`; `/hooks` và `/mcp` thấy hooks/MCP đã load.

> **Tóm gọn 1 câu:** Plugin là "trọn gói ăn liền" cho setup Claude Code — cài 1 phát cả team giống nhau, đỡ copy tay từng repo từng người.

---

## 2. Dùng plugin manager

Mục này hướng dẫn cách cài, thử và gỡ plugin bằng chính giao diện `/plugin` và CLI — đọc để biết luồng "tiếp nhận một plugin mới" từ đầu đến cuối.

```text
/plugin   → Discover / Browse / Manage (alias: /plugins)
```

Màn hình Browse/Discover hiện trước: commands, agents, skills, hooks, MCP/LSP servers của plugin — đọc kỹ trước khi cài (nhất là hooks: nó sẽ chạy code trên máy bạn).

### 2.1. Walkthrough cài plugin (10 phút)

```text
Bước 1: /plugin → tab Discover (marketplaces đã add) / Browse (installed).
Bước 2: Chọn plugin → đọc: skills/hooks/MCP/agents nào?
        → ĐẶC BIỆT đọc hooks (chạy shell trên máy bạn) + MCP (gọi ra ngoài).
Bước 3: Install → mở session MỚI (plugin load lúc start).
Bước 4: Gõ "/" → test 1 lệnh namespaced (xem list: gõ "/" hoặc /plugin list). Bước 5: /hooks + /mcp → xác nhận đã load.
Bước 6: Không hợp → /plugin → Manage → Disable → Uninstall.
```

### 2.2. Lệnh CLI cho plugin (chạy ngoài session)

> 📄 **Code ví dụ:** [`examples/01-2-2-lenh-cli-cho-plugin-chay-ngoai.sh`](examples/01-2-2-lenh-cli-cho-plugin-chay-ngoai.sh)

> Gõ `claude plugin --help` để xem cách gọi đúng ở bản của bạn — version khác nhau thì lệnh hiện khác nhau.

### 2.3. Nguồn cài được (2026)

Ngoài path local và git URL, plugin còn load được từ:

- **File `.zip`** — tiện share plugin qua artifact/attachment không cần repo.
- **`--plugin-url`** — cài thẳng từ URL khi khởi động/CLI, không cần add marketplace trước, vd `claude --plugin-url https://example.com/acme-standard.zip`.

> Dù nguồn nào — path, git, .zip hay URL — đều phải qua checklist trust ở mục 6 trước khi tin. Nguồn lạ càng phải sandbox test.

**Kiểm tra nhanh:** chạy đủ Bước 1–6 → plugin nằm trong `/plugin` → Manage (enabled) và gỡ được bằng Disable → Uninstall.

> **Tóm gọn 1 câu:** `/plugin` là cửa hàng của Claude Code — xem hàng, cài, mở session mới để load, không ưng thì Disable gỡ sạch.

---

## 3. Khi nào build plugin, khi nào không cần?

Mục này giúp bạn tránh "vung tay cầm chừng": plugin có chi phí riêng, không phải tình huống nào cũng đáng làm.

### 3.1. Chọn theo tình huống

| Tình huống | Chọn | Ví dụ |
|---|---|---|
| 1–2 skills nội bộ, 1 repo | `.claude/skills/` commit thẳng | Skill deploy của 1 project |
| Bộ setup chuẩn (skills+hooks+agents+MCP) dùng nhiều repo | Plugin | `acme-standard` cho 10 repos |
| Share công khai / cross-org | Plugin + marketplace | Plugin open-source review chuẩn |
| Chỉ personal, không share | `~/.claude/skills/` | Preferences cá nhân |

> **Cách đọc bảng này:** quét cột "Tình huống" để tìm đúng hoàn cảnh của bạn, rồi lấy đáp án ở cột "Chọn" — nếu hoàn cảnh của bạn nằm ở dòng 1 hoặc dòng cuối, bạn không cần đọc tiếp phần plugin.

Ngưỡng build plugin: team ≥3 repos hoặc onboarding ≥1 người/tháng. Dưới ngưỡng → commit `.claude/skills/` thẳng rẻ hơn (không tốn repo riêng, version, publish).

### 3.2. Nếu KHÔNG làm plugin thì chọn cách nào?

| Nhu cầu | Giải pháp nhẹ hơn | Vì sao |
|---|---|---|
| 1 repo, 2 skills | `.claude/skills/` commit thẳng | Plugin overhead không đáng |
| Việc chạy theo lịch | Routines / `/schedule` (bài 12) | Plugin không chạy định kỳ |
| Hành động deterministic | Hooks trong repo (bài 07) | Hook repo đơn giản hơn nếu chỉ 1 repo |
| Quy trình CI | `claude -p` jobs (bài 12) | Plugin sống trong session, CI cần non-interactive |

Ví dụ plugin hay gặp: `security-review` (skill review + subagent + hook guard), code-intelligence plugins cho typed languages, frontend-polish (vd Impeccable: `/audit /polish /distill /critique...` chống "AI slop").

Ví dụ plugin hay gặp: `security-review` (skill review + subagent + hook guard), code-intelligence plugins cho typed languages, frontend-polish (vd Impeccable: `/audit /polish /distill /critique...` chống "AI slop").

> **Tóm gọn 1 câu:** Plugin có "phí vận hành" riêng (repo, version, publish) — dưới ngưỡng vài repos thì commit `.claude/` thẳng vẫn rẻ hơn.

---

## 4. Viết plugin từ zero

Mục này là bản vẽ dựng plugin tay từng bộ phận: folder đặt sao, manifest ghi gì, từng thành phần sống ở đâu. Đọc xong bạn tự dựng được một plugin tối thiểu.

### 4.1. Cấu trúc folder chuẩn

```text
acme-standard/                  # repo plugin (git riêng, version riêng)
  .claude-plugin/
    plugin.json                 # BẮT BUỘC: manifest
    marketplace.json            # (optional) nếu publish marketplace
  skills/
    deploy/SKILL.md             # → /acme-standard:deploy (namespaced)
    review-pr/SKILL.md
  agents/
    explorer.md                 # subagents kèm
    security-reviewer.md
  hooks/
    block-main-push.sh
    lint-on-write.sh
  .mcp.json                     # MCP servers kèm (dùng env placeholders!)
  README.md                     # install + usage + trust notes
```

### 4.2. `plugin.json` mẫu hoàn chỉnh (copy-paste)

> 📄 **Code ví dụ:** [`examples/02-4-2-plugin-json-mau-hoan-chinh-copy.json`](examples/02-4-2-plugin-json-mau-hoan-chinh-copy.json)

> `${CLAUDE_PLUGIN_DIR}` = folder plugin (tương tự `${CLAUDE_SKILL_DIR}` cho skill). Đừng hardcode path tuyệt đối — plugin cài ở máy khác path khác.

### 4.3. Từng thành phần

```markdown
# skills/*/SKILL.md — như skill thường (bài 05), nhớ namespaced: /acme-standard:deploy.
# description vẫn quyết định auto-trigger.
# agents/*.md — như agent thường (bài 06), nhưng BỊ BỎ QUA hooks/mcpServers/permissionMode
#   trong frontmatter (copy ra .claude/agents/ nếu cần).
# hooks/*.sh — như hook thường (bài 07), dùng ${CLAUDE_PLUGIN_DIR} cho path.
# .mcp.json — env placeholders ${VAR}, KHÔNG secrets (bài 08).
```

> 📄 **Code ví dụ:** [`examples/03-4-3-tung-thanh-phan.sh`](examples/03-4-3-tung-thanh-phan.sh)

**Kiểm tra nhanh:** `/plugin` → Manage → Install from path `./acme-standard` cài được; session mới gõ `/` thấy lệnh namespaced, `/hooks` thấy hook vừa copy.

> **Tóm gọn 1 câu:** Plugin chỉ là một folder có đúng quy ước — `plugin.json` là giấy khai sinh, còn skills/hooks/agents/MCP thì đặt đúng tủ của chúng.

---

## 5. Publish + marketplace

Mục này nói về đường đi của plugin từ máy bạn ra thế giới: share mức nào cho ai, và update bằng cách nào để không gãy team.

### 5.1. 3 cấp share

| Cấp | Cách | Khi nào |
|---|---|---|
| **Path local** | `/plugin install ./acme-standard` | Dev/test plugin đang viết |
| **Git URL / .zip / --plugin-url** | `/plugin install git@github.com:...` hoặc `.zip`/URL | Team nội bộ (private repo), share không cần repo |
| **Marketplace** | Add marketplace URL → Discover → Install | Org nhiều plugins / công khai |

> **Cách đọc bảng này:** 3 cấp xếp từ "gần nhất" xuống "ra công khai" — bạn đang ở cấp nào thì đọc đúng dòng đó, càng xuống dưới càng cần chuẩn bị kỹ (version, review).

> 📄 **Code ví dụ:** [`examples/04-5-1-3-cap-share.sh`](examples/04-5-1-3-cap-share.sh)

> 📄 **Code ví dụ:** [`examples/05-5-1-3-cap-share.json`](examples/05-5-1-3-cap-share.json)

### 5.2. Versioning + update flow

```text
1. Bump version trong plugin.json (semver: breaking → major).
2. CHANGELOG entry: skills nào thêm/sửa? hooks nào đổi hành vi? (hooks đổi = highlight đỏ).
3. Tag git (vd acme-standard-v1.1.0).
4. Thông báo team: /plugin → Manage → Update. Teammate mở session mới để load bản mới.
5. Breaking hooks change → pin version cũ cho repos chưa sẵn sàng (đừng force update).
```

> **Tóm gọn 1 câu:** Share plugin như giao hàng 3 cấp (test local → team nội bộ → công khai), còn update thì bump version 1 nơi để cả team đồng bộ.

---

## 6. Trust: checklist review + sandbox trước khi cài

Mục này là "kiểm hàng trước khi nhận": vì hook của plugin chạy thẳng shell trên máy bạn, đừng cài thứ nào chưa đọc code.

Hooks của plugin chạy shell ngay trên máy bạn → cửa chắn là "không tin ai cho tới khi đọc code".

- Plugin subagents **bị bỏ qua** `hooks`/`mcpServers`/`permissionMode` → cần thì copy agent ra `.claude/agents/` hoặc `~/.claude/agents/`.
- Org có thể quản lý plugin qua managed/server policy settings (Team/Enterprise — [bài 10](./10-permissions-modes-availability.md)).
- **Mods khác 1 bậc:** sửa giao diện Claude Code, yêu cầu tin cậy cao hơn plugin thường — chỉ cài bản đã audit ([bài 16](./16-mods-bao-mat-validate.md)).
- Trước khi cài nên chạy: `claude plugin eval` (đánh giá), `claude plugin validate <mod>` (soi hooks/calls), `claude plugin details` (token cost — plugin tốn context mọi turn, nặng thì tách nhỏ).

### 6.1. Checklist review plugin trước khi cài

- [ ] Đọc `plugin.json`: skills/agents/hooks/MCP/LSP nào sẽ load?
- [ ] Đọc từng hook `.sh`: có `rm -rf`? có `curl | bash`? có exfiltrate (`curl` gửi file đi)?
- [ ] MCP servers: có server lạ gọi URL ngoài? Credentials qua env?
- [ ] Skills: có `allowed-tools` quá rộng? Có dặn làm việc nguy hiểm (deploy prod auto)?
- [ ] Nguồn: marketplace chính thức / org private / cá nhân lạ? (lạ → sandbox test trước)
- [ ] Version pinned? (tránh auto-update breaking giữa sprint)

### 6.2. Sandbox test (6 bước, ~10 phút)

> 📄 **Code ví dụ:** [`examples/06-6-2-sandbox-test-6-buoc-10-phut.sh`](examples/06-6-2-sandbox-test-6-buoc-10-phut.sh)

### 6.3. Checklist production-ready (trước khi announce team)

- [ ] plugin.json version + skills/agents/hooks/MCP đầy đủ, paths dùng `${CLAUDE_PLUGIN_DIR}`.
- [ ] Mọi hook `.sh` đã review (6.1) + sandbox test (6.2) pass.
- [ ] `.mcp.json` không secrets (grep `sk-|password|token` trống), dùng `${VAR}`.
- [ ] README có install (path/git/.zip/marketplace) + trust notes + version pinning.
- [ ] 1 teammate cài từ git URL thành công trên máy khác.
- [ ] CHANGELOG entry + git tag (`<plugin>-vX.Y.Z`).
- [ ] Lịch update: cuối sprint, không giữa sprint (trừ security fix).

> **Tóm gọn 1 câu:** Cài plugin = mời người lạ vào bếp — checklist review + sandbox test là bắt tay và giấy tờ trước khi mở cửa.

---

## 7. Bẫy thường gặp

Mục này tổng hợp những vấp thực tế khi dùng plugin, kèm cách xử lý — đọc khi cài xong mà có gì đó "không ra như mong đợi".

| Pitfall | Fix |
|---|---|
| Cài plugin lạ, hook xóa file | Checklist 6.1; test sandbox/container trước khi cài |
| 2 plugins cùng tên skill → gọi nhầm | Luôn gọi `/plugin:skill` đầy đủ, không gọi tắt |
| Plugin agent hooks không chạy | Bị bỏ qua theo thiết kế — copy agent ra `.claude/agents/` |
| Update giữa sprint gãy workflow | Pin version, update cuối sprint, đọc CHANGELOG hooks |
| `.claude/skills/` cần trust dialog | Accept trust dialog 1 lần; CI `-p` không trusted → test riêng |
| Plugin phình (20 skills) → context nặng | Tách plugin nhỏ theo domain (frontend/backend/security) |
| Skill plugin gọi thế nào? | Namespaced `/plugin:skill` — gõ `/` hoặc `/plugin list` để thấy list |
| Secrets trong plugin? | Cấm — MCP dùng `${VAR}` placeholders, secrets ở env máy/cloud (bài 08) |

> **Cách đọc bảng này:** cột "Pitfall" là triệu chứng bạn đang gặp, cột "Fix" là liều thuốc — tìm đúng triệu chứng rồi làm đúng fix, không cần đọc theo thứ tự.

> **Tóm gọn 1 câu:** Phần lớn bẫy plugin thuộc 3 nhóm: gọi tên không namespaced, tin plugin chưa review, và quên rằng plugin agent/hooks có luật riêng — bẫy nào cũng có fix trong bảng.

---

## 8. Bài tập thực hành + link chéo

**Bài 1 (15 phút):** `/plugin` → Browse 3 plugins có sẵn. Điền bảng: skills/hooks/MCP/agents gì? Cài cái nào?

**Bài 2 (40 phút):** Build plugin `my-standard` từ zero (mục 4): 1 skill + 1 hook + plugin.json. Install từ path local, test namespaced command. Review trust checklist (6.1) như thể bạn là người ngoài, rồi publish git repo private và install từ máy thứ 2.

**Link chéo:** [00 — Tổng quan](./00-tong-quan-claude-code.md) · [05 — Skills](./05-skills-custom-commands.md) (namespaced, `@skills-dir`) · [06 — Subagents](./06-subagents-agent-teams-parallel.md) (plugin agents bị bỏ qua hooks) · [07 — Hooks](./07-hooks-tu-dong-hoa.md) (`${CLAUDE_PLUGIN_DIR}`) · [08 — MCP](./08-mcp-ket-noi-cong-cu-ngoai.md) (env placeholders) · [10 — Permissions](./10-permissions-modes-availability.md) (managed policy) · [12 — SDK & CI](./12-agent-sdk-ci-cd-automation.md) (`claude -p` thay plugin khi cần chạy nền) · [16 — Mods](./16-mods-bao-mat-validate.md) (audit trước khi cài).
