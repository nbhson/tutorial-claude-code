---
paths: ["apps/mobile/**", "*.swift"]
---

# Mobile Swift rules (áp dụng mọi file dưới `apps/mobile/**` và `*.swift`)

Ba rule ngắn dưới đây là "nếp nhà" cho toàn bộ code Swift trong repo — ai đặt tay vào file `*.swift` đều phải theo.

- UI dùng SwiftUI, không UIKit trừ khi cần perf và có comment lý do.
- Mọi string user-visible qua Localizable, không hardcode.
- Test file đặt cạnh source: `<Ten>Tests.swift` trong cùng module.

> **Tóm gọn 1 câu:** SwiftUI cho UI, chữ nào hiện ra màn hình phải qua Localizable, và test luôn nằm cạnh source cùng module.
