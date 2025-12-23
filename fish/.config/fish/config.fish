if status is-interactive
    # Git 缩写
    abbr -a gs git status
    abbr -a ga git add
    abbr -a gc git commit -m
    abbr -a gcl git clone
    abbr -a gp git push
    abbr -a gl git log --oneline
    abbr -a gd git diff
    abbr -a gco git checkout
    abbr -a gb git branch

    # 系统命令
    abbr -a ll ls -lah
    abbr -a la ls -a
    abbr -a .. cd ..
    abbr -a ... cd ../..
    abbr -a .... cd ../../..
    abbr -a c clear

    # 常用工具
    abbr -a py python3
    abbr -a ipy ipython

    # 编辑器设置
    set -gx EDITOR vim

    # 颜色支持
    set -gx CLICOLOR 1

    # 自动建议颜色（更柔和的灰色）
    set -g fish_color_autosuggestion 555 brblack
end

# ======== nvm.fish ========
set -gx NVM_DIR ~/.nvm
# ======== End nvm.fish ========
