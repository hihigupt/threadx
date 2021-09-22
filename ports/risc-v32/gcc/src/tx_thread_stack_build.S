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
  .section      .text
  
/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_stack_build                              RISC-V/GNU      */
/*                                                           6.x          */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Scott Larson, Microsoft Corporation                                 */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function builds a stack frame on the supplied thread's stack.  */
/*    The stack frame results in a fake interrupt return to the supplied  */
/*    function pointer.                                                   */
/*                                                                        */
/*  INPUT                                                                 */
/*                                                                        */
/*    thread_ptr                            Pointer to thread control blk */
/*    function_ptr                          Pointer to return function    */
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
/*    _tx_thread_create                     Create thread service         */
/*                                                                        */
/*  RELEASE HISTORY                                                       */
/*                                                                        */
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  xx-xx-xxxx      Scott Larson            Initial Version 6.x           */
/*                                                                        */
/**************************************************************************/
/* VOID   _tx_thread_stack_build(TX_THREAD *thread_ptr, VOID (*function_ptr)(VOID)) */
/* { */
    .global  _tx_thread_stack_build
_tx_thread_stack_build:
    /* align to 16 bit */
    lw      t0, 16(a0)
    li      t1, ~15
    and     t0, t0, t1

    /* Save 32 registers */
#if __riscv_32e
    addi    t0, t0, -260
#else
    addi    t0, t0, -128
#endif

    li      t1, 1                           # Build stack typepe
    sw      t1, 0(t0)                       # Place stack type o
    sw      x0, 4(t0)                       # Initial s11
    sw      x0, 8(t0)                       # Initial s10
    sw      x0, 12(t0)                      # Initial s9
    sw      x0, 16(t0)                      # Initial s8
    sw      x0, 20(t0)                      # Initial s7
    sw      x0, 24(t0)                      # Initial s6
    sw      x0, 28(t0)                      # Initial s5
    sw      x0, 32(t0)                      # Initial s4
    sw      x0, 36(t0)                      # Initial s3
    sw      x0, 40(t0)                      # Initial s2
    sw      x0, 44(t0)                      # Initial s1
    sw      x0, 48(t0)                      # Initial s0
    sw      x0, 52(t0)                      # Initial t6
    sw      x0, 56(t0)                      # Initial t5
    sw      x0, 60(t0)                      # Initial t4
    sw      x0, 64(t0)                      # Initial t3
    sw      x0, 68(t0)                      # Initial t2
    sw      x0, 72(t0)                      # Initial t1
    sw      x0, 76(t0)                      # Initial t0
    sw      x0, 80(t0)                      # Initial a7
    sw      x0, 84(t0)                      # Initial a6
    sw      x0, 88(t0)                      # Initial a5
    sw      x0, 92(t0)                      # Initial a4
    sw      x0, 96(t0)                      # Initial a3
    sw      x0, 100(t0)                     # Initial a2
    sw      x0, 104(t0)                     # Initial a1
    sw      x0, 108(t0)                     # Initial a0
    sw      x0, 112(t0)                     # Initial ra
    sw      a1, 120(t0)                     # Initial mepc
#if __riscv_32e
    sw      x0, 124(t0)                     # Inital ft0
    sw      x0, 128(t0)                     # Inital ft1
    sw      x0, 132(t0)                     # Inital ft2
    sw      x0, 136(t0)                     # Inital ft3
    sw      x0, 140(t0)                     # Inital ft4
    sw      x0, 144(t0)                     # Inital ft5
    sw      x0, 148(t0)                     # Inital ft6
    sw      x0, 152(t0)                     # Inital ft7
    sw      x0, 156(t0)                     # Inital fs0
    sw      x0, 160(t0)                     # Inital fs1
    sw      x0, 164(t0)                     # Inital fa0
    sw      x0, 168(t0)                     # Inital fa1
    sw      x0, 172(t0)                     # Inital fa2
    sw      x0, 176(t0)                     # Inital fa3
    sw      x0, 180(t0)                     # Inital fa4
    sw      x0, 184(t0)                     # Inital fa5
    sw      x0, 188(t0)                     # Inital fa6
    sw      x0, 192(t0)                     # Inital fa7
    sw      x0, 196(t0)                     # Inital fs2
    sw      x0, 200(t0)                     # Inital fs3
    sw      x0, 204(t0)                     # Inital fs4
    sw      x0, 208(t0)                     # Inital fs5
    sw      x0, 212(t0)                     # Inital fs6
    sw      x0, 216(t0)                     # Inital fs7
    sw      x0, 220(t0)                     # Inital fs8
    sw      x0, 224(t0)                     # Inital fs9
    sw      x0, 228(t0)                     # Inital fs10
    sw      x0, 232(t0)                     # Inital fs11
    sw      x0, 236(t0)                     # Inital ft8
    sw      x0, 240(t0)                     # Inital ft9
    sw      x0, 244(t0)                     # Inital ft10
    sw      x0, 248(t0)                     # Inital ft11
    csrr    a1, fcsr                        # Read fcsr and use it for initial value for each thread
    sw      a1, 252(t0)                     # Initial fscr
    sw      x0, 256(t0)                     # Reserved word (0)
#else
    sw      x0, 124(t0)                     # Reserved word (0)
#endif

    sw      t0, 8(a0)

    ret
