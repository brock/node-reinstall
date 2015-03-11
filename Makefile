BIN ?= node-reinstall
PREFIX ?= /usr/local

install:
	cp node-reinstall.sh $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)

