# /setup-bedrock — Wizard cắm Claude Code vào AWS Bedrock

> Loại Built-in · Nhóm Provider & Cloud · Nguy hiểm Thấp (chỉ ghi config + test kết nối; nhưng Có nếu bạn dán access key vào file rồi commit — dùng IAM role/SSO thay vì key cứng)

> Nói nôm na: `/setup-bedrock` là wizard cấu hình Claude Code chạy qua AWS Bedrock: hỏi region, model entitlement, auth (IAM role/SSO/keys), ghi config rồi test 1 câu chào. Sinh ra cho team đã ở AWS (quỹ tín dụng, compliance, VPC) muốn xài Claude qua hạ tầng nhà. Hiểu `/setup-bedrock` là hiểu "đấu dây từ Claude Code vào ổ điện AWS".

## Khi nào dùng

- Dùng /setup-bedrock khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /setup-bedrock **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /setup-bedrock thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/setup-bedrock`
`/setup-bedrock --check`
`/status`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Máy đã có AWS CLI + SSO org:
aws sso login --profile team-dev
# → browser SSO OK

/setup-bedrock
# → region: ap-southeast-1 [Yes]
# → auth: SSO profile team-dev [Yes]
# → model: sonnet (đã enable) [Yes]
```

Kết quả mong đợi:

- Claude trả đúng việc của /setup-bedrock (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| "Model not available in region" dù auth OK | Sai region hoặc model chưa enable trong console | Console → Bedrock → Model access → Enable; chọn region có Claude |
| "ExpiredToken / InvalidClientTokenId" | Key cũ 90 ngày / SSO session hết hạn | `aws sso login` lại; key cứng thì chuyển SSO/role cho bền |
| "AccessDenied: not authorized bedrock:InvokeModel" | IAM policy thiếu quyền | Xin policy `bedrock:InvokeModel` trên ARN model; test bằng `aws bedrock list-foundation-models` |

## Tham khảo

- [../setup-vertex/README.md](../../auth-settings/setup-vertex/README.md)
- [../login/README.md](../../auth-settings/login/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /setup-bedrock sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
