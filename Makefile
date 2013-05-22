#
# The binaries you need installed globally are node and npm
#

distdir := dist
compileddir := compiled

coffee := node_modules/.bin/coffee

sources := $(shell find src web -iname '*.coffee')
web :=  $(shell find web/* -not -iname '*.coffee')
compiled = $(patsubst %.coffee, %.js, $(shell \
	files=; \
	for f in $(sources); do \
		files="$$files $(compileddir)/$$f"; \
	done; \
	echo $$files \
))

all: dist

dist: build
	@echo "(target) generating distribution"
	@mkdir -p $(distdir)/web
	@node stitch.js
	@for f in $(web); do \
		cp -f $$f $(distdir)/$$f; \
	done

build: $(compiled)

$(compileddir)/src/%.js: src/%.coffee node_modules
	@echo "(compile) source: $<"
	@$(coffee) -o $(compileddir)/$(dir $<) -c $<

$(compileddir)/web/%.js: web/%.coffee node_modules
	@echo "(compile) web: $<"
	@$(coffee) -o $(compileddir)/$(dir $<) -c $<

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

.PHONY: clean test build dist all
