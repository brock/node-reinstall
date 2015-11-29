# Node Re-install

[![Join the chat at https://gitter.im/brock/node-reinstall](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/brock/node-reinstall?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Complete Node Reinstall for OSX and Linux. See the [SO article](http://stackoverflow.com/a/11178106/2083544) for reference and the related [gist that spawned this repo](https://gist.github.com/brock/5b1b70590e1171c4ab54). This deletes everything, yes everything, and re-installs Node and NPM with NVM (or Nave), then re-installs any global NPM modules already installed.

*Don't have Node.js installed yet? No problem. It also works as a first-time installer.*

## Installation

Clone this repo somewhere: 
```
$ git clone git@github.com:brock/node-reinstall.git
$ cd node-reinstall
```

To run `node-reinstall`, you can call it directly since it is an executable file:

```
$ ./node-reinstall
```

Or you can run it with bash:
```
$ bash node-reinstall
```
---
If you decide later that you want to re-install all over again, just come back to this git repo where you cloned it, optionally update to the latest version of `node-reinstall` by running `git pull`, then run it again:
```
$ cd node-reinstall
$ git pull
$ bash node-reinstall
```

## Optional
If you are comfortable with Bash and the command line, you can copy the `node-reinstall` file to someplace in your [$PATH](http://en.wikipedia.org/wiki/PATH_%28variable%29)
```
cp node-reinstall ~/bin/node-reinstall
```

With `node-reinstall` in your [$PATH](http://en.wikipedia.org/wiki/PATH_%28variable%29) you can execute it from any directory:
```
$ node-reinstall
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
	node-reinstall 0.12				specify a default node version - currently 0.10

