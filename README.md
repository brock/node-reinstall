# Node Re-install

Complete Node Reinstall. See the [SO article](http://stackoverflow.com/a/11178106/2083544) for reference and the related [gist that spawned this repo](https://gist.github.com/brock/5b1b70590e1171c4ab54). This deletes everything, yes everything, and re-installs Node and NPM with NVM (or Nave), then re-installs any global NPM modules already installed.

## Installation

With [bpkg](https://github.com/bpkg/bpkg):

```sh
$ bpkg install -g brock/node-reinstall
```

Or from source:

```
$ git clone git@github.com:brock/node-reinstall.git
$ cp node-reinstall/node-reinstall.sh ~/bin/node-reinstall
```

## Usage

Whenever you feel like you need to completely re-install Node and NPM, simply run the command `node-reinstall`. You'll be prompted for sudo privileges since this will remove all possible installation paths. Feel free to update this script if it deletes directories in excess. Pull requests welcome.


    Usage:	node-reinstall [--nave|--nvm|--nvm-latest] [-h|--help] [-v|--version] [NODE_VERSION]

## Commands

	node-reinstall					re-install node and npm using nvm
	node-reinstall -h [--help]		show help
	node-reinstall -v [--version]	show the node-reinstall version number
	node-reinstall --nave			re-install using nave
	node-reinstall --nvm			re-install using stable nvm - the default
	node-reinstall --nvm-latest		re-install using latest nvm - creationix/nvm:master
	node-reinstall 0.12				specify a default node version - currently 0.10
