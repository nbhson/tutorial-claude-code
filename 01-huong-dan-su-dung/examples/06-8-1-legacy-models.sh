# Tìm model IDs cũ còn sót:
rg -n "opus-4|sonnet-4|haiku-4[^.]" --glob '!node_modules' --glob '!.git'
# → đổi từng hit sang ID mục 3.1, test 1 task mẫu trước khi merge.
