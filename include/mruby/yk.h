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

extern YkLocation yk_null_loc;

/* `locs` is irep->yk_locs, already initialised by the caller (see
   yk_irep_locs()), so a trace doesn't guard on it at every instruction. */
static inline void
mrb_jit_yk_hook(mrb_state *mrb, const mrb_irep *irep, YkLocation *locs, const mrb_code *pc)
{
  YkLocation *loc = &locs[(size_t)(pc - irep->iseq)];
  if (yk_is_interpreting()) {
    if (pc == irep->iseq) {
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

/* An executing irep has ilen > 0, so this never returns NULL. */
static inline YkLocation*
yk_irep_locs(mrb_state *mrb, const mrb_irep *irep)
{
  if (!irep->yk_locs) {
    ((mrb_irep*)irep)->yk_locs = yk_init_loc(mrb, irep);
  }
  return (YkLocation*)irep->yk_locs;
}

#endif /* MRUBY_YK_H */
