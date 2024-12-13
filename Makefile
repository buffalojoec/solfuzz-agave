RUSTFLAGS:=
RUSTFLAGS+=-g
RUSTFLAGS+=-Cpasses=sancov-module
RUSTFLAGS+=-Cllvm-args=-sanitizer-coverage-inline-8bit-counters
RUSTFLAGS+=-Cllvm-args=-sanitizer-coverage-level=4
RUSTFLAGS+=-Cllvm-args=-sanitizer-coverage-pc-table
RUSTFLAGS+=-Cllvm-args=-sanitizer-coverage-trace-compares
RUSTFLAGS+=-Clink-dead-code
RUSTFLAGS+=-Cforce-frame-pointers=yes
RUSTFLAGS+=-Ctarget-feature=-crt-static

ifeq ($(ENABLE_COVERAGE),1)
RUSTFLAGS+=-Cinstrument-coverage
$(info "Coverage enabled")
endif

CC:=clang

CARGO?=cargo

.PHONY: build clean binaries shared_obj fetch_proto

all: | fetch_proto shared_obj binaries

# Alias for backwards compatibility
build: | fetch_proto shared_obj

conformance: | fetch_proto shared_obj_debug

fetch_proto:
	./scripts/fetch_proto.sh

shared_obj:
	RUSTFLAGS="$(RUSTFLAGS)" $(CARGO) build --target x86_64-unknown-linux-gnu --release --lib
	# FIXME: Convert to a cargo workspace to create original and stubbed .so files in one go
	RUSTFLAGS="$(RUSTFLAGS)" $(CARGO) build --target x86_64-unknown-linux-gnu --release --lib --features stub-agave --target-dir target/stub-agave
	# to avoid conflicts when uploading as GH artifact
	cp target/stub-agave/x86_64-unknown-linux-gnu/release/libsolfuzz_agave.so target/x86_64-unknown-linux-gnu/release/libsolfuzz_agave_stubbed.so

shared_obj_debug:
	$(CARGO) build --lib

shared_obj_core_bpf:
	./scripts/fetch_program.sh $(PROGRAM)
	CARGO=$(CARGO) ./scripts/build_core_bpf.sh $(PROGRAM)

binaries:
	LLVM_PROFILE_FILE="compiler_artifacts.tmp" RUSTFLAGS="-Cinstrument-coverage" $(CARGO) build --bins --release
	# Remove the profile file generated by the build.rs script
	rm -f compiler_artifacts.tmp

tests/self_test: tests/self_test.c
	$(CC) -o $@ $< -Werror=all -pedantic -ldl -fsanitize=address,fuzzer-no-link -fsanitize-coverage=inline-8bit-counters

test:
	$(CARGO) check --release
	$(CARGO) test --release

clean:
	$(CARGO) clean
