# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/huang/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

#source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

autoload -Uz vcs_info 
precmd() { vcs_info }

zstyle ':vcs_info:git:*' formats '%b ' 
setopt PROMPT_SUBST
PROMPT='%F{yellow}%~%f %F{cyan}${vcs_info_msg_0_}%f$ '

#config aliases
source ~/.aliases

#config environment variable
source ~/.env_var

# load autojump if first time  
# if type j; then 
#	. ~/dotfiles/autojump/install.py
#fi

# enable autojump feature
[[ -s /home/huang/.autojump/etc/profile.d/autojump.sh ]] && source /home/huang/.autojump/etc/profile.d/autojump.sh

autoload -U compinit && compinit -u

# enable vim in cmd line
bindkey -v

#change from Insert to Normal  form GPT

#no beep
unsetopt BEEP

#enable auto suggestion
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

#enable auto jump
	[[ -s /home/user/.autojump/etc/profile.d/autojump.sh ]] && source /home/user/.autojump/etc/profile.d/autojump.sh
	autoload -U compinit && compinit -u


# add neovim
export PATH="$PATH:/opt/nvim-linux64/bin"

#add Go for lazyvim
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
#export GOBIN=~/go/bin
export PATH=$PATH:$GOBIN
