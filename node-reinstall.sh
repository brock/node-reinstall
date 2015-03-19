#!/bin/bash
# node-reinstall
# credit: http://stackoverflow.com/a/11178106/2083544

## program version
VERSION="0.0.4"

## path prefix
PREFIX="${PREFIX:-/usr/local}"

## version control systems
USE_NAVE=0
USE_NVM=1

## default node version
NODE_VERSION="0.10"

usage () {
  printf "%s\n" "node-reinstall"
  printf "\t%s\n" "completely re-installs Node & NPM and any global node modules."
  printf "\t%s\n" "It re-installs Node using NVM or Nave"
  printf "\n"
  printf "%s\t%s\n" "Usage:" "node-reinstall [--nave|--nvm|--nvm-latest] [-h|--help] [-v|--version] [NODE_VERSION]"
  printf "\n"
  printf "%s\n" "Commands:"
  printf "\n"
  printf "\t%s\t\t\t%s\n" "node-reinstall" "re-install node and npm using nvm"
  printf "\t%s %s %s\t%s\n" "node-reinstall" "-h" "[--help]" "show help"
  printf "\t%s %s %s\t%s\n" "node-reinstall" "-v" "[--version]" "show the node-reinstall version number"
  printf "\t%s %s\t\t%s\n" "node-reinstall" "--nave" "re-install using nave"
  printf "\t%s %s\t\t%s\n" "node-reinstall" "--nvm" "re-install using stable nvm - the default"
  printf "\t%s %s\t%s\n" "node-reinstall" "--nvm-latest" "re-install using latest nvm - creationix/nvm:master"
  printf "\t%s %s\t\t%s\n" "node-reinstall" "0.12" "specify a default node version - currently ${NODE_VERSION}"
  printf "\n"
}

## parse opts
{

  for opt in ${@}; do
    case $opt in
      --help|-h)
        usage
        exit
        ;;

      --version|-v)
        echo ${VERSION}
        exit
        ;;

      --nave)
        USE_NAVE=1
        USE_NVM=0
        ;;

      --nvm)
        USE_NVM=1
        USE_NAVE=0
        ;;

      --nvm-latest)
        USE_NVM=1
        USE_NAVE=0
        STABLE=master
        ;;

      *)
        if [ "-" == "${opt:0:1}" ]; then
          echo >&2 "error: Unknown option \`$opt'"
          usage >&2
          exit 1
        fi

        NODE_VERSION="${opt}"
    esac
  done

}

# get sudo
sudo -v

# check to see if npm is installed
IS_NPM_MISSING=$(which npm)
if [[ -z $IS_NPM_MISSING ]]; then
  echo "Installing Node, npm."
else
  echo "Completely reinstalling Node, npm."
  # get list of global npm modules to reinstall
  # omit the lib directory listing
  GLOBAL_MODULES=`npm -g list --depth 0 --parseable | xargs basename | sed -E 's/^(lib|npm)$//g'`
  if [[ -n $GLOBAL_MODULES ]]; then
    echo "Will reinstall these global npm modules:"
    echo $GLOBAL_MODULES
  fi
fi

if (( $USE_NVM )); then
  # NVM will think it is still installed if NVM_DIR is still set
  unset NVM_DIR
  sudo rm -rf $HOME/.nvm
elif (( $USE_NAVE )); then
  sudo rm -rf $HOME/.nave
else
  echo >&2 "error: Unsupported version control system"
  exit 1
fi

# erase all possible install paths
sudo rm -rf ~/{local,lib,include,node*,npm,.npm*}
sudo rm -rf $PREFIX/lib/node*
sudo rm -rf $PREFIX/include/node*
sudo rm -rf $PREFIX/bin/{node*,npm}
sudo rm -rf $PREFIX/bin/npm
sudo rm -rf $PREFIX/share/man/man1/node.1
sudo rm -rf $PREFIX/lib/dtrace/node.d
sudo rm -rf $HOME/.npm

if (( $USE_NVM )); then
  # go home and install NVM just because I feel safe there
  cd $HOME
  # get the latest stable version number of nvm from the repo's homepage
  [ "$STABLE" == "" ] && STABLE=$(curl -s https://github.com/creationix/nvm/ | grep "curl https://raw.githubusercontent.com/creationix/nvm/" | grep -oE "v\d+\.\d+\.\d+")
  curl -sL https://raw.githubusercontent.com/creationix/nvm/$STABLE/install.sh | bash
  source $HOME/.nvm/nvm.sh
elif (( $USE_NAVE )); then
  curl -sL https://raw.githubusercontent.com/isaacs/nave/master/nave.sh -o $PREFIX/bin/nave
fi


if (( $USE_NVM )); then
  # install the latest 0.10 version of node then set it as the default
  nvm install $NODE_VERSION
  nvm alias default $NODE_VERSION
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
elif (( $USE_NAVE )); then
  nave usemain $NODE_VERSION
fi

echo "Reinstalling your global npm modules:"
echo $GLOBAL_MODULES

npm install --global $GLOBAL_MODULES
