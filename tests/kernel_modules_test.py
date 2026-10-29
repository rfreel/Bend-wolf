import os,pathlib,subprocess,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
BEND=os.environ.get('BEND','bend')
class KernelModuleTest(unittest.TestCase):
    def test_modules_recheck(self):
        for name in ('Logic.bend','Rewrite.bend','Arithmetic.bend','Permutations.bend','Graph.bend','Dynamics.bend','Inference.bend','Optimize.bend','Abstract.bend','Proof.bend','Synthesis.bend','Research.bend','Pattern.bend','Quantify.bend'):
            with self.subTest(module=name):
                p=subprocess.run([BEND,name,'--verdict'],cwd=ROOT,text=True,capture_output=True,timeout=60)
                self.assertEqual(p.returncode,0,p.stdout+p.stderr)
                self.assertIn('ALL PROOFS CHECK',p.stdout+p.stderr)
if __name__=='__main__': unittest.main()
