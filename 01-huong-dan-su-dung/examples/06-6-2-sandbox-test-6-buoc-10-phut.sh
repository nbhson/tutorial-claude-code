# 1. Clone/unwrap plugin vào /tmp, đọc plugin.json + từng hook .sh (checklist 6.1).
cd /tmp/test-repo && git init && echo test > a.txt
# 2. Cài từ path local vào repo THỬ: /plugin → Install from path
# 3. Test từng skill namespaced: /<plugin>:<skill> với input vô hại.
# 4. Test hooks: prompt yêu cầu việc hook phải block → xác nhận deny.
# 5. /usage + /cost: plugin có phình context? disable skill ồn nếu cần.
# 6. Ổn mới cài vào repo thật + pin version.
