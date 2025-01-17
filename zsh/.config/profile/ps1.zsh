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
