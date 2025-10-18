#!/bin/bash

# logs for every cli bash command
if [ ! -d "$HOME/.logs" ]; then
	mkdir "$HOME/.logs"
fi
echo "export PROMPT_COMMAND='if [ \"\$(id -u)\" -ne 0 ]; then echo \"\$(date \"+%Y-%m-%d.%H:%M:%S\") \$(pwd) \$(history 1)\" >> ~/.logs/bash-history-\$(date \"+%Y-%m-%d\").log; fi'" >> $HOME/.profile
source $HOME/.profile

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install vim tmux wget
