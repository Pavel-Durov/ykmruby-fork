#ifndef MRUBY_YK_H
#define MRUBY_YK_H

#include <yk.h>
#include <mruby.h>
#include <mruby/irep.h>

extern YkMT *yk_mt;

void yk_init(void);

void yk_shutdown(void);

YkLocation *yk_init_loc(mrb_state *mrb, const mrb_irep *irep);

void yk_free_loc(mrb_state *mrb, mrb_irep *irep);

mrb_code yk_load_insn(const mrb_code *pc);

static inline mrb_code
yk_fetch(const mrb_code *pc)
{
  if (yk_is_interpreting()) return *pc;
  return yk_load_insn((const mrb_code*)yk_promote((void*)pc));
}

static inline void
mrb_jit_yk_hook(mrb_state *mrb, const mrb_irep *irep, const mrb_code *pc)
{
  YkLocation *locs = (YkLocation*)irep->yk_locs;
  if (!locs) {
    locs = yk_init_loc(mrb, irep);
    ((mrb_irep*)irep)->yk_locs = locs;
  }
  if (!locs) return;
  YkLocation *loc = &locs[(size_t)(pc - irep->iseq)];
  if (yk_is_interpreting()) {
    if (pc == irep->iseq){
      if (!irep->called) {
        ((mrb_irep*)irep)->called = TRUE;
      }
    }
    else if (yk_location_is_null(*loc)) {
      *loc = yk_location_new();
    }
  }
  yk_mt_control_point(yk_mt, loc);
}

#endif /* MRUBY_YK_H */
