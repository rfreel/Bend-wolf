import os
import pathlib
import shutil
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parents[1]
bend = os.environ.get('BEND', 'bend')
with tempfile.TemporaryDirectory(prefix='bend-proof-mutation-') as d:
    dst = pathlib.Path(d)
    for name in ('Logic.bend', 'Rewrite.bend', 'LAWS.bend', 'PROOF.bend'):
        shutil.copy2(root / name, dst / name)
    good = subprocess.run([bend, 'PROOF.bend', '--verdict'], cwd=dst, text=True, capture_output=True, timeout=60)
    assert good.returncode == 0 and 'ALL PROOFS CHECK' in good.stdout, (good.returncode, good.stdout, good.stderr)
    path = dst / 'Rewrite.bend'
    source = path.read_text()
    needle = 'case L.ENot{inner}: inner'
    assert source.count(needle) == 1
    path.write_text(source.replace(needle, 'case L.ENot{inner}: L.ENot{inner}'))
    compile_only = subprocess.run([bend, 'Rewrite.bend', '--check-only'], cwd=dst, text=True, capture_output=True, timeout=60)
    assert compile_only.returncode == 0, (compile_only.stdout, compile_only.stderr)
    bad = subprocess.run([bend, 'PROOF.bend', '--verdict'], cwd=dst, text=True, capture_output=True, timeout=60)
    assert bad.returncode != 0 and 'SOME PROOFS FAIL' in (bad.stdout + bad.stderr), (bad.returncode, bad.stdout, bad.stderr)
    assert 'simplify_double_negation' in (bad.stdout + bad.stderr), (bad.stdout, bad.stderr)
    # A wrong expression in the dependent proof-carrying result must also fail.
    shutil.copy2(root / 'Rewrite.bend', dst / 'Rewrite.bend')
    proof_path=dst / 'PROOF.bend'
    proof=proof_path.read_text(); needle='(R.simplify(expr), assignment => Laws.simplify_sound(expr, assignment))'
    assert proof.count(needle)==1
    proof_path.write_text(proof.replace(needle,'(L.ETrue{}, assignment => Laws.simplify_sound(expr, assignment))'))
    wrong=subprocess.run([bend, 'PROOF.bend', '--verdict'], cwd=dst, text=True, capture_output=True, timeout=60)
    assert wrong.returncode != 0 and 'verified_simplification' in (wrong.stdout+wrong.stderr), (wrong.stdout,wrong.stderr)
    print('proof mutation and wrong certified result rejected; unmutated proof passed')
