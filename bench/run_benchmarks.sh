#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
BEND="${BEND:-bend}"
CLANG="${CLANG:-clang}"
PYTHON="${PYTHON:-python3}"
mkdir -p build
"$BEND" Bench.bend -o build/bench_bend
"$PYTHON" bench/generate_optimized_reference.py
"$CLANG" -O3 -std=c11 bench/reference.c -o build/bench_c
"$CLANG" -O3 -std=c11 bench/reference_optimized.c -o build/bench_c_opt
"$PYTHON" bench/run.py --reference-kind generic --reference ./build/bench_c --output build/benchmark_generic.json
"$PYTHON" bench/run.py --reference-kind optimized --reference ./build/bench_c_opt --output build/benchmark_optimized.json
