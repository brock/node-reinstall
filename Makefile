BIN ?= nodereinstall
PREFIX ?= /usr/local

install:
	cp nodereinstall.sh $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)

