# Negative test = test "cái XẤU phải bị chặn". Mỗi dòng changelog về security
# → ít nhất 1 negative test. Không có negative test thì fix chỉ tồn tại trên giấy.
# (hook/guard exit 2 khi block):
echo ok && rm -rf /data          # expect BLOCK (compound)
echo ok; rm -rf /data            # expect BLOCK
echo "a && b"                    # expect PASS (quotes — không false positive)
TZ=UTC rm -rf /data              # expect BLOCK (env-prefix)
A=1 B=2 rm -rf /data             # expect BLOCK
ln -s /data /tmp/link && rm -rf /tmp/link   # expect BLOCK (realpath)
bash -c 'rm -rf /data'           # expect BLOCK (deny interpreter)
# Họ nested mod: test trong plugin validate — user mod xin nested approval → REFUSE.
