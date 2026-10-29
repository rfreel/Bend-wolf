import os,pathlib,shutil,subprocess,tempfile,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
BEND=os.environ.get('BEND','bend'); NODE=os.environ.get('NODE','node')
class CandidateValidationTest(unittest.TestCase):
    def test_mutant_is_compilable_but_rejected(self):
        with tempfile.TemporaryDirectory(prefix='bend-candidate-mutant-') as d:
            tmp=pathlib.Path(d)
            for name in ('Graph.bend','Permutations.bend'): shutil.copy2(ROOT/name,tmp/name)
            p=tmp/'Graph.bend'; source=p.read_text(); needle='case True{}: P.canonical3(edges)'
            control=subprocess.run([BEND,'Graph.bend','-o','Control.mjs'],cwd=tmp,capture_output=True,text=True,timeout=60)
            self.assertEqual(control.returncode,0,control.stdout+control.stderr)
            good=subprocess.run([NODE,str(ROOT/'bench/validate_candidate.mjs'),str(tmp/'Control.mjs')],cwd=ROOT,capture_output=True,text=True,timeout=60)
            self.assertEqual(good.returncode,0,good.stdout+good.stderr)
            self.assertIn('candidate validation passed',good.stdout)
            self.assertEqual(source.count(needle),1)
            p.write_text(source.replace(needle,'case True{}: 0'))
            compiled=subprocess.run([BEND,'Graph.bend','-o','Graph.mjs'],cwd=tmp,capture_output=True,text=True,timeout=60)
            self.assertEqual(compiled.returncode,0,compiled.stdout+compiled.stderr)
            check=subprocess.run([NODE,str(ROOT/'bench/validate_candidate.mjs'),str(tmp/'Graph.mjs')],cwd=ROOT,capture_output=True,text=True,timeout=60)
            self.assertNotEqual(check.returncode,0,check.stdout+check.stderr)
            self.assertIn('candidate mismatch',check.stderr)
if __name__=='__main__':unittest.main()
