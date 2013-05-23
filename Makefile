#
# The binaries you need installed globally are node and npm
#

dist_dir := dist
compiled_dir := compiled

coffee := node_modules/.bin/coffee
mocha := node_modules/.bin/mocha

sources := $(shell find src web -iname '*.coffee')
web :=  $(shell find web/* -not -iname '*.coffee')
test_sources := $(shell find test -iname '*.coffee')
get_compiled = $(patsubst %.coffee, %.js, $(shell \
	files=; \
	for f in $(1); do \
		files="$$files $(compiled_dir)/$$f"; \
	done; \
	echo $$files \
))
compiled = $(call get_compiled, $(sources))
test_compiled = $(call get_compiled, $(test_sources))

all: dist

dist: test
	@echo "(target) generating distribution"
	@mkdir -p $(dist_dir)/web
	@node stitch.js
	@for f in $(web); do \
		cp -f $$f $(dist_dir)/$$f; \
	done
	@for f in `find $(compiled_dir)/web -iname '*.js'`; do \
		dest_file=$(dist_dir)/`echo $$f | sed -e 's%^compiled/%%'`; \
		cp -f $$f $$dest_file; \
	done

build: $(compiled)

$(compiled_dir)/src/%.js: src/%.coffee node_modules
	@echo "(compile) source: $<"
	@$(coffee) -o $(compiled_dir)/$(dir $<) -c $<

$(compiled_dir)/web/%.js: web/%.coffee node_modules
	@echo "(compile) web: $<"
	@$(coffee) -o $(compiled_dir)/$(dir $<) -c $<

$(compiled_dir)/test/%.js: test/%.coffee node_modules
	@echo "(compile) test: $<"
	@$(coffee) -o $(compiled_dir)/$(dir $<) -c $<
	@cp test/mocha.opts $(compiled_dir)/test

test: build $(test_compiled)
	@echo "(target) running tests..."
	@cd $(compiled_dir); ../$(mocha)
	@echo "(target) running doc tests..."
	@node $(compiled_dir)/test/doctest

node_modules: package.json
	@echo "(target) updating node modules..."
	@npm install && touch $@

clean:
	@echo "(target) cleaning..."
	@rm -rf $(compiled_dir)
	@rm -rf $(dist_dir)

node_clean:
	@echo "(target) distcleaning..."
	@rm -rf node_modules

.PHONY: clean test build dist all
