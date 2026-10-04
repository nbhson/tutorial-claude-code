---
paths: ["apps/mobile/**", "*.swift"]
---

- UI dùng SwiftUI, không UIKit trừ khi cần perf và có comment lý do.
- Mọi string user-visible qua Localizable, không hardcode.
- Test file đặt cạnh source: `<Ten>Tests.swift` trong cùng module.
