-include test_config.mk
CFG_FILE   ?= ../test/build_cfg_orca.py
BUILD_ARGS ?= -k --cfg-file=$(CFG_FILE) $(EXTRA_BUILD_ARGS)

default: builds

RV_TESTS=../software/riscv-tests
RV_TESTS_COPY=software/riscv-tests
$(RV_TESTS_COPY): $(RV_TESTS)
	rm -rf software/riscv-tests
	cp -r $< $@

builds: $(RV_TESTS_COPY)
	python ../scripts/build/build.py $(BUILD_ARGS) 2>&1 | tee builds.log

################################################################################

clean:
	rm -rf builds/ builds.log $(RV_TESTS_COPY) *~ nohup.out \#*

################################################################################

.PHONY: builds clean microsemi microsemi_timing lattice $(RV_TESTS_COPY)
.DELETE_ON_ERROR:
