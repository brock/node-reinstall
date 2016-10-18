# Node Re-install

[![Join the chat at https://gitter.im/brock/node-reinstall](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/brock/node-reinstall?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Node-Reinstall is going to delete a lot of shit, and you won't be able to recover any of it. Do yourself a favor and make sure that you read the [node-reinstall](./node-reinstall) script and completely understand what it is going to do (i.e.: *what it is going to delete*) before you proceed. Here is an expanded version of the script that shows all of the directories that will be deleted:

```
rm -rf ~/local
rm -rf ~/lib
rm -rf ~/include
rm -rf ~/node*
rm -rf ~/npm
rm -rf ~/.npm*
sudo rm -rf /usr/local/lib/node*
sudo rm -rf /usr/local/include/node*
sudo rm -rf /usr/local/bin/node
sudo rm -rf /usr/local/bin/npm
sudo rm -rf /usr/local/share/man/man1/node.1
sudo rm -rf /usr/local/lib/dtrace/node.d
```

At an absolute minimum, you need to go into the home directories (the ones that start with `~/`) and make sure you are okay with deleting the contents of those directories. If you are unsure if this will delete anything important, you should stop now and find another alternative for re-installing Node.js, because this approach is pretty destructive.

This script assumes you are comfortable enough with UNIX to perform these actions. If you are not, I will respond to your GitHub issue with the following GIF that is titled "pay-attention.gif"  

![](img/pay-attention.gif)

## Summary
This is a complete (and very destructive) tool for re-installing Node.js on OSX and Linux. See the [SO article](http://stackoverflow.com/a/11178106/2083544) for reference and the related [gist that spawned this repo](https://gist.github.com/brock/5b1b70590e1171c4ab54). This deletes ~~everything, yes everything,~~ **a lot of stuff you might want** and completely removes Node.js and NPM and replaces it with the Node Version Manager called [NVM](https://github.com/creationix/nvm). It will attempt to re-install any global NPM modules already installed, and you can opt for Nave instead of NVM if you prefer.

It also works as a first-time installer.

## Installation

### Clone this Repo

Clone this repo somewhere. If you have SSH setup with GitHub, use this format:
```
git clone git@github.com:brock/node-reinstall.git
```

Otherwise, clone this repo using HTTPS:
```
git clone https://github.com/brock/node-reinstall.git
```

### Run the Re-Installer
Change into the directory:
```
cd node-reinstall
```

To run `node-reinstall`, you can call it directly since it is an executable file:

```
./node-reinstall
```

Or you can run it with bash:
```
bash node-reinstall
```
---
If you decide later that you want to re-install Node.js all over again, just come back to the directory where you cloned the `node-reinstall` repo, optionally update to the latest version of `node-reinstall` by running `git pull`, then run it again:

```
git pull
bash node-reinstall
```

## Optional
If you are comfortable with Bash and the command line, you can copy the `node-reinstall` file to someplace in your [$PATH](http://en.wikipedia.org/wiki/PATH_%28variable%29)
```
cp node-reinstall ~/bin/node-reinstall
```

With `node-reinstall` in your [$PATH](http://en.wikipedia.org/wiki/PATH_%28variable%29) you can execute it from any directory:
```
node-reinstall
```


## Usage

Whenever you feel like you need to completely re-install Node and NPM, simply execute `node-reinstall`. You'll be prompted for sudo privileges since this will remove all possible installation paths. Pull requests welcome.


    Usage:	node-reinstall [--nave|--nvm|--nvm-latest] [-h|--help] [-v|--version] [NODE_VERSION]

## Commands

	node-reinstall					re-install node and npm using nvm
	node-reinstall [-h|--help]		show help
	node-reinstall [-v|--version]	show the node-reinstall version number
	node-reinstall [-f|--force]		installs defaults without user confirmation
	node-reinstall --nave			re-install using nave
	node-reinstall --nvm			re-install using stable nvm - the default
	node-reinstall --nvm-latest		re-install using latest nvm - creationix/nvm:master
	node-reinstall 5.0.0			specify a default node version
