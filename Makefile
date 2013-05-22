#
# The binaries you need installed globally are node and npm
#

sources := $(shell find src web -iname '*.coffee')
web :=  $(shell find web/* -not -iname '*.coffee')
compiled = $(patsubst %.coffee, %.js, $(shell \
	files=; \
	for f in $(sources); do \
		files="$$files $(distdir)/`echo $$f | sed -e 's%^src/%%'`"; \
	done; \
	echo $$files \
))
distdir := dist

coffee := node_modules/.bin/coffee

all: dist

dist: build
	@echo "(target) generating distribution"
	@mkdir -p $(distdir)/web
	@node stitch.js
	@for f in $(web); do \
		cp -f $$f $(distdir)/$$f; \
	done

build: $(compiled)

$(distdir)/web/%.js: web/%.coffee node_modules
	@echo "(compile) source: $<"
	@$(coffee) -o $(distdir)/$(dir $<) -c $<

$(distdir)/%.js: src/%.coffee node_modules
	@echo "(compile) source: $<"
	@$(coffee) -o $(distdir)/`echo $(dir $<) | sed -e 's%^src/%%'` -c $<

test: build
	@$(coffee) test/doctest.coffee

node_modules: package.json
	@echo "(target) updating node modules..."
	@npm install && touch $@

clean:
	@echo "(target) cleaning..."
	@rm -rf $(distdir)

node_clean:
	@echo "(target) distcleaning..."
	@rm -rf node_modules

.PHONY: clean test
