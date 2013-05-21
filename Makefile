.PHONY: all test publish clean

all: index.js ./lib/classes.js ./lib/encoders.js

index.js: index.pegjs
	@node_modules/.bin/pegjs index.pegjs

lib/%.js: src/%.coffee
	@mkdir -p lib
	@node_modules/.bin/coffee -p -c $< > $@

test: all
	@coffee ./test/index.coffee

publish: test
	@npm publish

clean:
	@rm -r lib
	@rm index.js
