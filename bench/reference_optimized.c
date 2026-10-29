#include <stdint.h>
#include <stdio.h>

static inline uint32_t r0(uint32_t e) { return (e & 1911u); }
static inline uint32_t r1(uint32_t e) { return (e & 1u) | ((e & 2u) << 1) | ((e & 4u) >> 1) | ((e & 16u) << 4) | ((e & 32u) << 5) | ((e & 64u) << 3) | ((e & 256u) >> 4) | ((e & 512u) >> 3) | ((e & 1024u) >> 5); }
static inline uint32_t r2(uint32_t e) { return ((e & 1u) << 5) | ((e & 2u) << 3) | ((e & 4u) << 4) | ((e & 16u) >> 3) | ((e & 32u) >> 5) | ((e & 64u) >> 4) | ((e & 256u) << 1) | ((e & 512u) >> 1) | (e & 1024u); }
static inline uint32_t r3(uint32_t e) { return ((e & 51u) << 5) | ((e & 68u) << 2) | ((e & 768u) >> 7) | ((e & 1024u) >> 10); }
static inline uint32_t r4(uint32_t e) { return ((e & 1u) << 10) | ((e & 6u) << 7) | ((e & 272u) >> 2) | ((e & 1632u) >> 5); }
static inline uint32_t r5(uint32_t e) { return ((e & 1u) << 10) | ((e & 2u) << 8) | ((e & 4u) << 6) | ((e & 16u) << 2) | (e & 32u) | ((e & 64u) >> 2) | ((e & 256u) >> 6) | ((e & 512u) >> 8) | ((e & 1024u) >> 10); }

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
  printf("%u\n",total);
  return total==1040000 ? 0 : 1;
}
