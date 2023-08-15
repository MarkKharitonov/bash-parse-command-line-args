#!/usr/bin/env bash
# Copyright 2023 Mark Kharitonov

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

opts_short=h
opts_long=help
help_lines=("-h, --help[zz]Show this help text")
case_body="    -h | --help)
        help
        exit
        ;;"
extra_checks_body=
extra_checks_body_delim=
help_opt_len=10

init_vars_text=
init_vars_delim=

i=0
readarray cmds < <(jq -r '.[] | ([to_entries[] | {k:.key,v:(.value | if (. | type == "array") then [.[] | tojson | @sh] else (. | @sh) end)} | "\(.k)=\(.v)"] | join(" "))')
for cmd in "${cmds[@]}"; do
    ((i = i + 1))
    option= description= required= values= variable= default=
    eval $cmd
    if [[ -z "variable" ]]; then
        echo >&2 "$(basename $0): malformed spec for parameter #$i - missing 'variable'."
        exit 1
    fi
    if [[ -z "$option" ]]; then
        echo >&2 "$(basename $0): malformed spec for $variable - missing 'option'."
        exit 1
    fi
    if [[ -z "$description" ]]; then
        echo >&2 "$(basename $0): malformed spec for $variable - missing 'description'."
        exit 1
    fi
    if [[ "$required" ]] && [[ "$default" ]] && [[ "$required" != false ]] && [[ "$required" != 0 ]]; then
        echo >&2 "$(basename $0): malformed spec for $variable - 'required' and 'default' are mutually exclusive."
        exit 1
    fi
    if [[ "$default" ]] && [[ "$values" ]] && [[ -z $(jq -n --arg item "$default" ${values//\'/}'[] | select(. == $item)') ]]; then
        echo >&2 "$(basename $0): malformed spec for $variable - the default value '$default' is not equal any of the supported values $(echo ${values:1:-1} | tr -d '\"')."
        exit 1
    fi
    IFS='|' read -a keys <<<$option
    q=
    i=0
    value=1
    shift=1
    for k in "${keys[@]}"; do
        if [[ $k = *= ]]; then
            q=:
            value='"$2"'
            shift=2
            k=${k::-1}
        fi
        keys[$i]=$k
        ((i = i + 1))
    done

    init_vars_text+="$init_vars_delim$variable=$default"
    init_vars_delim="
"

    case_cond=
    case_cond_delim=
    help_opt=
    help_opt_delim=
    has_short_opt=
    for k in "${keys[@]}"; do
        if [[ ${#k} -eq 1 ]]; then
            opts_short+="$k$q"
            has_short_opt=1
        else
            opts_long+=",$k$q"
            k=-$k
        fi
        case_cond+="$case_cond_delim-$k"
        help_opt+="$help_opt_delim-$k"
        case_cond_delim=" | "
        help_opt_delim=", "
    done

    if [[ -z "$has_short_opt" ]]; then
        help_opt="    $help_opt"
    fi
    if [[ "$q" ]]; then
        help_opt+="=value"
    fi

    if [[ ${#help_opt} -gt $help_opt_len ]]; then
        help_opt_len=${#help_opt}
    fi

    case_body+="
    $case_cond)
        $variable=$value
        shift $shift
        ;;"

    if [[ $required == true ]]; then
        extra_checks_body+="${extra_checks_body_delim}if [[ -z \"\$$variable\" ]]; then
    echo \"\$(basename \$0): ($case_cond) value must be given\"
    exit 1
fi"
        extra_checks_body_delim="
"
        description="[REQUIRED] $description"
    fi

    help_lines+=("$help_opt[zz]$description")

    if [[ "$values" ]]; then
        extra_checks_body+="${extra_checks_body_delim}if [[ \"\$$variable\" ]] && [[ -z \$(jq -n --arg item \"\$$variable\" $values'[] | tostring | select(. == \$item)') ]]; then
    echo \"\$(basename \$0): The given ($case_cond) value of '\$$variable' is not equal any of the supported values ${values:1:-1}\"
    exit 1
fi"
        extra_checks_body_delim="
"
        help_lines+=(" [zz]The supported values: ${values:1:-1}")
    fi
    if [[ "$default" ]]; then
        help_lines+=(" [zz]The default value: '$default'")
    fi
done

temp_file=$(mktemp)
{
    echo 'help() {'
    echo '    echo Command line options:'
    echo '    echo'
    for help_line in "${help_lines[@]}"; do
        echo "$help_line" | awk -F '\\[zz\\]' -v width=$help_opt_len '{ printf("    echo \"%-*s%s\"\n", width + 1, $1, $2) }'
    done
    echo '}'
    echo
    echo "$init_vars_text"

    opts_short=${opts_short:+-o $opts_short}
    opts_long=${opts_long:+--long $opts_long}

    echo
    echo 'VALID_ARGS=$(getopt -n $(basename $0) '$opts_short' '$opts_long' -- "$@")'
    echo 'if [[ $? -ne 0 ]]; then'
    echo '    exit 1'
    echo 'fi'
    echo
    echo 'eval set -- "$VALID_ARGS"'
    echo 'while true; do'
    echo '    case "$1" in'
    echo "$case_body"
    echo '    --)'
    echo '        shift'
    echo '        break'
    echo '        ;;'
    echo '    esac'
    echo 'done'
    echo "$extra_checks_body"
} >$temp_file

. $temp_file
