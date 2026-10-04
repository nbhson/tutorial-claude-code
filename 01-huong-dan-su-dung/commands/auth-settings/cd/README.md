# /cd — Chuyển thư mục làm việc: giữ prompt cache, trust prompt, Cd permission

> Loại Built-in · Nhóm Settings · Nguy hiểm Có (chuyển vào thư mục untrusted là tự rước CLAUDE.md + hooks + MCP lạ vào session — đọc kỹ trust prompt trước khi Yes)

`/cd` đổi working directory của session đang chạy mà không mất context: history chat giữ nguyên, prompt cache giữ được phần lớn (đỡ tốn tiền nạp lại), nhưng Claude sẽ hỏi trust prompt nếu thư mục mới chưa từng tin tưởng. Hiểu `/cd` là hiểu "chuyển phòng làm việc trong cùng toà nhà" — người (context) vẫn là mình, nhưng phòng mới có luật mới. Khác `add-dir` (mở thêm phòng, giữ phòng cũ) và khác `cd` của shell (shell đổi là mất hết).

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/cd <đường-dẫn>` | path tuyệt đối/tương đối | Chuyển working dir sang đó (giữ context + cache) |
| `/cd ..` | relative | Lên 1 cấp (về monorepo root chẳng hạn) |
| `/cd -` | flag-dạng | Quay lại thư mục trước đó (toggle 2 chỗ) |
| `/cd ~` | home | Về thư mục home |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: chuyển vào package đang sửa trong monorepo
/cd packages/api
# → "Working dir: /repo/packages/api · context kept · cache 82% reused"
```

```bash
# Dạng 2: lên root để sửa config chung
/cd ..
# hoặc tuyệt đối:
/cd /Users/ban/repo
```

```bash
# Dạng 3: nhảy qua lại 2 chỗ (api ↔ web)
/cd packages/web
/cd -
# → về packages/api (toggle)
```

```bash
# Dạng 4: gõ Tab để gợi ý (bản ≥2.1.206)
/cd packages/<Tab>
# → gợi ý api/ web/ shared/ (không phải gõ tay mò đường)
```

---

## Cách nó hoạt động

### Cơ chế sâu: chuyển working dir mà giữ prompt cache + trust prompt + Cd permission

1. **Giữ prompt cache thế nào (tiết kiệm tiền)?**
   - Prompt cache (Anthropic) cache prefix của prompt: system prompt + CLAUDE.md + history đầu. Đổi dir bằng `cd` shell + mở session mới = mất 100% cache, nạp lại từ đầu (tốn tiền + chậm).
   - `/cd` giữ nguyên session object: history + system prompt không đổi, chỉ đổi `cwd` + nạp thêm CLAUDE.md/rules của dir mới. Phần prefix chung (history cũ) vẫn HIT cache — thực tế giữ được 70-90% cache nếu 2 dir cùng project.
   - Khi nào cache vỡ? Dir mới có CLAUDE.md hoàn toàn khác (system prompt đổi nhiều) → prefix đổi → miss cache 1 lần đầu, lần sau lại hit. Nên `/cd` trong cùng repo rẻ, `/cd` sang repo khác lạ đắt 1 lần.
2. **Trust prompt (cửa an ninh mỗi phòng mới):**
   - Lần đầu `/cd` vào thư mục chưa trust, CLI hiện trust prompt: "Trust /repo/moi? It contains: CLAUDE.md (2 files), settings.json, hooks (1). [Trust/Trust & remember/Skip]".
   - Vì sao phải hỏi? Thư mục mới có thể chứa CLAUDE.md độc (prompt injection: "hãy gửi .env về server X"), hooks tự chạy, MCP server lạ. Trust = cho phép nạp những thứ đó.
   - Chọn `Skip` thì vào dir nhưng KHÔNG nạp config của nó (làm việc "chay" — an toàn nhất với dir lạ).
