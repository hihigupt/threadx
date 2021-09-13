#ifndef CRT0_S
#define CRT0_S

#include "encoding.h"

  .section      .text.entry
  .globl __start
__start:
  j handle_reset

nmi_vector:
  j nmi_vector

trap_vector:
  j exception_handler

handle_reset:
  la t0, exception_handler
  csrw mtvec, t0
  csrwi mstatus, 0
  csrwi mie, 0

  # initialize global pointer
  la gp, _gp

  # initialize stack pointer
  la sp, _stack_top

  la t0, _edata
  la t1, _ebss
_zero_section:
  sw      x0, (t0)
  addi    t0, t0, 4
  blt     t0, t1, _zero_section

  li a0, 0
  li a1, 0
  j main

exit:
    j exit

#endif

  .globl exception_handler
exception_handler :
  /* Save stack */
  addi    sp, sp, -128
  sw      x1, 0x70(sp)                            # Store RA
  csrr    x1, mcause
  bge     x1, x0, error_exceptions                # If negative (msb set), it's a normal interrupt.

  call    _tx_thread_context_save

  csrr    a0, mcause
  csrr    a1, mepc
  mv      a2, sp
  jal     handle_trap

  j       _tx_thread_context_restore

error_exceptions:
  csrr a0, mcause
  csrr a1, mepc
  j     error_exceptions
