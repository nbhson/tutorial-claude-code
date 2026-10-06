# /init — Quét codebase, sinh CLAUDE.md + settings chuẩn cho repo mới

> Loại Built-in · Nhóm Code & Repo · Nguy hiểm Không (chỉ đọc repo + sinh file docs/settings; có ghi file mới nhưng là file docs — review trước khi commit)

> Nói nôm na: `/init` là "lễ nhập trạch" cho repo: Claude Code đi bộ toàn bộ codebase (cấu trúc thư mục, package.json, git history, docs), rồi sinh `CLAUDE.md` (luật dự án: lệnh build/test, convention, việc cấm) + gợi ý `settings.json` baseline. Từ đó mọi session sau khỏi hỏi lại "chạy test bằng gì?".

## Khi nào dùng

- Dùng /init khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng /init **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /init thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/init`
`/init <gợi ý>`
`CLAUDE_CODE_NEW_INIT=1`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: đứng root, init kèm gợi ý sơ bộ từ README
/init Tôi là người mới. Quét repo, sinh CLAUDE.md gồm: lệnh dev/build/test,
cấu trúc thư mục, và 5 việc cấm làm (nếu phát hiện được từ config).
```

Kết quả mong đợi:

- Claude trả đúng việc của /init (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/init` sinh lệnh test sai (`npm test` trong khi dùng pnpm) | Đoán từ package.json thiếu scripts, hoặc monorepo nhiều package | Sửa tay CLAUDE.md 1 dòng; lần sau `/init` kèm gợi ý rõ package manager |
| CLAUDE.md quá dài/dài dòng 200 dòng | Repo lớn + model verbose | Bảo "rút gọn còn 60 dòng, chỉ giữ lệnh + cấm + cấu trúc" |
| Init ở nhầm thư mục (sinh CLAUDE.md ở `~/`) | Quên `cd` vào repo | Xóa file nhầm, `cd` đúng repo, `/init` lại |

## Tham khảo

- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../plan/README.md](../../model-mode/plan/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- [../diff/README.md](../../code-repo/diff/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /init sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