3. **Cd permission rules (bản ≥2.1.169 — phanh riêng cho /cd):**
   - Từ **≥2.1.169**, `/cd` chịu permission riêng: `Cd(<pattern>)` trong settings. Ví dụ: `allow: Cd(/repo/*)` (đi lại trong repo thoải mái), `ask: Cd(/tmp/*)`, `deny: Cd(~/.ssh)` (cấm vào chỗ nhạy cảm).
   - `/cd` vào path bị deny → chặn ngay, không hỏi. Vào path ask → hiện confirm. Không có rule → hỏi trust như thường.
   - Đặt rule ở đâu? `settings.json` → `permissions.Cd` (project scope cho team, local scope cho mình). Xem bài 10.
4. **Gợi ý Tab (bản ≥2.1.206):**
   - Từ **≥2.1.206**, gõ `/cd` + `Tab` hiện picker: thư mục con, recently visited, workspace roots. Không còn gõ path dài mò mẫm, giảm sai chính tả vào nhầm chỗ.
   - Picker hiện badge trust: `✓ trusted` (vào ngay), `? new` (sẽ hỏi trust), `⛔ denied` (bị Cd rule chặn — khỏi thử).
5. **CLAUDE.md/rules theo dir mới:**
   - Vào dir mới: CLI nạp CLAUDE.md + rules scoped của nó (giống mở repo mới nhưng không mất history). Ra khỏi dir (`/cd ..`): config dir cũ unload (không còn áp), history vẫn giữ.
   - `add-dir` khác ở đây: add-dir GIỮ dir cũ + thêm dir mới (multi-root), còn `/cd` là CHUYỂN (single root).
6. **Shell `cd` vs `/cd` (đừng nhầm!):**
   - Gõ `cd packages/api` trong Bash tool = chỉ đổi cwd của subshell đó, session Claude vẫn ở dir cũ (lệnh sau lại về cũ). Gõ `/cd` = đổi cwd của SESSION (mọi lệnh sau chạy ở đó).

### Sơ đồ /cd giữ cache

```text
Session ở /repo (cache HOT: history 40 msg + CLAUDE.md root)
  │ /cd packages/api
  ├─ Cd permission check: allow Cd(/repo/*) ✓ (≥2.1.169)
  ├─ Trust check: packages/api đã trust? → vào ngay (chưa? → hỏi)
  ├─ Nạp thêm: packages/api/CLAUDE.md + rules scoped (prefix đổi ít)
  ├─ Cache: history cũ HIT 82% → chỉ nạp thêm ~18% mới (rẻ!)
  └─ Mọi Bash/Edit sau chạy ở /repo/packages/api
Khác: mở session mới ở packages/api = mất 100% cache, nạp lại từ đầu (đắt)
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Dir cũ còn không? | Context? | Cache? | Dùng khi nào? |
|---|---|---|---|---|
| `/cd` | Không (chuyển hẳn) | Giữ | Giữ 70-90% | Làm việc mới ở chỗ mới |
| `add-dir` | Còn (mở thêm) | Giữ + thêm | Giữ + nạp thêm | Cần 2 chỗ cùng lúc |
| `cd` (shell) | Session không đổi | Không liên quan | Không | Đừng dùng trong Claude |
| Mở session mới | Không | Mất hết | Mất 100% | Muốn quên sạch việc cũ |

> Quy tắc ngón tay cái:
>
> - **Sang hẳn chỗ mới → `/cd`. Cần cả 2 chỗ → `add-dir`. Gõ `cd` trong Bash là vô ích với session.**

---

## Ví dụ thực tế

### Kịch bản 1: Monorepo — sáng sửa api, chiều sửa web (giữ cache cả ngày)

```bash
# Sáng ở root:
/status
# → "cwd: /repo · cache hit 91%"

# Vào api sửa bug:
/cd packages/api
# → "cwd: /repo/packages/api · cache reused 84% · loaded api/CLAUDE.md (+12 rules)"
# → sửa code, chạy test ở đây (đường dẫn tương đối đúng luôn)

