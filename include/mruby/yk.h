#ifndef MRUBY_YK_H
#define MRUBY_YK_H

#ifdef USE_YK
#include <yk.h>
#include <mruby.h>
#include <mruby/irep.h>

extern YkMT *yk_mt;

void yk_init(void);

void yk_shutdown(void);

YkLocation *yk_init_loc(mrb_state *mrb, const mrb_irep *irep);

void yk_free_loc(mrb_state *mrb, mrb_irep *irep);

extern YkLocation yk_null_loc;

/* mrb_yk_iseq_gen increased whenever an iseq is freed.
  Its used as idempotent key for bytecode fetching in the dispatch loop.*/
extern uint32_t mrb_yk_iseq_gen;

static inline void
mrb_jit_yk_hook(mrb_state *mrb, const mrb_irep *irep, const mrb_code *pc)
{
  YkLocation *loc = &((YkLocation*)irep->yk_locs)[(size_t)(pc - irep->iseq)];
  /* As in yklua: a function entered again while it already has an active
     frame is recursing, so its entry gets a location and each recursive call
     becomes a trace boundary instead of unrolling into the caller's trace.
     The `yk_is_interpreting()` check comes first so a trace never evaluates
     `pc == irep->iseq`. */
  if (yk_is_interpreting() && pc == irep->iseq) {
    if (irep->called && yk_location_is_null(*loc)) {
      *loc = yk_location_new();
    }
    else if (!irep->called) {
      ((mrb_irep*)irep)->called = TRUE;
    }
  }
  yk_mt_control_point(yk_mt, loc);
}

#endif /* USE_YK */
#endif /* MRUBY_YK_H */
