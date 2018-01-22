-include test_config.mk
CFG_FILE   ?= ../test/build_cfg_orca.py
BUILD_ARGS ?= -k --cfg-file=$(CFG_FILE) $(EXTRA_BUILD_ARGS)

.PHONY: testall
testall:

RV_TESTS=../software/riscv-tests
RV_TESTS_COPY=software/riscv-tests
$(RV_TESTS_COPY): $(RV_TESTS)
	rm -rf software/riscv-tests
	cp -r $< $@


builds:
	mkdir -p $@

builds/%: | builds
	rm -f builds/$*
	cd builds && ln -sf ../../$*

.PHONY: testall
testall: $(RV_TESTS_COPY) builds/rtl builds/software
	python ../scripts/build/build.py $(BUILD_ARGS) 2>&1 | tee make.log

################################################################################

.PHONY: clean
clean:
	rm -rf builds/ *.log $(RV_TESTS_COPY) *~ nohup.out \#*

################################################################################

.DELETE_ON_ERROR:
