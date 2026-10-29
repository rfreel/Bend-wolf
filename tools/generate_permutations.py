#!/usr/bin/env python3
"""Validate Wolfram's small permutation table and emit a Bend lookup module."""
import argparse
import itertools
import json
import pathlib

class ValidationError(ValueError): pass

def generate(data):
    tables=data.get('tables') if isinstance(data,dict) else None
    if not isinstance(tables,list) or len(tables)!=5:
        raise ValidationError('expected five tables')
    for n,values in enumerate(tables):
        if not isinstance(values,list) or any(type(x) is not int for x in values):
            raise ValidationError(f'table {n} must contain integers')
        expected={sum(x*(4**i) for i,x in enumerate(p)) for p in itertools.permutations(range(n))}
        if len(values)!=len(expected) or set(values)!=expected:
            raise ValidationError(f'table {n} is not exactly the vertex permutations')
    out=['import Base', '', '# Generated from a Wolfram result; generator independently verifies every permutation.']
    for n,values in enumerate(tables):
        out += [f'def get{n}(index: U32) -> U32:', '  match index:']
        out.extend(f'    case {i}: {value}' for i,value in enumerate(values))
        out += ['    case _: 0', '']
    out += ['def get(n: Nat, index: U32) -> U32:', '  match n:']
    out.extend(f'    case {n}n: get{n}(index)' for n in range(5))
    out += ['    case _: 0', '', 'def count(n: Nat) -> Nat:', '  match n:']
    out.extend(f'    case {n}n: {len(values)}n' for n,values in enumerate(tables))
    out += ['    case _: 0n', '']
    return '\n'.join(out)

def generate_specialized(data, masks):
    generate(data)  # validate the permutation table first
    if not isinstance(masks,list) or len(masks)!=6:
        raise ValidationError('expected six 3-vertex mask groups')
    if [m.get('code') if isinstance(m,dict) else None for m in masks] != data['tables'][3]:
        raise ValidationError('mask codes disagree with permutation table')
    out=[]
    source_positions={4*u+v for u in range(3) for v in range(3)}
    for i,entry in enumerate(masks):
        code=entry['code']
        mapping=[(code>>(2*u))&3 for u in range(3)]
        groups=entry.get('groups')
        if not isinstance(groups,list): raise ValidationError('missing groups')
        covered=set(); terms=[]; deltas=set()
        for group in groups:
            if not isinstance(group,list) or len(group)!=2 or any(type(x) is not int for x in group):
                raise ValidationError('invalid group')
            delta,mask=group
            if delta in deltas or not -15<=delta<=15 or mask<=0 or mask>=65536:
                raise ValidationError('invalid mask or shift')
            deltas.add(delta)
            positions={pos for pos in range(16) if mask&(1<<pos)}
            if not positions <= source_positions or covered & positions:
                raise ValidationError('overlapping or out-of-domain bits')
            for pos in positions:
                u,v=divmod(pos,4)
                if pos+delta != 4*mapping[u]+mapping[v]:
                    raise ValidationError('mask does not implement the permutation')
            covered |= positions
            term=f'U32.and(edges, {mask})'
            if delta>0: term=f'U32.shln({term}, {delta}n)'
            if delta<0: term=f'U32.shrn({term}, {-delta}n)'
            terms.append(term)
        if covered!=source_positions: raise ValidationError('incomplete mask')
        expression=terms[0]
        for term in terms[1:]: expression=f'U32.or({expression}, {term})'
        out.extend([f'def relabel3_{i}(+edges: U32) -> U32:', f'  {expression}', ''])
    expression='relabel3_0(edges)'
    for i in range(1,6): expression=f'U32.min({expression}, relabel3_{i}(edges))'
    out.extend(['def canonical3(+edges: U32) -> U32:', f'  {expression}', ''])
    return '\n'.join(out)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('input',type=pathlib.Path);p.add_argument('output',type=pathlib.Path)
    p.add_argument('--masks',type=pathlib.Path)
    args=p.parse_args()
    try:
        data=json.loads(args.input.read_text(encoding='utf-8'))
        source=generate(data)
        if args.masks: source += '\n' + generate_specialized(data,json.loads(args.masks.read_text(encoding='utf-8')))
        args.output.write_text(source,encoding='utf-8')
    except (OSError, json.JSONDecodeError, ValidationError) as e: p.exit(2,f'permutation table error: {e}\n')
if __name__=='__main__':main()
