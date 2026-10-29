import json, pathlib, sys, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from generate_permutations import generate, generate_specialized, ValidationError
class TestPermutations(unittest.TestCase):
    def setUp(self): self.data=json.loads((ROOT/'evidence/wolfram_permutations.json').read_text())
    def test_valid(self):
        text=generate(self.data)
        self.assertIn('def get3(',text)
        self.assertIn('case 5: 6',text)
    def test_specialization(self):
        masks=json.loads((ROOT/'evidence/wolfram_masks.json').read_text())
        self.assertIn('def canonical3(',generate_specialized(self.data,masks))
    def test_bad_mask_rejected(self):
        masks=json.loads((ROOT/'evidence/wolfram_masks.json').read_text())
        masks[0]['groups'][0][1] -= 1
        with self.assertRaises(ValidationError): generate_specialized(self.data,masks)
    def test_duplicate_rejected(self):
        self.data['tables'][3][0]=self.data['tables'][3][1]
        with self.assertRaises(ValidationError): generate(self.data)
    def test_out_of_range_rejected(self):
        self.data['tables'][4][0]=256
        with self.assertRaises(ValidationError): generate(self.data)
if __name__=='__main__': unittest.main()
