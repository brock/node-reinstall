#!/bin/bash
# nodereinstall
# credit: http://stackoverflow.com/a/11178106/2083544

# get sudo
sudo -v

## program version
VERSION="0.0.1"

## path prefix
PREFIX="${PREFIX:-/usr/local}"

## version control systems
USE_NAVE=0
USE_NVM=1

## default node version
NODE_VERSION="0.10"

usage () {
  echo "usage: nodereinstall [-hV] [version]"
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
  curl -sL https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
  source $HOME/.nvm/nvm.sh
elif (( $USE_NAVE )); then
  curl -sL https://raw.githubusercontent.com/isaacs/nave/master/nave.sh -o $PREFIX/bin/nave
fi


if (( $USE_NVM )); then
  # install the latest 0.10 version of node then set it as the default
  nvm install $NODE_VERSION
  nvm alias default $NODE_VERSION
  if test -f $HOME/.zshrc; then
    # you must "source" the NVM exports - yours are most likely in ~/.zshrc or ~/.bashrc or ~/.bash_profile
    source $HOME/.zshrc
  elif test -f $HOME/.bashrc; then
     # source $HOME/.bashrc
    :
  elif test -f $HOME/.bash_profile; then
    # source $HOME/.bash_profile
    :
  fi
elif (( $USE_NAVE )); then
  nave usemain $NODE_VERSION
fi

echo "Reinstalling your global npm modules:"
echo $GLOBAL_MODULES

npm install --global $GLOBAL_MODULES
