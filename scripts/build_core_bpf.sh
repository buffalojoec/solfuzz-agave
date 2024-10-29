#!/bin/bash

: "${BPF_PROGRAMS_DIR:=bpf_programs}"
: "${CARGO:=cargo}"

set_core_bpf_vars() {
    case "$1" in
        address-lookup-table)
            CORE_BPF_PROGRAM_ID="AddressLookupTab1e1111111111111111111111111"
            CORE_BPF_TARGET="$BPF_PROGRAMS_DIR/lib/solana_address_lookup_table_program.so"
            ;;
        config)
            CORE_BPF_PROGRAM_ID="Config1111111111111111111111111111111111111"
            CORE_BPF_TARGET="$BPF_PROGRAMS_DIR/lib/solana_config_program.so"
            ;;
        *)
            echo "Invalid argument. Use 'address-lookup-table' or 'config'."
            exit 1
            ;;
    esac
}

set_core_bpf_vars "$1"

RUSTFLAGS="$RUSTFLAGS" FORCE_RECOMPILE=true CORE_BPF_PROGRAM_ID=$CORE_BPF_PROGRAM_ID CORE_BPF_TARGET=$CORE_BPF_TARGET $CARGO build \
    --target x86_64-unknown-linux-gnu \
    --features core-bpf \
    --lib \
    --release
