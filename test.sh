#!/bin/bash
if [[ $SHELL =~ zsh$ ]]; then
  	if [ -f "$HOME/.zshrc" ]; then
    	echo "Sourcing your ~/.zshrc file."
	   	source "$HOME/.zshrc"
	elif [ -f "$HOME/.profile" ]; then
    	echo "Sourcing your ~/.profile file."
    	source "$HOME/.profile"
    else
    	echo "Detected ZSH as your shell but did not find ~/.zshrc or ~/.profile"
    fi
elif [[ $SHELL =~ bash$ ]]; then
	if [ -f "$HOME/.bashrc" ]; then
    	echo "Sourcing your ~/.bashrc file."
    	source "$HOME/.bashrc"
	elif [ -f "$HOME/.bash_profile" ]; then
    	echo "Sourcing your ~/.bash_profile file."
    	source "$HOME/.bash_profile"
    elif [ -f "$HOME/.profile" ]; then
    	echo "Sourcing your ~/.profile file."
    	source "$HOME/.profile"
	else
    	echo "Detected Bash as your shell but did not find a ~/.bashrc or ~/.bash_profile or ~/.profile"
    fi
else
	if [ -f "$HOME/.profile" ]; then
    	echo "Your Shell type was not Bash or ZSH, but I found a ~/.profile file."
    	echo "I will try to source the ~/.profile, but you may need to restart your terminal for this to take effect."
    	echo "Please open an issue at http://github.com/brock/node-reinstall/issues and report your shell type:"
    	echo "Your shell type is: ${SHELL}"
    	echo ""
    	echo "Sourcing your ~/.profile file."
    	source "$HOME/.profile"
    fi
fi
