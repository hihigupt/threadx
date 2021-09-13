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

    .global     _tx_thread_execute_ptr
    .global     _tx_thread_current_ptr
    .global     _tx_timer_time_slice
    .global     _tx_execution_thread_enter

    ENABLE_SR   =   0x0008                  # Machine interrupts enabled
    
    .section      .text

/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_schedule                                 RISC-V/GNU      */
/*                                                           6.x          */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Scott Larson, Microsoft Corporation                                 */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function waits for a thread control block pointer to appear in */
/*    the _tx_thread_execute_ptr variable.  Once a thread pointer appears */
/*    in the variable, the corresponding thread is resumed.               */
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
/*    _tx_initialize_kernel_enter          ThreadX entry function         */
/*    _tx_thread_system_return             Return to system from thread   */
/*    _tx_thread_context_restore           Restore thread's context       */
/*                                                                        */
/*  RELEASE HISTORY                                                       */
/*                                                                        */
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  xx-xx-xxxx      Scott Larson            Initial Version 6.x           */
/*                                                                        */
/**************************************************************************/
/* VOID   _tx_thread_schedule(VOID) */
/* { */
    .global  _tx_thread_schedule
_tx_thread_schedule:
    /* enable_irq(); while(_tx_thread_execute_ptr == NULL) {} disable_irq();*/
    
    /* Enable interrupts */
    csrsi   mstatus, ENABLE_SR 

    la      t0, _tx_thread_execute_ptr

__tx_thread_schedule_loop:
    lw      t1, (t0)
    beqz    t1, __tx_thread_schedule_loop

    /* Disable interrupts */
    csrci   mstatus, ENABLE_SR 

#ifdef TX_ENABLE_EVENT_LOGGING
    mv      s0, t1                          # Store thread pointer in saved register
    mv      a0, t1                          # Prepare thread pointer as argument
    call    _tx_el_thread_running           # Call event logging routine
    mv      t1, s0                          # Recover thread pointer
#endif

    /* _tx_thread_current_ptr = _tx_thread_execute_ptr; */
    la      t0, _tx_thread_current_ptr
    sw      t1, (t0)

    /* restore _tx_thread_current_ptr stack */
    /* Increment run count */
    lw      t2, 4(t1)
    addi    t2, t2, 1
    sw      t2, 4(t1)
    lw      t3, 24(t1)

    /* _tx_timer_time_slice = _tx_thread_current_ptr->tx_thread_time_slice */
    la      t2, _tx_timer_time_slice
    sw      t3, (t2) 

    /* switch to the thread */
    lw      sp, 8(t1)

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY

    call    _tx_execution_thread_enter      # Call the thread execution enter function
#endif

    lw      t2, (sp)
    beqz    t2, __tx_thread_schedule_sync_restore

    /* interrupt frame */
    lw      t0, 120(sp)
    csrw    mepc, t0
    li      t0, 0x1880
    csrw    mstatus, t0

    lw      s11, 4(sp)
    lw      s10, 8(sp)
    lw      s9, 12(sp)
    lw      s8, 16(sp)
    lw      s7, 20(sp)
    lw      s6, 24(sp)
    lw      s5, 28(sp)
    lw      s4, 32(sp)
    lw      s3, 36(sp)
    lw      s2, 40(sp)
    lw      s1, 44(sp)
    lw      s0, 48(sp)
    lw      t6, 52(sp)
    lw      t5, 56(sp)
    lw      t4, 60(sp)
    lw      t3, 64(sp)
    lw      t2, 68(sp)
    lw      t1, 72(sp)
    lw      t0, 76(sp)
    lw      a7, 80(sp)
    lw      a6, 84(sp)
    lw      a5, 88(sp)
    lw      a4, 92(sp)
    lw      a3, 96(sp)
    lw      a2, 100(sp)
    lw      a1, 104(sp)
    lw      a0, 108(sp)
    lw      ra, 112(sp)

    add     sp, sp, 128

    mret

__tx_thread_schedule_sync_restore:
    /* suspend thread frame */

    lw      s11, 4(sp)
    lw      s10, 8(sp)
    lw      s9, 12(sp)
    lw      s8, 16(sp)
    lw      s7, 20(sp)
    lw      s6, 24(sp)
    lw      s5, 28(sp)
    lw      s4, 32(sp)
    lw      s3, 36(sp)
    lw      s2, 40(sp)
    lw      s1, 44(sp)
    lw      s0, 48(sp)
    lw      ra, 52(sp)
    lw      t0, 56(sp)
    csrw    mstatus, t0

    addi     sp, sp, 64

    ret
