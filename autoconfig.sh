#! /bin/bash

# Run at the dotfiles path, otherwise the ls and the pwd won't work.
# test c

# 2. download tmux if not installed DONE
# Auto switch esc and capslock DONE
# DONE 1. set zsh as default shell
# Lack:
# 3. auto config 'auto suggestion' and 'auto smart jump'
# 4. git ssh?
# clash config : lanqiaoyun
# downloading need files for plugin in dir 'plugin'

files=$(ls -a | grep -E '^\.[^.]' | grep -v '.git$' )


if ! which zsh; then
  sudo apt-get install zsh
fi
chsh -s $(which zsh)

if ! which tmux; then
  sudo apt-get install tmux
fi

for file in $files ;do
	if [[ -e ~/$file ]]; then
		rm ~/$file;
	fi	
	ln -s $(pwd)/$file ~/$file	;
done
