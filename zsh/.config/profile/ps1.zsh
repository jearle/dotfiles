DIR=${0:a:h}

. $DIR/git-prompt.sh

BGREEN='%F{green}%B'
GREEN='%F{green}'
BRED='%F{red}%B'
RED='%F{red}'
BBLUE='%F{blue}%B'
BLUE='%F{blue}'
YELLOW='%F{yellow}%B'
MAGENTA='%F{magenta}'
LBLUE='%F{cyan}'
GRAY='%F{white}'
NORMAL='%f%b'

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"
export GIT_PS1_STATESEPARATOR=' '
export GIT_PS1_DESCRIBE_STYLE="branch"
export GIT_PS1_SHOWCOLORHINTS=1

MY_GIT='$(__git_ps1)'
TIME='%* | %D{%Y-%m-%d}'
MY_PATH='%~'

setopt PROMPT_SUBST
PS1=$(cat <<EOF

${BBLUE}${MY_GIT}
 ${YELLOW}${TIME}
 ${BGREEN}${MY_PATH}
 ${RED}> ${NORMAL}
EOF
)

