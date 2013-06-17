COFFEE_FILES := $(wildcard *.coffee)
JS_FILES := $(COFFEE_FILES:%.coffee=%.js)

build: components d3-testbed.css $(JS_FILES)
	component build --dev

.SUFFIXES: .coffee .js

.coffee.js:
	coffee -c $<

# template.js: template.html
#	@component convert $<

components: component.json
	@component install --dev

clean:
	rm -fr build components template.js

.PHONY: clean build
