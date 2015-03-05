#!/bin/bash
# nodereinstall
# credit: http://stackoverflow.com/a/11178106/2083544

# get sudo
sudo -v

# check to see if npm is installed
IS_NPM_MISSING=$(which npm)
if [[ -z $IS_NPM_MISSING ]]; then
  echo "Installing Node, npm, and nvm."
else
  echo "Completely reinstalling Node, npm, and nvm."
  # get list of global npm modules to reinstall
  # omit the lib directory listing
  GLOBAL_MODULES=`npm -g list --depth 0 --parseable | xargs basename | sed -E 's/^(lib|npm)$//g'`
  if [[ -n $GLOBAL_MODULES ]]; then
    echo "Will reinstall these global npm modules:"
    echo $GLOBAL_MODULES
  fi
fi

# NVM will think it is still installed if NVM_DIR is still set
unset NVM_DIR

# erase all possible install paths
sudo rm -rf /usr/local/lib/node*
sudo rm -rf /usr/local/include/node*
sudo rm -rf ~/{local,lib,include,node*,npm,.npm*}
sudo rm -rf /usr/local/bin/{node*,npm}
sudo rm -rf /usr/local/bin/npm
sudo rm -rf /usr/local/share/man/man1/node.1
sudo rm -rf /usr/local/lib/dtrace/node.d
sudo rm -rf ~/.npm
sudo rm -rf ~/.nvm

# go home and install NVM just because I feel safe there
cd $HOME
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

# you must "source" the NVM exports - yours are most likely in ~/.zshrc or ~/.bashrc or ~/.bash_profile
source ~/.zshrc
# source ~/.bashrc
# source ~/.bash_profile

# install the latest 0.10 version of node then set it as the default
nvm install 0.10
nvm alias default 0.10

echo "Reinstalling your global npm modules:"
echo $GLOBAL_MODULES

npm install --global $GLOBAL_MODULES
fi
fi
