# Triệu chứng: /context 80% sau 3 turns dù task nhỏ
# Metrics: skill.tokens_total: deploy 45K, các skill khác <3K → description quá rộng, fire nhầm
# Fix: hẹp description (chỉ fire khi user nói "deploy staging/prod")
#      + skillOverrides tắt auto-fire ở repo không deploy (xem Tips 07):
/doctor
# → "skill deploy fires 5/10 turns (unnecessary 4)" → hẹp xong còn 1/10
# Verify: metrics skill deploy <5K/turn ở repo này
