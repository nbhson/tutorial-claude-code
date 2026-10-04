# Security guidance — MẪU (copy về .claude/claude-security-guidance.md rồi điền)

> Mẫu threat model + checklist cho plugin security-guidance (bài 15).
> KHÔNG secrets thật trong file này — chỉ tên env + quy tắc.

## 1. Threat model (điền cho repo bạn)

- Data nhạy cảm: PII users (bảng users), STRIPE_SECRET_KEY, JWT_SECRET.
  Nằm ở env nào? Ai được đọc? (liệt kê tên env, KHÔNG paste giá trị)
- Attack surface: public API `/auth/*`, webhook `/stripe/*`, admin `/admin/*`,
  file upload `/upload/*`.
- Không tin: mọi input client, webhook raw body, issue/PR text (prompt-injection).
- Hậu quả ưu tiên: rò PII > mất tiền (payments) > downtime > deface.
- Ghi rõ "vùng cấm": file/thư mục nào agent KHÔNG BAO GIỜ được đọc/ghi
  (vd: `infra/secrets/`, `*.pem`, prod Terraform state).

## 1b. Quy ước severity (dùng chung cho rules + review)

- critical: secret/key lộ, RCE, auth bypass — BLOCK, fix ngay trong turn này.
- high: injection có điều kiện, SSRF, log lọt PII — fix trước commit.
- medium: TODO security, dep cũ, thiếu rate-limit — tạo issue, fix trong tuần.
- low: style/naming liên quan security — góp ý, không block.

## 2. Checklist per-edit (layer 1 — mỗi lần sửa)

- [ ] Không secret hardcode — key vào env + secret manager, không paste vào code.
- [ ] SQL/query parameterized? (grep `+ req.` / f-string trong query builder)
- [ ] Auth check ở caller chưa? (đừng tin comment "đã check ở trên" — đọc code)
- [ ] Log có lọt PII/token? (mask email, token, thẻ trước khi log)
- [ ] Redirect/SSRF: URL ngoài có allowlist? (chặn IP nội bộ/metadata endpoint)
- [ ] Upload: check type + size + quét? (không tin Content-Type client gửi)
- [ ] Crypto: không tự chế — dùng lib chuẩn, random từ CSPRNG.

## 3. Checklist commit/push (layer 3 — fresh context review)

- [ ] Diff có file .env/key/cert/credentials? → BLOCK, không thương lượng.
- [ ] Secret từng tồn tại trong git history? (scan cả history, không chỉ HEAD)
- [ ] Migration có xóa cột/table? → cần approve DBA/giáo viên.
- [ ] Endpoint mới có rate-limit + auth? (kèm test chứng minh 401 khi thiếu token)
- [ ] Findings layer 1/2 còn critical/high? → fix hết mới push.
- [ ] Reviewer chạy fresh context (không tự chấm bài mình — bài 15 mục 2.4).

## 4. False positive log (ghi để tune, không xóa rule bừa)

| Ngày | Rule | File | Vì sao oan | Fix (thu hẹp scope/hạ severity/allowlist) |
|---|---|---|---|---|
| 2026-.. | aws-key | fixtures/ | key fake trong test | trừ `fixtures/**` khỏi rule |
| (ghi tiếp) | | | | |

## 5. Kill switches (mở khi cần, bật lại trong ngày)

- `SECURITY_GUIDANCE_DISABLE_PER_EDIT=1` — tắt layer 1 (tên chính xác xem README plugin).
- `SECURITY_GUIDANCE_DISABLE_END_TURN=1` — tắt layer 2.
- `SECURITY_GUIDANCE_DISABLE_PRE_PUSH=1` — tắt layer 3.
- `SECURITY_GUIDANCE_DISABLE_ALL=1` — master. Tắt là nợ — ghi lý do + deadline.
- Debug: `claude --debug-file /tmp/sec-debug.log` rồi tìm hook/pattern/git/auth.
- Debug theo layer: layer 1 im? (file patterns load? JSON/YAML lỗi dòng mấy?) —
  layer 2 im? (có phải git repo? auth còn hạn?) — layer 3 im? (hook pre-push
  có đăng ký? reviewer có fresh context?).
- Sau mỗi lần sửa patterns: validate JSON/YAML + viết 1 negative test
  (bài 16 mục 8) chứng minh rule mới bắt được trước khi tin nó.
