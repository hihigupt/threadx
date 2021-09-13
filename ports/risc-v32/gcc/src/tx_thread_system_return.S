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

    ENABLE_SR   =   0x0008                  # Machine interrupts enabled
    
    .section      .text

/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_system_return                            RISC-V/GNU      */
/*                                                           6.x          */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Scott Larson, Microsoft Corporation                                 */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function is target processor specific.  It is used to transfer */
/*    control from a thread back to the ThreadX system.  Only a           */
/*    minimal context is saved since the compiler assumes temp registers  */
/*    are going to get slicked by a function call anyway.                 */
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
/*    _tx_thread_schedule                   Thread scheduling loop        */
/*                                                                        */
/*  CALLED BY                                                             */
/*                                                                        */
/*    ThreadX components                                                  */
/*                                                                        */
/*  RELEASE HISTORY                                                       */
/*                                                                        */
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  xx-xx-xxxx      Scott Larson            Initial Version 6.x           */
/*                                                                        */
/**************************************************************************/
/*  VOID   _tx_thread_system_return(VOID) */
/*  { */
    .global  _tx_thread_system_return
_tx_thread_system_return:

    addi    sp, sp, -64

    sw      x0, (sp)
    sw      s11,4(sp)
    sw      s10, 8(sp)
    sw      s9, 12(sp)
    sw      s8, 16(sp)
    sw      s7, 20(sp)
    sw      s6, 24(sp)
    sw      s5, 28(sp)
    sw      s4, 32(sp)
    sw      s3, 36(sp)
    sw      s2, 40(sp)
    sw      s1, 44(sp)
    sw      s0, 48(sp)
    sw      ra, 52(sp)
    csrr    t0, mstatus
    sw      t0, 56(sp)

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY

    call    _tx_execution_thread_exit       # Call the thread execution exit function
#endif

    /* Lockout interrupts. - will be enabled in _tx_thread_schedule */
    csrci   mstatus, 0xF              # Disable interrupts

    /* _tx_thread_current_ptr->tx_thread_stack_ptr = sp */
    /* sp = _tx_thread_system_stack_ptr */
    la      t0, _tx_thread_current_ptr
    lw      t1, (t0)
    la      t2, _tx_thread_system_stack_ptr
    sw      sp, 8(t1)
    lw      sp, (t2)

    /* _tx_thread_current_ptr->tx_thread_time_slice =  _tx_timer_time_slice*/
    /* _tx_timer_time_slice = 0*/
    la      t4, _tx_timer_time_slice
    lw      t3, (t4)
    beqz    t3, __tx_thread_system_return_do_not_save
    sw      t3, 24(t1)
    sw      x0, (t4)

__tx_thread_system_return_do_not_save:
    la      t2, _tx_thread_schedule

    /* _tx_thread_current_ptr = NULL */
    sw      x0, (t0) 
    jr      t2
