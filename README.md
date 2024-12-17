# SolFuzz-Agave

SolFuzz-Agave provides [SolFuzz](https://github.com/firedancer-io/solfuzz) API bindings for Agave components. These API bindings have native support in Firedancer, but not in Agave. This harness simply wraps pieces of Agave's execution layer to provide the necessary APIs to run fuzz tests on Agave components.

It only supports `x86_64-unknown-linux-gnu` targets.

Supported APIs:

- `sol_compat_instr_execute_v1`
- `sol_compat_vm_syscall_execute_v1`

## How to Use

Install dependencies:
```sh
apt install libudev-dev protobuf-compiler pkg-config
```


Check and test:

```sh
cargo check
cargo test
```

Build:

```sh
make build
make conformance
```

Produces file `target/x86_64-unknown-linux-gnu/release/libsolfuzz_agave.so`, which is a SolFuzz target that can be used with [Solana-Conformance](https://github.com/firedancer-io/solana-conformance) and [SolFuzz](https://github.com/firedancer-io/solfuzz).

The resulting file is instrumented with sancov.

```
$ ldd target/x86_64-unknown-linux-gnu/release/libsolfuzz_agave.so
        linux-vdso.so.1 (0x00007ffdaeba8000)
        libgcc_s.so.1 => /lib64/libgcc_s.so.1 (0x00007f328c8e4000)
        libpthread.so.0 => /lib64/libpthread.so.0 (0x00007f328c6c4000)
        libm.so.6 => /lib64/libm.so.6 (0x00007f328c342000)
        libdl.so.2 => /lib64/libdl.so.2 (0x00007f328c13e000)
        libc.so.6 => /lib64/libc.so.6 (0x00007f328bd79000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f328ef71000)

$ nm -D target/x86_64-unknown-linux-gnu/release/libsolfuzz_agave.so | grep '__sanitizer'
                 U __sanitizer_cov_8bit_counters_init
                 U __sanitizer_cov_pcs_init
                 U __sanitizer_cov_trace_pc_indir
```

**Note:** You may have to periodically run `make build` to ensure that Protobuf definitions stay in sync with [Protosol](https://github.com/firedancer-io/protosol/). Alternatively, you can run `./scripts/fetch_proto.sh` to keep Protosol up to date.

## Building Targets with Core BPF Programs

SolFuzz-Agave can be used with tools like [Solana-Conformance](https://github.com/firedancer-io/solana-conformance) and [SolFuzz](https://github.com/firedancer-io/solfuzz) to test for conformance between a builtin program and its [Core BPF](https://github.com/solana-foundation/solana-improvement-documents/blob/main/proposals/0088-enable-core-bpf-programs.md) version.

For this use case, contributors may wish to build one target which contains the builtin version, and then another target which contains the BPF version. This concept is oriented around the contents of the compiled target's [program JIT cache](https://github.com/anza-xyz/agave/blob/6c6c26eec4317e06e334609ea686b0192a210092/program-runtime/src/loaded_programs.rs#L654).

By default, SolFuzz-Agave populates the program JIT cache with each of the Solana protocol's builtin programs when the entrypoint for an instruction (`sol_compat_instr_execute_v1`) is invoked (see the `load_builtins` function in `lib.rs`). A combination of a feature flag and compile-time environment variables can be used to override a builtin in the program JIT cache.

Available features:
* `core-bpf`: Simply overrides the builtin with the provided BPF program, no other special-casing.
* `core-bpf-conformance`: Overrides the builtin with the provided BPF program and additionally enables certain logic to handle known mismatches between builtins and BPF programs. This feature is primarily intended for the `run-tests` function of Solana-Conformance.

Required variables:
* `CORE_BPF_PROGRAM_ID`: The program ID of the builtin that should be overriden in the cache.
* `CORE_BPF_TARGET`: The path to the program's ELF file (`.so` file) to use in place of the builtin.

**Note:** You may continue to use the same program ID and ELF file path in consecutive compilations, but the program ELF itself has changed. Rustc has no way to know about this change, since the environment variables have not changed. As a result, you can optionally provide `FORCE_RECOMPILE=true` to recompile the underlying macro that does the builtin override, to ensure the compiled target has the latest ELF.

The overriding of a builtin is done via [macro](./macro/), which generates code only when either the `core-bpf` or `core-bpf-conformance` feature is enabled. This code will perform the override, as well as a few other related tasks.

A convenience script is available to assist in building targets with Core BPF programs. It can be found at [`scripts/build_core_bpf.sh`](./scripts/build_core_bpf.sh) and supports a set of specific program IDs currently. Simply add your program ID t this list and the list defined in the macro (`SUPPORTED_BUILTINS`) to add it to the workflow.
