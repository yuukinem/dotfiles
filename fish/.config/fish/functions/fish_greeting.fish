# 自定义欢迎提示 - 随机小动物（彩色版）
function fish_greeting
    # 随机选择一个小动物
    set -l animals \
        "cat" "dog" "fish" "rabbit" "owl" "fox" "bear" "penguin"

    set -l choice (random choice $animals)

    # 获取天气信息（带缓存，1小时更新一次）
    set -l cache_file ~/.cache/fish_weather_data
    set -l cache_max_age 3600
    set -l weather_icon ""
    set -l weather_desc ""
    set -l weather_temp ""
    set -l weather_max ""
    set -l weather_min ""

    # 天气描述转图标
    function __weather_icon
        switch $argv[1]
            case "*Sunny*" "*Clear*"
                echo "☀️"
            case "*Partly*cloudy*"
                echo "⛅"
            case "*Cloudy*" "*Overcast*"
                echo "☁️"
            case "*Mist*" "*Fog*"
                echo "🌁"
            case "*Rain*" "*Drizzle*" "*shower*"
                echo "🌧️"
            case "*Thunder*" "*storm*"
                echo "⛈️"
            case "*Snow*" "*Blizzard*"
                echo "❄️"
            case "*Sleet*" "*Ice*"
                echo "🌨️"
            case "*Wind*"
                echo "💨"
            case "*"
                echo "🌤️"
        end
    end

    # 检查缓存是否存在且未过期
    if test -f $cache_file
        set -l cache_age (math (date +%s) - (stat -f %m $cache_file))
        if test $cache_age -lt $cache_max_age
            set -l cache_data (cat $cache_file)
            set weather_icon (echo $cache_data | cut -d'|' -f1)
            set weather_desc (echo $cache_data | cut -d'|' -f2)
            set weather_temp (echo $cache_data | cut -d'|' -f3)
            set weather_max (echo $cache_data | cut -d'|' -f4)
            set weather_min (echo $cache_data | cut -d'|' -f5)
        end
    end

    # 如果缓存无效，实时获取并更新缓存
    if test -z "$weather_temp"
        set -l weather_json (curl -s --max-time 5 "wttr.in/Beijing?format=j1" 2>/dev/null)
        if test -n "$weather_json"
            set weather_temp (echo $weather_json | jq -r '.current_condition[0].temp_C' 2>/dev/null)
            set weather_desc (echo $weather_json | jq -r '.current_condition[0].weatherDesc[0].value' 2>/dev/null)
            set weather_max (echo $weather_json | jq -r '.weather[0].maxtempC' 2>/dev/null)
            set weather_min (echo $weather_json | jq -r '.weather[0].mintempC' 2>/dev/null)
            if test -n "$weather_temp" -a "$weather_temp" != "null"
                set weather_icon (__weather_icon "$weather_desc")
                # 写入缓存
                mkdir -p ~/.cache
                echo "$weather_icon|$weather_desc|$weather_temp|$weather_max|$weather_min" > $cache_file
            end
        end
    end

    if test -z "$weather_temp"
        set weather_icon "☀️"
        set weather_desc "今天也要元气满满哦"
        set weather_temp "--"
        set weather_max "--"
        set weather_min "--"
    end

    # 彩色天气显示函数
    function __show_weather
        set -l icon $argv[1]
        set -l desc $argv[2]
        set -l temp $argv[3]
        set -l max_t $argv[4]
        set -l min_t $argv[5]

        echo -n "  "
        echo -n "$icon "
        set_color bryellow
        echo -n "$desc "
        set_color brred
        echo -n "$temp°C "
        set_color red
        echo -n "↑$max_t°C "
        set_color brblue
        echo "↓$min_t°C"
        set_color normal
    end

    # 显示日期和时间
    set_color cyan
    echo "📅 "(date "+%Y年%m月%d日 %H:%M:%S")
    set_color normal
    echo ""

    # 根据选择显示不同的小动物（彩色版）
    switch $choice
        case cat
            # 猫咪 - 黄色身体，粉色鼻子，青色眼睛
            set_color yellow
            echo -n "   /\\_/\\  "
            set_color normal
            echo ""
            set_color yellow
            echo -n "  ( "
            set_color brcyan
            echo -n "o"
            set_color yellow
            echo -n "."
            set_color brcyan
            echo -n "o"
            set_color yellow
            echo -n " ) "
            set_color brmagenta
            echo "喵~ 欢迎回来！"
            set_color yellow
            echo -n "   > "
            set_color brred
            echo -n "^"
            set_color yellow
            echo " <  "
            __show_weather $weather_icon $weather_desc $weather_temp $weather_max $weather_min
        case dog
            # 狗狗 - 棕色身体，黑色鼻子
            set_color bryellow
            echo "   / \\__"
            echo -n "  (    "
            set_color black
            echo -n "@"
            set_color bryellow
            echo "\\___"
            echo -n "  /         "
            set_color black
            echo -n "O"
            set_color bryellow
            echo -n "  "
            set_color brgreen
            echo "汪汪~ 主人好！"
            set_color bryellow
            echo " /   (_____/"
            echo "/_____/   U"
            set_color normal
            __show_weather $weather_icon $weather_desc $weather_temp $weather_max $weather_min
        case fish
            # 鱼 - 蓝色身体，黄色眼睛
            set_color brblue
            echo -n "   ><((("
            set_color bryellow
            echo -n "°"
            set_color brblue
            echo "> "
            set_color brcyan
            echo "   Fish Shell 欢迎你！"
            set_color normal
            __show_weather $weather_icon $weather_desc $weather_temp $weather_max $weather_min
        case rabbit
            # 兔子 - 白色身体，粉色耳朵内侧，红色眼睛
            set_color white
            echo -n "   (\\"
            set_color brmagenta
            echo -n "_"
            set_color white
            echo "__/)"
            echo -n "   (="
            set_color brred
            echo -n "'"
            set_color white
            echo -n "."
            set_color brred
            echo -n "'"
            set_color white
            echo -n "=)  "
            set_color brmagenta
            echo "兔兔向你问好~"
            set_color white
            echo "   (\")_(\")  "
            set_color normal
            __show_weather $weather_icon $weather_desc $weather_temp $weather_max $weather_min
        case owl
            # 猫头鹰 - 棕色身体，大黄色眼睛
            set_color bryellow
            echo "   ,___,"
            echo -n "   ("
            set_color yellow
            echo -n "O"
            set_color bryellow
            echo -n ","
            set_color yellow
            echo -n "O"
            set_color bryellow
            echo -n ")  "
            set_color brmagenta
            echo "咕咕~ 智慧与你同在！"
            set_color bryellow
            echo "   (   )"
            echo "   -\"-\"-"
            set_color normal
            __show_weather $weather_icon $weather_desc $weather_temp $weather_max $weather_min
        case fox
            # 狐狸 - 橙红色身体，白色脸颊，黑色鼻子
            set_color brred
            echo "   /\\_/\\"
            echo -n "  ( "
            set_color bryellow
            echo -n "^"
            set_color black
            echo -n "."
            set_color bryellow
            echo -n "^"
            set_color brred
            echo " )/\\"
            echo -n "   (\") (\")  "
            set_color yellow
            echo "小狐狸祝你开心！"
            set_color normal
            __show_weather $weather_icon $weather_desc $weather_temp $weather_max $weather_min
        case bear
            # 熊 - 棕色身体，黑色鼻子和眼睛
            set_color bryellow
            echo -n "   ʕ "
            set_color black
            echo -n "•"
            set_color bryellow
            echo -n "ᴥ"
            set_color black
            echo -n "•"
            set_color bryellow
            echo "ʔ"
            set_color brmagenta
            echo "   熊熊给你一个大大的拥抱！"
            set_color normal
            __show_weather $weather_icon $weather_desc $weather_temp $weather_max $weather_min
        case penguin
            # 企鹅 - 黑白配色，黄色嘴巴
            set_color white
            echo -n "   ("
            set_color black
            echo -n "°"
            set_color yellow
            echo -n "v"
            set_color black
            echo -n "°"
            set_color white
            echo ")"
            set_color black
            echo -n "   <"
            set_color white
            echo -n "( )"
            set_color black
            echo -n ">  "
            set_color brcyan
            echo "企鹅向你挥手~"
            set_color yellow
            echo "    \" \""
            set_color normal
            __show_weather $weather_icon $weather_desc $weather_temp $weather_max $weather_min
    end

    set_color normal
    echo ""
end
