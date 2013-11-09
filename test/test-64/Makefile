.PHONY: test pre clean
SOURCE = $(wildcard test-*.lua)

test: pre
	diff test-*.ini

pre:
	luajit $(SOURCE)

clean:
	-rm $(wildcard test-*.ini)
