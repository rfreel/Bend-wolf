#!/usr/bin/env python3
"""Emit a Bend checker invocation from a deliberately restricted Boolean IR."""
import argparse
import json
import pathlib
import re

class IRValidationError(ValueError):
    pass

def compile_ir(data):
    if not isinstance(data, dict):
        raise IRValidationError('IR must be an object')
    required = {'schema', 'variables', 'specification', 'candidate'}
    allowed = required | {'condition', 'provenance'}
    if not required <= data.keys() or not data.keys() <= allowed:
        raise IRValidationError('missing or unknown top-level field')
    if data['schema'] != 'bend-boolean-ir/v1':
        raise IRValidationError('unsupported schema')
    names = data['variables']
    if (not isinstance(names, list) or len(names) > 16 or
        any(not isinstance(name, str) or not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*', name) for name in names) or
        len(set(names)) != len(names)):
        raise IRValidationError('variables must be distinct identifiers, at most 16')
    variables = {name: i for i, name in enumerate(names)}
    nodes = [0]
    def emit(node, depth=0):
        nodes[0] += 1
        if depth > 64 or nodes[0] > 1024 or not isinstance(node, dict):
            raise IRValidationError('invalid expression or complexity limit')
        op = node.get('op')
        if op in ('true', 'false') and set(node) == {'op'}:
            return 'L.ETrue{}' if op == 'true' else 'L.EFalse{}'
        if op == 'var' and set(node) == {'op', 'name'}:
            name = node['name']
            if not isinstance(name, str) or name not in variables:
                raise IRValidationError('unknown variable')
            return 'L.EVar{' + str(variables[name]) + '}'
        if op == 'not' and set(node) == {'op', 'arg'}:
            return 'L.ENot{' + emit(node['arg'], depth + 1) + '}'
        if op in ('and', 'or', 'xor') and set(node) == {'op', 'left', 'right'}:
            constructor = {'and':'EAnd', 'or':'EOr', 'xor':'EXor'}[op]
            return 'L.' + constructor + '{' + emit(node['left'], depth + 1) + ', ' + emit(node['right'], depth + 1) + '}'
        raise IRValidationError('unknown operator or invalid fields')
    specification = emit(data['specification'])
    candidate = emit(data['candidate'])
    n = str(len(names)) + 'n'
    if 'condition' in data:
        condition = emit(data['condition'])
        body = f'def main() -> L.Outcome & L.Outcome:\n  (L.satisfy({n}, {condition}), P.under({n}, {condition}, {specification}, {candidate}))\n'
    else:
        body = f'def main() -> L.Outcome:\n  P.check({n}, {specification}, {candidate})\n'
    return 'import Base\nimport ./Logic.bend as L\nimport ./Proof.bend as P\n\n' + body

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=pathlib.Path)
    parser.add_argument('output', type=pathlib.Path, help='Bend file beside Logic.bend and Proof.bend')
    args = parser.parse_args()
    try:
        source = compile_ir(json.loads(args.input.read_text(encoding='utf-8')))
        if args.output.suffix != '.bend':
            raise IRValidationError('output must have a .bend extension')
        args.output.write_text(source, encoding='utf-8')
    except (OSError, json.JSONDecodeError, IRValidationError) as e:
        parser.exit(2, f'IR error: {e}\n')

if __name__ == '__main__': main()
