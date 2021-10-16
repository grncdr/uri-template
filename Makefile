.PHONY: all test publish clean

all: lib/grammar.js dist/index.js dist/classes.js

dist/%.js: lib/%.ts
	@npx tsc

lib/grammar.js: lib/grammar.pegjs
	@npx pegjs lib/grammar.pegjs ./lib/grammar.js

test: all
	@node ./test/index.js

publish: test
	@npm publish

clean:
	@rm -fr dist