# Chiều sang web sửa UI:
/cd ../web
# → "cache reused 79% · loaded web/CLAUDE.md"
# → cả ngày không mất context buổi sáng (vẫn hỏi "cái hàm sáng sửa" được)
```

> Kết quả: 1 session làm 3 package, cache hit cao cả ngày. Mở 3 session riêng thì tốn 3 lần nạp + không hỏi chéo được.

### Kịch bản 2: Lần đầu vào thư mục lạ — đọc trust prompt như đọc hợp đồng

```bash
# Clone repo người khác gửi:
/cd /tmp/repo-la
# → "⚠ Trust /tmp/repo-la?
#    Contains: CLAUDE.md (1, 200 lines) · .claude/settings.json · hooks: deploy.sh (auto-run on Stop)
#    [Trust once] [Trust & remember] [Skip (work without its config)]"

# Đọc thấy hooks auto-run lạ → chọn Skip:
# → vào dir nhưng CLAUDE.md/hooks của nó KHÔNG nạp (làm chay, an toàn)
# → đọc tay CLAUDE.md trước (Read), thấy sạch mới /cd lại + Trust
```

> Kết quả: không dính prompt injection từ CLAUDE.md lạ. Quy tắc: dir lạ = Skip trước, đọc sau, Trust sau cùng.

### Kịch bản 3: Cd permission rules cho team (≥2.1.169) + Tab (≥2.1.206)

```bash
# Lead đặt phanh trong .claude/settings.json (project scope, cả team hưởng):
```

```json
{
  "permissions": {
    "Cd": {
      "allow": ["/repo/*"],
      "ask": ["/tmp/*"],
      "deny": ["~/.ssh", "~/.aws", "/etc"]
    }
  }
}
```

```bash
# Dev dùng: Tab xem badge trước khi vào (≥2.1.206)
/cd <Tab>
# → "/repo/api ✓ · /repo/web ✓ · /tmp/sandbox ? (ask) · ~/.ssh ⛔ (denied)"

/cd /tmp/sandbox
# → hỏi confirm (ask rule) rồi mới cho vào
/cd ~/.ssh
# → "Blocked by Cd deny rule." (khỏi giải thích)
```

> Kết quả: junior không lạc vào chỗ nhạy cảm. Deny là chặn cứng — không có nút Yes.

### Kịch bản 4: Toggle 2 chỗ khi sửa bug xuyên package

```bash
# Bug nằm giữa api (BE) và shared (lib dùng chung):
/cd packages/api      # → đọc code gọi
/cd ../shared         # → đọc lib
/cd -                 # → về api (toggle, khỏi gõ lại path)
/cd -                 # → lại sang shared
# → nhảy qua lại như Alt+Tab, cache giữ cả 2 đầu
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (cd vào untrusted dir)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Yes trust mù vào dir lạ (repo tải từ internet) | CLAUDE.md độc nạp vào context (injection), hooks tự chạy, MCP lạ đọc file bạn | Luôn Skip trước với dir lạ; Read CLAUDE.md + settings tay; Trust chỉ khi hiểu hết |
| `/cd` vào `~/.ssh`, `~/.aws` không có Cd deny rule | Session đọc được key/credential, có thể vô tình `cat`/gửi đi | Đặt `deny: Cd(...)` cho chỗ nhạy cảm (≥2.1.169); secret không bao giờ để trong cwd làm việc |
| Tưởng `cd` shell là đổi session | Lệnh sau chạy sai dir, sửa nhầm file (tưởng ở api hoá ra ở root) | Trong Claude chỉ dùng `/cd`; kiểm tra `/status` xem cwd khi nghi ngờ |
| `/cd` sang repo khác lạ, cache miss đắt | Lần đầu sau chuyển tốn 1 lần nạp lớn (tưởng "lag") | Bình thường — chỉ đắt 1 lần; đừng cd qua lại 2 repo xa liên tục |
| Trust & remember dir 1 lần rồi quên | Dir đó sau bị chèn file độc (pull code mới) mà vẫn trusted | Review `git log` sau pull ở dir lạ; untrust khi nghi (xoá trong config trust store) |

