#!/usr/bin/env python3
"""Validate and benchmark four existing Bend graph implementations; never promote one."""
import argparse,hashlib,json,os,pathlib,statistics,subprocess,tempfile,time
ROOT=pathlib.Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--samples',type=int,default=5)
parser.add_argument('--output',type=pathlib.Path)
args=parser.parse_args()
if not 1<=args.samples<=15:parser.error('samples must be 1..15')
bend=os.environ.get('BEND','bend');node=os.environ.get('NODE','node')
variants=[('baseline','bench/baseline/Bench.bend'),('permutations','bench/optimized_v1/Bench.bend'),('masked','bench/specialized_v2/Bench.bend'),('compact','bench/scale/Bench1000.bend')]
records=[]
with tempfile.TemporaryDirectory(prefix='bend-candidate-search-') as d:
    tmp=pathlib.Path(d)
    for name,entry in variants:
        source=ROOT/entry; graph=source.parent/'Graph.bend'; module=tmp/(name+'.mjs'); binary=tmp/(name+'.bin')
        r={'name':name,'source':entry,'graph_sha256':hashlib.sha256(graph.read_bytes()).hexdigest()}
        try:
            checks=[([bend,str(graph),'-o',str(module)],'compile_module'),([node,str(ROOT/'bench/validate_candidate.mjs'),str(module)],'validate'),([bend,str(source),'-o',str(binary)],'compile_native')]
            for command,label in checks:
                p=subprocess.run(command,capture_output=True,text=True,timeout=60,cwd=ROOT)
                if p.returncode: raise RuntimeError(f'{label} failed: {(p.stdout+p.stderr)[-800:]}')
            r['status']='validated';r['binary']=str(binary);r['samples_seconds']=[]
        except (OSError,subprocess.TimeoutExpired,RuntimeError) as e:r.update(status='rejected',reason=str(e))
        records.append(r)
    def run(r):
        start=time.perf_counter_ns();p=subprocess.run([r['binary']],capture_output=True,text=True,timeout=60)
        if p.returncode or p.stdout.strip()!='104000':raise RuntimeError(f'{r["name"]} produced an invalid result')
        return (time.perf_counter_ns()-start)/1e9
    eligible=[r for r in records if r['status']=='validated']
    for r in eligible:
        try:run(r)
        except (OSError,subprocess.TimeoutExpired,RuntimeError) as e:r.update(status='rejected',reason=str(e))
    eligible=[r for r in records if r['status']=='validated']
    for i in range(args.samples):
        order=eligible[i%len(eligible):]+eligible[:i%len(eligible)] if eligible else []
        for r in order:
            if r['status']!='validated':continue
            try:r['samples_seconds'].append(run(r))
            except (OSError,subprocess.TimeoutExpired,RuntimeError) as e:r.update(status='rejected',reason=str(e))
    eligible=[r for r in records if r['status']=='validated' and len(r['samples_seconds'])==args.samples]
    for r in eligible:r['median_seconds']=statistics.median(r['samples_seconds'])
    winner=min(eligible,key=lambda r:r['median_seconds'])['name'] if eligible else None
    for r in records:r.pop('binary',None)
    report={'workload':'1000 repetitions, all 512 directed 3-vertex graphs with loops','validation':'independent exhaustive canonical keys plus count, prior to benchmarking','timing':'whole-process startup and output, one warmup, rotated candidate order','samples':args.samples,'winner':winner,'promotion':'none','candidates':records}
    text=json.dumps(report,indent=2)+'\n'
    if args.output:args.output.write_text(text)
    print(text,end='')
    if winner is None:raise SystemExit(1)
