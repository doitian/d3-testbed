build: components index.js 2013-06-top3-donut.js d3-testbed.css
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
