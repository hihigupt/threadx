/**************************************************************************/
/*                                                                        */
/*       Copyright (c) Microsoft Corporation. All rights reserved.        */
/*                                                                        */
/*       This software is licensed under the Microsoft Software License   */
/*       Terms for Microsoft Azure RTOS. Full text of the license can be  */
/*       found in the LICENSE file at https://aka.ms/AzureRTOS_EULA       */
/*       and in the root directory of this software.                      */
/*                                                                        */
/**************************************************************************/


/**************************************************************************/
/**************************************************************************/
/**                                                                       */ 
/** ThreadX Component                                                     */ 
/**                                                                       */
/**   Thread                                                              */
/**                                                                       */
/**************************************************************************/
/**************************************************************************/


/* #define TX_SOURCE_CODE  */


/* Include necessary system files.  */

/*  #include "tx_api.h"
    #include "tx_thread.h"
    #include "tx_timer.h"  */

    .text
/**************************************************************************/ 
/*                                                                        */ 
/*  FUNCTION                                               RELEASE        */ 
/*                                                                        */ 
/*    _tx_thread_context_restore                       RISC-V/SoftConsole */
/*                                                           6.0          */
/*  AUTHOR                                                                */
/*                                                                        */
/*    William E. Lamie, Microsoft Corporation                             */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */ 
/*    This function restores the interrupt context if it is processing a  */ 
/*    nested interrupt.  If not, it returns to the interrupt thread if no */ 
/*    preemption is necessary.  Otherwise, if preemption is necessary or  */ 
/*    if no thread was running, the function returns to the scheduler.    */ 
/*                                                                        */ 
/*  INPUT                                                                 */ 
/*                                                                        */ 
/*    None                                                                */ 
/*                                                                        */ 
/*  OUTPUT                                                                */ 
/*                                                                        */ 
/*    None                                                                */ 
/*                                                                        */ 
/*  CALLS                                                                 */ 
/*                                                                        */ 
/*    _tx_thread_schedule                   Thread scheduling routine     */ 
/*                                                                        */ 
/*  CALLED BY                                                             */ 
/*                                                                        */ 
/*    ISRs                                  Interrupt Service Routines    */ 
/*                                                                        */ 
/*  RELEASE HISTORY                                                       */ 
/*                                                                        */ 
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  05-19-2020     William E. Lamie         Initial Version 6.0           */
/*                                                                        */
/**************************************************************************/
/* VOID   _tx_thread_context_restore(VOID)
{  */
    .globl  _tx_thread_context_restore
_tx_thread_context_restore:

    /* Lock the interrupts */
    csrci   mstatus, 0x00000008

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY
    call    _tx_execution_isr_exit              # Call the ISR execution exit function
#endif

    la      t0, _tx_thread_system_state         # Pickup addr of nested interrupt count
    lw      t1, (t0)                            # Pickup nested interrupt count

    addi    t1, t1, -1                          # Decrement the nested interrupt counter
    sw      t1, (t0)                            # Store new nested count
    beqz    t1, _tx_thread_not_nested_restore   # If 0, not nested restore

    /* if (--_tx_thread_system_state) { */

#if __riscv_32e
    /* Recover floating point registers.  */

    flw     f0, 0x7C(sp)                        # Recover ft0
    flw     f1, 0x80(sp)                        # Recover ft1
    flw     f2, 0x84(sp)                        # Recover ft2
    flw     f3, 0x88(sp)                        # Recover ft3
    flw     f4, 0x8C(sp)                        # Recover ft4
    flw     f5, 0x90(sp)                        # Recover ft5
    flw     f6, 0x94(sp)                        # Recover ft6
    flw     f7, 0x98(sp)                        # Recover ft7
    flw     f10,0xA4(sp)                        # Recover fa0
    flw     f11,0xA8(sp)                        # Recover fa1
    flw     f12,0xAC(sp)                        # Recover fa2
    flw     f13,0xB0(sp)                        # Recover fa3
    flw     f14,0xB4(sp)                        # Recover fa4
    flw     f15,0xB8(sp)                        # Recover fa5
    flw     f16,0xBC(sp)                        # Recover fa6
    flw     f17,0xC0(sp)                        # Recover fa7
    flw     f28,0xEC(sp)                        # Recover ft8
    flw     f29,0xF0(sp)                        # Recover ft9
    flw     f30,0xF4(sp)                        # Recover ft10
    flw     f31,0xF8(sp)                        # Recover ft11
    lw      t0, 0xFC(sp)                        # Recover fcsr
    csrw    fcsr, t0                            # 
