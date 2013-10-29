.PHONY: doc info test clean

SOURCE = ini.lua

info:
	@echo Available Targets
	@echo =================
	@echo doc: build the luadoc HTML documentation
	@echo clean: remove debris
	@echo test: run the test suite

doc:
	luadoc -d doc $(SOURCE)

test:
	make -C test

clean:
	-rm -rf ./doc/*
	make -C test clean
