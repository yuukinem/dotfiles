#!/bin/bash
# Kitty fzf 搜索并复制脚本
# 支持多行选择，并去掉 shell 提示符和末尾换行

# 使用完整路径，去掉常见的提示符，并去除末尾换行符
/opt/homebrew/bin/fzf --multi --no-sort --no-mouse --exact -i | \
    sed 's/^[❯›➜>$#] *//' | \
    sed 's/^.*@.*:.*[❯›➜>$#] *//' | \
    perl -pe 'chomp if eof' | \
    /usr/bin/pbcopy
