claude --safe-mode              # cách 1: 1 session sạch
# settings: { "disableAllHooks": true }   # cách 2: mọi session
claude --bare -p "..."          # cách 3: API run sạch (CI)
# cách 4: managed policy JSON (org admin) — tên flags chính xác xem docs bản bạn:
# { "allowManagedModsOnly": true, "disableSideloadFlags": true,
#   "prependPlugins": ["org-policy-mod"], ".catch": "refuse" }
