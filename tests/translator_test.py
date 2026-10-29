import json, os, pathlib, shutil, subprocess, sys, tempfile, unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from emit_bend import compile_ir, IRValidationError

class TranslatorTest(unittest.TestCase):
    def setUp(self):
        self.case = json.loads((ROOT / 'evidence/wolfram_boolean_ir.json').read_text())
    def test_wolfram_ir_is_rendered(self):
        text = compile_ir(self.case)
        self.assertIn('L.EVar{0}', text)
        self.assertIn('P.check(2n,', text)
    def test_end_to_end_rejects_bad_wolfram_candidate(self):
        bend=os.environ.get('BEND','bend')
        with tempfile.TemporaryDirectory(prefix='bend-ir-test-') as d:
            tmp=pathlib.Path(d)
            for name in ('Logic.bend','Rewrite.bend','Proof.bend'): shutil.copy2(ROOT/name,tmp/name)
            self.case['candidate']={'op':'true'}
            (tmp/'Check.bend').write_text(compile_ir(self.case))
            p=subprocess.run([bend,'Check.bend'],cwd=tmp,text=True,capture_output=True,timeout=60)
            self.assertEqual(p.returncode,0,p.stdout+p.stderr)
            self.assertIn('Different{0}',p.stdout)
    def test_unsatisfiable_condition_is_visible(self):
        bend=os.environ.get('BEND','bend')
        with tempfile.TemporaryDirectory(prefix='bend-ir-test-') as d:
            tmp=pathlib.Path(d)
            for name in ('Logic.bend','Rewrite.bend','Proof.bend'): shutil.copy2(ROOT/name,tmp/name)
            self.case['condition']={'op':'false'}
            (tmp/'Check.bend').write_text(compile_ir(self.case))
            p=subprocess.run([bend,'Check.bend'],cwd=tmp,text=True,capture_output=True,timeout=60)
            self.assertEqual(p.returncode,0,p.stdout+p.stderr)
            self.assertIn('Unsat{}',p.stdout)
            self.assertIn('Equivalent{}',p.stdout)
    def test_unknown_variable_rejected(self):
        self.case['candidate'] = {'op': 'var', 'name': 'a}; evil'}
        with self.assertRaises(IRValidationError): compile_ir(self.case)
    def test_unknown_operator_rejected(self):
        self.case['candidate'] = {'op': 'eval', 'arg':'evil'}
        with self.assertRaises(IRValidationError): compile_ir(self.case)
    def test_duplicate_variables_rejected(self):
        self.case['variables'] = ['a','a']
        with self.assertRaises(IRValidationError): compile_ir(self.case)
    def test_domain_bound_rejected(self):
        self.case['variables'] = [f'x{i}' for i in range(17)]
        with self.assertRaises(IRValidationError): compile_ir(self.case)
    def test_condition_kept(self):
        self.case['condition'] = {'op':'var','name':'a'}
        self.assertIn('P.under(2n,', compile_ir(self.case))
    def test_extra_node_fields_rejected(self):
        self.case['candidate']['evil'] = 'untrusted code'
        with self.assertRaises(IRValidationError): compile_ir(self.case)
if __name__ == '__main__': unittest.main()
