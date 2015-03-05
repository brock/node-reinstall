# Node Re-install

Complete Node Reinstall. See the [SO article](http://stackoverflow.com/a/11178106/2083544) for reference and the related [gist that spawned this repo](https://gist.github.com/brock/5b1b70590e1171c4ab54). This deletes everything, yes everything, and re-installs Node and NPM with NVM, then re-installs global NPM modules.

## Installation

With [bpkg](https://github.com/bpkg/bpkg):

```sh
$ bpkg install brock/node-reinstall
```

Or from source:

```
$ git clone git@github.com:brock/node-reinstall.git
$ cp node-reinstall/nodereinstall.sh ~/bin/nodereinstall
$ chmod +x ~/bin/nodereinstall
```

## Usage
Whenever you feel like you need to completely re-install Node, NPM or NVM, simply run the command `nodereinstall`. You'll be prompted for sudo priviledges since this will remove all possible installation paths. Feel free to update this script if it deletes directories in excess. Pull requests welcome.