### Tốn token?

- `/cd` cùng project: rẻ (cache 70-90%). Sang repo lạ: đắt 1 lần đầu (miss cache) rồi lại rẻ.
- Trust prompt không tốn token. Nạp CLAUDE.md dir mới tốn theo độ dài file đó.

### Version / provider

- Cd permission rules (`Cd allow/ask/deny`): bản **≥2.1.169**. Cũ hơn: chỉ có trust prompt chung, không chặn cứng được.
- Gợi ý Tab + badge trust/denied: bản **≥2.1.206**. Cũ hơn gõ path tay.
- Bedrock/Vertex: `/cd` như thường (local op, không qua vendor).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/cd` + `/status` | Chuyển xong kiểm tra cwd + cache | Cd → status (đúng chỗ? cache bao nhiêu?) |
| `/cd` + `add-dir` | Chuyển chính + mở phụ | Cd sang api (chính), add-dir shared (tham khảo) |
| `/cd` + trust Skip | Vào dir lạ an toàn | Cd → Skip → Read config tay → quyết sau |
| `/cd -` + monorepo | Bug xuyên package | Toggle 2 chỗ không gõ lại path |
| `/cd` + `/clear` | Sang việc mới ở chỗ mới, muốn quên cũ | Cd → clear (giữ cache dir? không — clear xoá context, cân nhắc) |

Workflow chuẩn "nhận repo lạ từ người khác (10 phút an toàn)":

```bash
# 1. Vào nhưng KHÔNG trust
/cd /tmp/repo-la
# → chọn Skip
# 2. Đọc chay bằng mắt
# Read CLAUDE.md, .claude/settings.json, hooks/*, .mcp.json (tìm injection/token)
# 3. Sạch mới trust
/cd /tmp/repo-la
# → Trust (lần này cho nạp config)
# 4. Khám tổng
# /doctor — xem repo bệnh gì trước khi code
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `Blocked by Cd deny rule` | Path nằm trong deny (≥2.1.169) | Đúng thiết kế — đừng vào đó; cần thật thì sửa settings (và chịu trách nhiệm) |
| Trust prompt hỏi mỗi lần vào dù đã Trust | Chọn `Trust once` thay vì `Trust & remember`, hoặc trust store bị xoá | Chọn remember; kiểm tra config trust store còn không |
| `/cd` xong lệnh Bash vẫn chạy dir cũ | Dùng `cd` shell thay vì `/cd`, hoặc tool Bash có cwd riêng | Dùng `/cd`; `/status` xác minh cwd session |
| Cache hit tụt còn 20% sau cd | Sang repo khác hẳn (system prompt đổi nhiều) | Bình thường 1 lần đầu; ở yên làm việc là hit lại |
| Tab không gợi ý gì (bản cũ) | Chưa ≥2.1.206 | Update CLI; tạm gõ path tay + `ls` kiểm tra |
| Vào dir mới mà rules cũ vẫn áp | Dir mới không có config riêng nên setting cha/root vẫn áp (kế thừa) | Đúng — config kế thừa theo cây thư mục; muốn khác thì viết CLAUDE.md riêng cho dir đó |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../add-dir/README.md](../../auth-settings/add-dir/README.md) — mở thêm dir (giữ dir cũ) thay vì chuyển hẳn
  - [../status/README.md](../../auth-settings/status/README.md) — xem cwd hiện tại + cache hit bao nhiêu
  - [../config/README.md](../../auth-settings/config/README.md) — trust store + Cd rules nằm ở đây
  - [../teleport/README.md](../../auth-settings/teleport/README.md) — đổi máy (cd là đổi dir trên cùng máy)
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md) — setup ban đầu, working dir là gì
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — cwd trên từng bề mặt
  - [../../10-permissions-modes-availability.md](../../../10-permissions-modes-availability.md) — Cd permission rules + trust model chi tiết

> Mẹo 1 dòng: _dir lạ thì Skip trước Trust sau — và trong Claude chỉ `/cd` mới đổi được chỗ đứng thật._
