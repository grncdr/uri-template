.PHONY: check publish clean

all: lib/grammar.js dist/index.js dist/classes.js

dist/%.js: lib/%.ts
	@npx tsc

check:
	@npx tsc --noEmit

lib/grammar.js: lib/grammar.pegjs
	@npx peggy lib/grammar.pegjs

test: all
	@node ./test/index.js

publish: test
	@npm publish

clean:
	@rm -fr dist
