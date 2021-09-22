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
/*    _tx_thread_context_save                          RISC-V/SoftConsole */
/*                                                           6.0          */
/*  AUTHOR                                                                */
/*                                                                        */
/*    William E. Lamie, Microsoft Corporation                             */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */ 
/*    This function saves the context of an executing thread in the       */ 
/*    beginning of interrupt processing.  The function also ensures that  */ 
/*    the system stack is used upon return to the calling ISR.            */ 
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
/*    None                                                                */ 
/*                                                                        */ 
/*  CALLED BY                                                             */ 
/*                                                                        */ 
/*    ISRs                                                                */ 
/*                                                                        */ 
/*  RELEASE HISTORY                                                       */ 
/*                                                                        */ 
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  05-19-2020     William E. Lamie         Initial Version 6.0           */
/*                                                                        */
/**************************************************************************/
/* VOID   _tx_thread_context_save(VOID)
{  */
    .globl _tx_thread_context_save
_tx_thread_context_save:

    /* Save all the temporary registers */
    sw      x7, 0x44(sp)                    # Store t2
    sw      x10, 0x6C(sp)                   # Store a0
    sw      x11, 0x68(sp)                   # Store a1
    sw      x12, 0x64(sp)                   # Store a2
    sw      x13, 0x60(sp)                   # Store a3
    sw      x14, 0x5C(sp)                   # Store a4
    sw      x15, 0x58(sp)                   # Store a5
    sw      x16, 0x54(sp)                   # Store a6
    sw      x17, 0x50(sp)                   # Store a7
    sw      x5, 0x4C(sp)                    # Store t0 
    sw      x6, 0x48(sp)                    # Store t1
    sw      x28, 0x40(sp)                   # Store t3
    sw      x29, 0x3C(sp)                   # Store t4
    sw      x30, 0x38(sp)                   # Store t5
    sw      x31, 0x34(sp)                   # Store t6
    csrr    t0, mepc                        # Load exception program counter
    sw      t0, 0x78(sp)                    # Save it on the stack


#if __riscv_32e

    /* Save floating point scratch registers.  */
    
    fsw     f0, 0x7C(sp)                    # Store ft0
    fsw     f1, 0x80(sp)                    # Store ft1
    fsw     f2, 0x84(sp)                    # Store ft2
    fsw     f3, 0x88(sp)                    # Store ft3
    fsw     f4, 0x8C(sp)                    # Store ft4
    fsw     f5, 0x90(sp)                    # Store ft5
    fsw     f6, 0x94(sp)                    # Store ft6
    fsw     f7, 0x98(sp)                    # Store ft7
    fsw     f10,0xA4(sp)                    # Store fa0
    fsw     f11,0xA8(sp)                    # Store fa1
    fsw     f12,0xAC(sp)                    # Store fa2
    fsw     f13,0xB0(sp)                    # Store fa3
    fsw     f14,0xB4(sp)                    # Store fa4
    fsw     f15,0xB8(sp)                    # Store fa5
    fsw     f16,0xBC(sp)                    # Store fa6
    fsw     f17,0xC0(sp)                    # Store fa7
    fsw     f28,0xEC(sp)                    # Store ft8
    fsw     f29,0xF0(sp)                    # Store ft9
    fsw     f30,0xF4(sp)                    # Store ft10
    fsw     f31,0xF8(sp)                    # Store ft11
    csrr    t0, fcsr 
    sw      t0, 0xFC(sp)                    # Store fcsr
#endif

    la      t0, _tx_thread_system_state
    lw      t1, (t0)
    add     t2, t1, 1
    sw      t2, (t0)
    beqz    t1, _tx_thread_context_save_context
    /* if (_tx_thread_system_state++) {*/

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY
    call    _tx_execution_isr_enter         # Call the ISR execution enter function
#endif

    ret
    /*}*/
_tx_thread_context_save_context:
    la      t0, _tx_thread_current_ptr
    lw      t1, (t0)
    beqz    t1, _tx_thread_context_save_idle_context
    /*else if (_tx_thread_current_ptr != NULL) {*/
    
    sw      sp, 8(t1)

    lw      sp, _tx_thread_system_stack_ptr # Switch to system stack
#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY
    call    _tx_execution_isr_enter         # Call the ISR execution enter function
#endif

    ret
    /*}*/
_tx_thread_context_save_idle_context:
    /*else {*/

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY
    call    _tx_execution_isr_enter         # Call the ISR execution enter function
#endif

    ret
    /*}*/
