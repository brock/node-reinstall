BIN ?= node-reinstall
PREFIX ?= /usr/local
USAGE ?= $$(./node-reinstall.sh -h | grep "Usage:")

install:
	cp node-reinstall.sh $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)

readme:
	perl -pi -w -e "s/Usage:.*/$(USAGE)/" README.md
	sed -i -e '/Commands/,$$ d' README.md
	echo "## Commands" >> README.md
	echo '' >> README.md
	./node-reinstall.sh -h | sed -n -e '/Commands:/,// p' | tail -n +3 >> README.md