#endif

    lw      t0, 0x78(sp)                        # Recover mepc
    csrw    mepc, t0                            # Setup mepc
    li      t0, 0x1880                          # Prepare MPIP
    csrw    mstatus, t0                         # Enable MPIP

    /* Restore temporary registers */
    lw      x1, 0x70(sp)                        # Recover RA
    lw      x5, 0x4C(sp)                        # Recover t0
    lw      x6, 0x48(sp)                        # Recover t1
    lw      x7, 0x44(sp)                        # Recover t2
    lw      x10, 0x6C(sp)                       # Recover a0
    lw      x11, 0x68(sp)                       # Recover a1
    lw      x12, 0x64(sp)                       # Recover a2
    lw      x13, 0x60(sp)                       # Recover a3
    lw      x14, 0x5C(sp)                       # Recover a4
    lw      x15, 0x58(sp)                       # Recover a5
    lw      x16, 0x54(sp)                       # Recover a6
    lw      x17, 0x50(sp)                       # Recover a7
    lw      x28, 0x40(sp)                       # Recover t3
    lw      x29, 0x3C(sp)                       # Recover t4
    lw      x30, 0x38(sp)                       # Recover t5
    lw      x31, 0x34(sp)                       # Recover t6

#if __riscv_32e
    addi    sp, sp, 260                         # Recover stack frame with floating point enabled
#else
    addi    sp, sp, 128                         # Recover stack frame
#endif

    mret                                        # Return to point of interrupt

    /*} else {*/
_tx_thread_not_nested_restore:
    la      t0, _tx_thread_current_ptr
    lw      t1, (t0)
    bnez    t1, _tx_thread_context_restore_check_switch

    /* if (_tx_thread_current_ptr == NULL) {*/
    /* Remove the old frame */

#if __riscv_32e
    addi    sp, sp, 260                         # Recover stack frame with floating point enabled
#else
    addi    sp, sp, 128                         # Recover stack frame
#endif

    j       _tx_thread_context_restore_idle_restore

    /*} else if (_tx_thread_current_ptr == _tx_thread_execute_ptr ||
                 _tx_thread_preempt_disable) {*/
_tx_thread_context_restore_check_switch:
    la      t2, _tx_thread_execute_ptr
    lw      t3, (t2)
    beq     t1, t3, _tx_thread_context_restore_no_preemption

    la      t2, _tx_thread_preempt_disable
    lw      t3, (t2)
    beqz    t3, _tx_thread_context_restore_switch
    
_tx_thread_context_restore_no_preemption:    
    lw      sp, 8(t1)

#if __riscv_32e

    /* Recover floating point registers.  */

    flw     f0, 0x7C(sp)                        # Recover ft0
    flw     f1, 0x80(sp)                        # Recover ft1
    flw     f2, 0x84(sp)                        # Recover ft2
    flw     f3, 0x88(sp)                        # Recover ft3
    flw     f4, 0x8C(sp)                        # Recover ft4
    flw     f5, 0x90(sp)                        # Recover ft5
    flw     f6, 0x94(sp)                        # Recover ft6
    flw     f7, 0x98(sp)                        # Recover ft7
    flw     f10,0xA4(sp)                        # Recover fa0
    flw     f11,0xA8(sp)                        # Recover fa1
    flw     f12,0xAC(sp)                        # Recover fa2
    flw     f13,0xB0(sp)                        # Recover fa3
    flw     f14,0xB4(sp)                        # Recover fa4
    flw     f15,0xB8(sp)                        # Recover fa5
    flw     f16,0xBC(sp)                        # Recover fa6
    flw     f17,0xC0(sp)                        # Recover fa7
    flw     f28,0xEC(sp)                        # Recover ft8
    flw     f29,0xF0(sp)                        # Recover ft9
    flw     f30,0xF4(sp)                        # Recover ft10
    flw     f31,0xF8(sp)                        # Recover ft11
    lw      t0, 0xFC(sp)                        # Recover fcsr
    csrw    fcsr, t0                            # 
