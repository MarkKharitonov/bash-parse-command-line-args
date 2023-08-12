#!/usr/bin/env bash
# Copyright 2023 Mark Kharitonov

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

IFS=$'\n'
opts_short=h
opts_long=help
help_text="-h, --help[zz]Show this help text"
case_body="    -h | --help)
        help
        exit
        ;;"
required_check_body=
required_check_body_delim=
help_opt_len=10

init_vars_text=
init_vars_delim=

for cmd in $(jq -r '.[] | ([to_entries[] | "\(.key)=\(.value|@sh)"] | join(" "))'); do
    option= description= required= variable=
    eval $cmd
    if [[ -z "$option" ]] || [[ -z "$description" ]] || [[ -z "variable" ]]; then
        echo &>2 "Malformed args spec"
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

    init_vars_text+="$init_vars_delim$variable="
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
        required_check_body+="${required_check_body_delim}if [[ -z \"\$$variable\" ]]; then
    echo \"$(basename $0): a required option is missing ($case_cond)\"
    exit 1
fi"
        required_check_body_delim="
"
        description="[REQUIRED] $description"
    fi

    help_text+="
$help_opt[zz]$description"
done

temp_file=$(mktemp)
{
    echo 'help() {'
    echo '    echo Command line options:'
    echo '    echo'
    for help_line in $(echo "$help_text"); do
        echo $help_line | awk -F '\\[zz\\]' -v width=$help_opt_len '{ printf("    echo \"%-*s%s\"\n", width + 1, $1, $2) }'
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
    echo "$required_check_body"
} >$temp_file

. $temp_file
