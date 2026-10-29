/* Independent baseline: enumerate all 3-vertex directed graphs with loops;
   quotient by all 6 relabelings; repeat 1000 times. */
#include <stdint.h>
#include <stdio.h>

static uint16_t expand(unsigned compact) {
  uint16_t g=0;
  for (unsigned u=0;u<3;u++) for (unsigned v=0;v<3;v++)
    if (compact & (1u<<(3*u+v))) g |= (uint16_t)(1u<<(4*u+v));
  return g;
}
static uint16_t permute(uint16_t graph, const unsigned p[3]) {
  uint16_t r=0;
  for (unsigned u=0;u<3;u++) for (unsigned v=0;v<3;v++)
    if (graph & (1u<<(4*u+v))) r |= (uint16_t)(1u<<(4*p[u]+p[v]));
  return r;
}
static unsigned count_classes(void) {
  static const unsigned p[6][3]={{0,1,2},{0,2,1},{1,0,2},{1,2,0},{2,0,1},{2,1,0}};
  unsigned count=0;
  for (unsigned i=0;i<512;i++) {
    uint16_t g=expand(i), best=65535;
    for (unsigned j=0;j<6;j++){uint16_t v=permute(g,p[j]);if(v<best)best=v;}
    count += g==best;
  }
  return count;
}
int main(void) {
  unsigned total=0;
  for (unsigned i=0;i<10000;i++) total += count_classes();
  printf("%u\n",total);
  return total==1040000 ? 0 : 1;
}
