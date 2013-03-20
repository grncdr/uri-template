all: parser.js ./lib/classes.js ./lib/encoders.js

parser.js: parser.pegjs
	node_modules/.bin/pegjs parser.pegjs

.PHONY: test
test: all
	node ./test

lib/%.js: src/%.coffee
	mkdir -p lib
	node_modules/.bin/coffee -p -c $< > $@

clean:
	rm -r lib
	rm parser.js

publish: all
	node test.js
	npm publish
