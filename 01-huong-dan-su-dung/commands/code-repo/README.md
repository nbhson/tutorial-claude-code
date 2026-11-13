# /code-repo — nhóm 17 lệnh làm việc với code và repo

> **Loại:** index nhóm lệnh · **Nhóm:** Code & Repo · **Mức rủi ro:** trung bình (đụng code thật, có lệnh tốn quota)
> **Nói nôm na:** nhóm này là nơi Claude "xem diff, review, chạy thật, chia việc song song" trên repo của bạn. Lệnh /batch, /loop chạy ẩu sẽ tốn quota thật, nên luôn đọc mức rủi ro trong bảng lệnh trước khi gõ.

## Khi nào dùng

- Bạn đang viết code và cần xem /diff sau mỗi bước, review bằng /code-review, hoặc chứng minh bằng /verify (build + chạy thật).
- Bạn cần chia task lớn thành nhiều nhánh song song bằng /batch, /subtask — dùng khi 1 mạch không kịp, không phải chạy ẩu làm thiệt hại quota.
- Bạn muốn khởi tạo CLAUDE.md cho repo mới bằng /init, hoặc chạy app local bằng /run — làm trước khi bắt đầu task, không làm giữa chừng.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

Kiểm tra lệnh có ở máy bạn không: mở session, gõ `/` rồi gõ tiếp chữ đầu lệnh — version/provider khác nhau hiện lệnh khác nhau.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Bạn vừa để Claude sửa 1 file, muốn xem nó đổi gì:

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

- Mong đợi: panel diff hiện từng hunk thay đổi, bạn bấm chọn dòng nào thì prompt tiếp được dòng đó (feature ≥2.1.260, terminal ≥110 cột).
- Kiểm tra (≤30 giây): xem diff có đúng chỗ bạn muốn không; nếu panel không hiện, xem terminal có đủ 110 cột và repo có phải git repo không.

## Lỗi thường gặp

Mục này nói về những sự cố hay gặp khi dùng cả nhóm lệnh: đọc để biết triệu chứng → nguyên nhân → cách xử lý, đừng mò mẫm.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Hook pre-commit "im": không chạy, hoặc không chặn được | Cấu hình hook trong settings sai, hoặc bản của bạn chưa hỗ trợ hook mới | Gõ `/hooks` (nhóm knowledge-system) xem cấu hình, đọc output hook trong terminal; muốn hook lỗi/timeout thì chặn hẳn, bật `onFailure: "block"` (≥2.1.295) |
| Session "hờn", model lặp lại 1 lỗi, context đầy giữa task | Context window đầy; /loop hoặc /batch chạy bypass ngốn quota liên tục | Dùng /compact để nén, /context xem ai tốn context, dừng /loop khi không cần; đặt `autoCompactWindow` cho subagent (≥2.1.296) để tự compact sớm hơn |
| /subtask kẹt (subagent không về), /code-review "dễ dãi" bỏ sót | Subagent context riêng nhưng spawn ẩu; review chỉ đọc + nhận xét, không verify | Chạy /verify (build + chạy thật) sau review; chia /subtask nhỏ hơn; /tasks để kill job kẹt |

> **Cách đọc bảng này:** tìm dòng khớp triệu chứng bạn gặp ở cột "Triệu chứng", đọc ngang sang "Vì sao" rồi "Cách sửa" — xử lý được trong vài phút.

## Bộ 3 phải nhớ

> /diff duyệt từng hunk sau mỗi bước | /verify build + chạy thật lấy output | /batch chia worktree song song

## Các lệnh (17)

Mục này là danh mục đầy đủ 17 lệnh của nhóm — coi như thực đơn của nhà hàng: chọn món ở đây rồi nhảy sang file riêng của lệnh đó.

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/batch](./batch/README.md) | Có nếu ẩu | Chia nhiều worktree/subagent chạy song song; coi chừng conflict + tốn quota |
| [/btw](./btw/README.md) | Không | Hỏi nhanh một câu phụ, không sửa file, không ghi history |
| [/code-review](./code-review/README.md) | Không | Review tự động, mặc định chỉ đọc + báo cáo |
| [/design-sync](./design-sync/README.md) | Thấp | Đọc design rồi sinh/sửa code UI (version-gated) |
| [/diff](./diff/README.md) | Không | Xem diff thay đổi, kính lúp bắt buộc sau mỗi bước thực thi |
| [/fewer-permission-prompts](./fewer-permission-prompts/README.md) | Thấp | Đề xuất allowlist read-only để bớt bị hỏi quyền |
| [/init](./init/README.md) | Không | Đọc repo rồi sinh CLAUDE.md + docs/settings |
| [/loop](./loop/README.md) | Trung bình | Chạy lặp một task nhiều vòng; coi chừng tốn quota khi auto/bypass |
| [/pr-comments](./pr-comments/README.md) | Không | Xử lý comment PR: sửa code theo góp ý (đã gỡ v2.1.91) |
| [/radio](./radio/README.md) | Thấp | Hỏi-đáp + nghe realtime trong session (version-gated) |
| [/review](./review/README.md) | Không | Review code trong context phiên hiện tại, chỉ đọc + nhận xét |
| [/run](./run/README.md) | Thấp | Chạy app local theo recipe; tốn port/CPU, có thể ghi DB dev |
| [/run-skill-generator](./run-skill-generator/README.md) | Không | Sinh file SKILL.md hướng dẫn chạy app |
| [/security-review](./security-review/README.md) | Không | Quét bảo mật, chỉ đọc + báo cáo |
| [/subtask](./subtask/README.md) | Thấp | Giao việc phụ cho session con trong cùng session (≥2.1.212) |
| [/ultrareview](./ultrareview/README.md) | Không | Review sâu trong sandbox cách ly; tốn nhiều quota nhất |
| [/verify](./verify/README.md) | Thấp | Build + chạy thật lấy output làm bằng chứng |

> **Cách đọc bảng này:** mỗi dòng một lệnh; cột "Mức rủi ro" cho biết có nên cẩn trọng không (chạy ẩu là tốn quota thật), cột "Một dòng" đủ để quyết định có đọc tiếp file riêng hay không.

## Sơ đồ quyết định (30 giây)

```text
Cần gì? -> Nhóm này cho gì? -> Lệnh nào?
Đọc 3 lệnh trong "Bộ 3" trước, còn lại tra khi cần.
Gõ / trong session để xem lệnh nào hiện ở máy bạn.
```

## Cách dùng nhóm này cho đúng

> 📄 **Code ví dụ:** [`examples/03-cach-dung-nhom-nay-cho-ung.sh`](examples/03-cach-dung-nhom-nay-cho-ung.sh)

> **Tóm gọn 1 câu:** nhóm này là bộ dụng cụ làm việc với code thật — `/diff` soi từng bước, `/verify` lấy bằng chứng sống, `/batch` chia việc song song, còn quota là nguyên liệu phải dùng có kế hoạch.

## Tham khảo

- [← Về index tất cả lệnh](../README.md)
- [04 — slash commands toàn tập](../../04-slash-commands-toan-tap.md)
- [Nhóm session-context](../session-context/README.md) · [Nhóm knowledge-system](../knowledge-system/README.md)

> Mẹo 1 dòng: _luôn /diff + /verify sau mỗi bước, đừng tích nhiều bước mới kiểm tra — lỗi 1 bước nhân lên các bước sau._