#endif

    lw      t0, 0x78(sp)                        # Recover mepc
    csrw    mepc, t0                            # Setup mepc
    li      t0, 0x1880                          # Prepare MPIP
    csrw    mstatus, t0                         # Enable MPIP

    /* Restore temporary registers */
    lw      x1, 0x70(sp)                        # Recover RA
    lw      x5, 0x4C(sp)                        # Recover t0
    lw      x6, 0x48(sp)                        # Recover t1
    lw      x7, 0x44(sp)                        # Recover t2
    lw      x10, 0x6C(sp)                       # Recover a0
    lw      x11, 0x68(sp)                       # Recover a1
    lw      x12, 0x64(sp)                       # Recover a2
    lw      x13, 0x60(sp)                       # Recover a3
    lw      x14, 0x5C(sp)                       # Recover a4
    lw      x15, 0x58(sp)                       # Recover a5
    lw      x16, 0x54(sp)                       # Recover a6
    lw      x17, 0x50(sp)                       # Recover a7
    lw      x28, 0x40(sp)                       # Recover t3
    lw      x29, 0x3C(sp)                       # Recover t4
    lw      x30, 0x38(sp)                       # Recover t5
    lw      x31, 0x34(sp)                       # Recover t6

#if __riscv_32e
    addi    sp, sp, 260                         # Recover stack frame with floating point enabled
#else
    addi    sp, sp, 128                         # Recover stack frame
#endif
    mret                                        # Return to point of interrupt

    /*} else {*/
_tx_thread_context_restore_switch:

    /* Save rest of register and update slice before clearing _tx_thread_current_ptr */
    lw      t0, 8(t1)
    ori     t3, x0, 1                           # Build interrupt stack type
    sw      t3, (t0)

#if __riscv_32e

    /* Store floating point preserved registers.  */
 
    fsw     f8,  0x9C(t0)                       # Store fs0
    fsw     f9,  0xA0(t0)                       # Store fs1
    fsw     f18, 0xC4(t0)                       # Store fs2
    fsw     f19, 0xC8(t0)                       # Store fs3
    fsw     f20, 0xCC(t0)                       # Store fs4
    fsw     f21, 0xD0(t0)                       # Store fs5
    fsw     f22, 0xD4(t0)                       # Store fs6
    fsw     f23, 0xD8(t0)                       # Store fs7
    fsw     f24, 0xDC(t0)                       # Store fs8
    fsw     f25, 0xE0(t0)                       # Store fs9
    fsw     f26, 0xE4(t0)                       # Store fs10
    fsw     f27, 0xE8(t0)                       # Store fs11
#endif

    sw      x8, 0x30(t0)                        # Store s0
    sw      x9, 0x2C(t0)                        # Store s1
    sw      x18, 0x28(t0)                       # Store s2
    sw      x19, 0x24(t0)                       # Store s3
    sw      x20, 0x20(t0)                       # Store s4
    sw      x21, 0x1C(t0)                       # Store s5
    sw      x22, 0x18(t0)                       # Store s6
    sw      x23, 0x14(t0)                       # Store s7
    sw      x24, 0x10(t0)                       # Store s8
    sw      x25, 0x0C(t0)                       # Store s9
    sw      x26, 0x08(t0)                       # Store s10
    sw      x27, 0x04(t0)                       # Store s11

/* Add logging */
#ifdef TX_ENABLE_EVENT_LOGGING
    mv      s0, t1                              # Save thread pointer into non-volatile
    mv      a0, t1                              # Move thread pointer into input register
    call    _tx_el_thread_preempted             # Call event logging routine
    mv      t1, s0                              # Recover thread pointer
#endif

    la      t0, _tx_timer_time_slice
    lw      t2, (t0)
    beqz    t2, _tx_thread_context_restore_dont_save_ts
    /* if (_tx_timer_time_slice) { */
    /*  _tx_thread_current_ptr -> tx_thread_time_slice = _tx_timer_time_slice */
    /*  _tx_timer_time_slice = 0 */
    sw      t2, 24(t1)
    sw      x0, (t0)

    /*}*/
_tx_thread_context_restore_dont_save_ts:
    
    /* _tx_thread_current_ptr = NULL */
    sw      x0, _tx_thread_current_ptr, t0

_tx_thread_context_restore_idle_restore:
    /* Virtual fram should be created here */
    j       _tx_thread_schedule
    /*}
    }*/
