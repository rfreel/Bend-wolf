#!/usr/bin/env python3
"""Compare the two whole-process graph-class workloads; emit raw samples."""
import argparse
import hashlib
import json
import pathlib
import platform
import statistics
import subprocess
import time

ROOT = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--bend', default=str(ROOT / 'build/bench_bend'))
parser.add_argument('--reference', default=str(ROOT / 'build/bench_c'))
parser.add_argument('--samples', type=int, default=7)
parser.add_argument('--reference-kind', choices=['generic','optimized'], default='generic')
parser.add_argument('--output', type=pathlib.Path)
args = parser.parse_args()
if not 1 <= args.samples <= 30:
    parser.error('samples must be 1..30')
commands={'bend':[args.bend], 'c':[args.reference]}
def run(name):
    start=time.perf_counter_ns()
    result=subprocess.run(commands[name],check=True,capture_output=True,text=True)
    elapsed=(time.perf_counter_ns()-start)/1e9
    if result.stdout.strip()!='1040000':
        raise RuntimeError(f'{name} produced unexpected result {result.stdout!r}')
    return elapsed
for name in commands: run(name)  # warmup once each
samples={name:[] for name in commands}
for i in range(args.samples):
    order=('bend','c') if i%2==0 else ('c','bend')
    for name in order: samples[name].append(run(name))
medians={name:statistics.median(xs) for name,xs in samples.items()}
report={
    'workload':'10000 repetitions of the number of isomorphism classes among all 512 directed 3-vertex graphs with loops',
    'expected_output':1040000,
    'timing_includes':'whole-process startup and output, excludes build',
    'warmups_per_binary':1,
    'alternating_order':True,
    'samples_seconds':samples,
    'median_seconds':medians,
    'bend_over_c_median':medians['bend']/medians['c'],
    'algorithm_difference':('Bend uses validated fixed bit-mask permutations and direct compact expansion; C independently enumerates vertex permutations' if args.reference_kind=='generic' else 'Bend and C both use fixed bit-mask permutations and direct compact expansion; C uses a volatile offset to prevent loop hoisting'),
    'platform':platform.platform(),
    'source_sha256':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'Graph.bend',ROOT/'Permutations.bend',ROOT/'Bench.bend',ROOT/('bench/reference.c' if args.reference_kind=='generic' else 'bench/reference_optimized.c'))},
}
text=json.dumps(report,indent=2)+'\n'
if args.output: args.output.write_text(text)
print(text,end='')
