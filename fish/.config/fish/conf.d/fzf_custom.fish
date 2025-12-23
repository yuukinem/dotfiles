# 自定义 FZF 配置和函数
if not status is-interactive
    exit
end

# ======== FZF 基础配置 ========
set -gx FZF_DEFAULT_OPTS '--height 60% --layout=reverse --border --info=inline'

# 如果有 fd 就用 fd
if command -q fd
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
end

# 预览设置
if command -q bat
    set -gx FZF_CTRL_T_OPTS '--preview "bat --color=always --style=numbers --line-range=:500 {}"'
else
    set -gx FZF_CTRL_T_OPTS '--preview "head -100 {}"'
end

# ======== FZF 函数 ========

# ff - 模糊搜索文件并用编辑器打开
function ff --description "Fuzzy find file and open in editor"
    if command -q bat
        set -l file (fzf --preview 'bat --color=always --style=numbers {}')
    else
        set -l file (fzf --preview 'head -100 {}')
    end
    if test -n "$file"
        $EDITOR $file
    end
end

# fif - 搜索文件内容
function fif --description "Find in file content"
    if test (count $argv) -eq 0
        echo "Usage: fif <search_term>"
        return 1
    end

    if not command -q rg
        echo "错误: 需要安装 ripgrep"
        echo "运行: brew install ripgrep"
        return 1
    end

    set -l pattern "$argv"

    # 排除常见无关目录，隐藏错误输出
    set -l rg_opts --column --line-number --no-heading --color=always --smart-case \
        --glob '!.git' \
        --glob '!node_modules' \
        --glob '!*.min.js' \
        --glob '!*.min.css' \
        --glob '!Library' \
        --glob '!.Trash'

    # 根据是否有 bat 选择预览命令
    set -l match
    if command -q bat
        set match (rg $rg_opts "$pattern" 2>/dev/null | \
            fzf --ansi --delimiter : \
                --preview 'bat --color=always --style=numbers --highlight-line {2} {1} 2>/dev/null' \
                --preview-window 'right,60%' \
                --bind 'ctrl-/:toggle-preview')
    else
        set match (rg $rg_opts "$pattern" 2>/dev/null | \
            fzf --ansi --delimiter : \
                --preview 'rg --color=always --smart-case --context 10 "'"$pattern"'" {1} 2>/dev/null' \
                --preview-window 'right,60%' \
                --bind 'ctrl-/:toggle-preview')
    end

    if test -n "$match"
        set -l file (echo $match | cut -d: -f1)
        set -l line (echo $match | cut -d: -f2)
        $EDITOR +$line $file
    end
end

# fh - 搜索命令历史
function fh --description "Fuzzy search command history"
    history | fzf --no-sort | read -l cmd
    and commandline -r $cmd
end

# fcd - 模糊搜索目录并进入
function fcd --description "Fuzzy cd into directory"
    if command -q fd
        fd --type d --hidden --follow --exclude .git | fzf --preview 'ls -la {}' | read -l dir
    else
        find . -type d -not -path '*/\.git/*' 2>/dev/null | fzf --preview 'ls -la {}' | read -l dir
    end
    and cd $dir
end

# fp - 预览文件（kitty 支持图片）
function fp --description "Preview files with kitty image support"
    fzf --preview '
        if file {} | grep -qiE "image|bitmap"
            kitty +kitten icat --clear --transfer-mode=memory --stdin=no --place=40x20@0x0 {} 2>/dev/null
        else if command -q bat
            bat --color=always --style=numbers {}
        else
            head -100 {}
        end
    ' | read -l file
    and begin
        if file $file | grep -qiE "image|bitmap"
            kitty +kitten icat $file
        else if command -q bat
            bat $file
        else
            cat $file
        end
    end
end
