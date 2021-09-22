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


#if __riscv_32e
    flw     f0, 0x7C(sp)                    # Recover ft0
    flw     f1, 0x80(sp)                    # Recover ft1
    flw     f2, 0x84(sp)                    # Recover ft2
    flw     f3, 0x88(sp)                    # Recover ft3
    flw     f4, 0x8C(sp)                    # Recover ft4
    flw     f5, 0x90(sp)                    # Recover ft5
    flw     f6, 0x94(sp)                    # Recover ft6
    flw     f7, 0x98(sp)                    # Recover ft7
    flw     f8, 0x9C(sp)                    # Recover fs0
    flw     f9, 0xA0(sp)                    # Recover fs1
    flw     f10,0xA4(sp)                    # Recover fa0
    flw     f11,0xA8(sp)                    # Recover fa1
    flw     f12,0xAC(sp)                    # Recover fa2
    flw     f13,0xB0(sp)                    # Recover fa3
    flw     f14,0xB4(sp)                    # Recover fa4
    flw     f15,0xB8(sp)                    # Recover fa5
    flw     f16,0xBC(sp)                    # Recover fa6
    flw     f17,0xC0(sp)                    # Recover fa7
    flw     f18,0xC4(sp)                    # Recover fs2
    flw     f19,0xC8(sp)                    # Recover fs3
    flw     f20,0xCC(sp)                    # Recover fs4
    flw     f21,0xD0(sp)                    # Recover fs5
    flw     f22,0xD4(sp)                    # Recover fs6
    flw     f23,0xD8(sp)                    # Recover fs7
    flw     f24,0xDC(sp)                    # Recover fs8
    flw     f25,0xE0(sp)                    # Recover fs9
    flw     f26,0xE4(sp)                    # Recover fs10
    flw     f27,0xE8(sp)                    # Recover fs11
    flw     f28,0xEC(sp)                    # Recover ft8
    flw     f29,0xF0(sp)                    # Recover ft9
    flw     f30,0xF4(sp)                    # Recover ft10
    flw     f31,0xF8(sp)                    # Recover ft11
    lw      t0, 0xFC(sp)                    # Recover fcsr
    csrw    fcsr, t0                        # 
#endif

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

#if __riscv_32e
    addi    sp, sp, 260                     # Recover stack frame - with floating point registers  
#else
    addi    sp, sp, 128                     # Recover stack frame - without floating point registers
#endif

    mret

__tx_thread_schedule_sync_restore:
    /* suspend thread frame */

#if __riscv_32e 
    flw     f8, 0x3C(sp)                    # Recover fs0
    flw     f9, 0x40(sp)                    # Recover fs1
    flw     f18,0x44(sp)                    # Recover fs2
    flw     f19,0x48(sp)                    # Recover fs3
    flw     f20,0x4C(sp)                    # Recover fs4
    flw     f21,0x50(sp)                    # Recover fs5
    flw     f22,0x54(sp)                    # Recover fs6
    flw     f23,0x58(sp)                    # Recover fs7
    flw     f24,0x5C(sp)                    # Recover fs8
    flw     f25,0x60(sp)                    # Recover fs9
    flw     f26,0x64(sp)                    # Recover fs10
    flw     f27,0x68(sp)                    # Recover fs11
    lw      t0, 0x6C(sp)                    # Recover fcsr
    csrw    fcsr, t0                        # 
#endif

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

#if __riscv_32e
    addi    sp, sp, 116                      # Recover stack frame
#else
    addi    sp, sp, 64                       # Recover stack frame
#endif

    ret
