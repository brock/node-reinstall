BIN ?= node-reinstall
PREFIX ?= /usr/local
USAGE ?= $$(./node-reinstall -h | grep "Usage:")

install:
	cp node-reinstall $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)

readme:
	perl -pi -w -e "s/Usage:.*/$(USAGE)/" README.md
	sed '/Commands/,$$ d' README.md > changes.md
	mv changes.md README.md
	echo "## Commands" >> README.md
	echo '' >> README.md
	./node-reinstall -h | sed -n -e '/Commands:/,// p' | tail -n +3 >> README.md
