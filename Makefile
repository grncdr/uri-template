PATH += $(shell npm bin)
all: parser.js ./lib/classes.js ./lib/encoders.js

parser.js: parser.pegjs
	pegjs parser.pegjs

.PHONY: test
test: all
	node ./test

lib/%.js: src/%.coffee
	mkdir -p lib
	coffee -p -c $< > $@

clean:
	rm -r lib
	rm parser.js
