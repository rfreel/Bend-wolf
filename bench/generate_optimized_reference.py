#!/usr/bin/env python3
"""Generate an optimized C baseline from the validated mask table."""
import json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools'))
from generate_permutations import generate_specialized
masks=json.loads((root/'evidence/wolfram_masks.json').read_text())
data=json.loads((root/'evidence/wolfram_permutations.json').read_text())
generate_specialized(data,masks)  # independently validate every source/destination bit
out=['#include <stdint.h>','#include <stdio.h>','']
for i,entry in enumerate(masks):
    terms=[]
    for delta,mask in entry['groups']:
        x=f'(e & {mask}u)'
        if delta>0:x=f'({x} << {delta})'
        if delta<0:x=f'({x} >> {-delta})'
        terms.append(x)
    out.append(f'static inline uint32_t r{i}(uint32_t e) {{ return '+ ' | '.join(terms)+'; }')
out += ['''
static inline uint32_t canonical(uint32_t e) {
  uint32_t best=r0(e),x;
  x=r1(e);if(x<best)best=x; x=r2(e);if(x<best)best=x;
  x=r3(e);if(x<best)best=x; x=r4(e);if(x<best)best=x;
  x=r5(e);if(x<best)best=x; return best;
}
static volatile unsigned seed = 0;
#if defined(__GNUC__)
__attribute__((noinline))
#endif
static unsigned count_classes(unsigned offset) {
  unsigned count=0;
  for(unsigned i=0;i<512;i++) {
    unsigned c=(i+offset)&511u;
    uint32_t e=(c&7u)|((c&56u)<<1)|((c&448u)<<2);
    count += canonical(e)==e;
  }
  return count;
}
int main(void) {
  unsigned total=0;
  for(unsigned i=0;i<10000;i++) total += count_classes(seed);
  printf("%u\\n",total);
  return total==1040000 ? 0 : 1;
}
''']
(root/'bench/reference_optimized.c').write_text('\n'.join(out))
