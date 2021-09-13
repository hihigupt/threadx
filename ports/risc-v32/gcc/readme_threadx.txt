                       Microsoft's Azure RTOS ThreadX for RISC-V  

                                     32-bit Mode

                                  Using the GNU GCC Tools

1.  Building the ThreadX run-time Library

First make sure you are in the "example_build" directory. Also, make sure that
you have setup your path and other environment variables necessary for the GNU
development environment.

2.  Demonstration System

Building the demonstration is easy; simply execute the GNU make command while 
inside the "example_build" directory. 

   cmake -Bbuild .
   cmake --build build

You should observe the compilation of sample_threadx.c (which is the demonstration 
application) and linking with tx.a. The resulting file DEMO is a binary file 
that can be executed.

3.  System Initialization

The entry point in ThreadX for the RISC-V using GNU GCC tools is at label 
__start. This is defined entry.S file. In addition, this is where all static,
global preset C variable initialization processing takes place and trap handlers
are defined.

The ThreadX tx_initialize_low_level.s file is responsible for setting up 
various system data structures. 

The _tx_initialize_low_level function inside of tx_initialize_low_level.s
also determines the first available address for use by the application, which 
is supplied as the sole input parameter to your application definition function, 
tx_application_define. To accomplish this, a section is created in 
tx_initialize_low_level.s called FREE_MEM, which must be located after all 
other RAM sections in memory.

4.  Register Usage and Stack Frames

The GNU GCC RISC-V compiler assumes that registers t0-t6 and a0-a7 are scratch 
registers for each function. All other registers used by a C function must 
be preserved by the function. ThreadX takes advantage of this in situations 
where a context switch happens as a result of making a ThreadX service call 
(which is itself a C function). In such cases, the saved context of a thread 
is only the non-scratch registers.

The following defines the saved context stack frames for context switches
that occur as a result of interrupt handling or from thread-level API calls.
All suspended threads have one of these two types of stack frames. The top
of the suspended thread's stack is pointed to by tx_thread_stack_ptr in the 
associated thread control block TX_THREAD.



    Offset        Interrupted Stack Frame        Non-Interrupt Stack Frame

     0x00                   1                           0
     0x04                   s11 (x27)                   s11 (x27)
     0x08                   s10 (x26)                   s10 (x26)
     0x0C                   s9  (x25)                   s9  (x25)
     0x10                   s8  (x24)                   s8  (x24)
     0x14                   s7  (x23)                   s7  (x23)
     0x18                   s6  (x22)                   s6  (x22)
     0x1C                   s5  (x21)                   s5  (x21)
     0x20                   s4  (x20)                   s4  (x20)
     0x24                   s3  (x19)                   s3  (x19)
     0x28                   s2  (x18)                   s2  (x18)
     0x2C                   s1  (x9)                    s1  (x9) 
     0x30                   s0  (x8)                    s0  (x8)    
     0x34                   t6  (x31)                   ra  (x1)
     0x38                   t5  (x30)                   mstatus
     0x3C                   t4  (x29)                   fs0
     0x40                   t3  (x28)                   fs1
     0x44                   t2  (x7)                    fs2
     0x48                   t1  (x6)                    fs3
     0x4C                   t0  (x5)                    fs4
     0x50                   a7  (x17)                   fs5 
     0x54                   a6  (x16)                   fs6 
     0x58                   a5  (x15)                   fs7 
     0x5C                   a4  (x14)                   fs8 
     0x60                   a3  (x13)                   fs9 
     0x64                   a2  (x12)                   fs10 
     0x68                   a1  (x11)                   fs11 
     0x6C                   a0  (x10)                   fcsr
     0x70                   ra  (x1)
     0x74                   reserved
     0x78                   mepc

Note: This port right now doesn't support saving floating point registers.

5.  Improving Performance

The distribution version of ThreadX is built without any compiler 
optimizations. This makes it easy to debug because you can trace or set 
breakpoints inside of ThreadX itself. Of course, this costs some 
performance. To make ThreadX run faster, you can change the project 
options to disable debug information and enable the desired 
compiler optimizations. 

In addition, you can eliminate the ThreadX basic API error checking by 
compiling your application code with the symbol TX_DISABLE_ERROR_CHECKING 
defined before tx_api.h is included. 

6.  Interrupt Handling
TODO:

6.1 Sample Timer ISR

The following sample timer ISR using mcahine timer handle in sample_threadx.c such that timer 
functionality is available under renode simulation for Mi-V RISC-V board:

uintptr_t handle_trap(uintptr_t mcause, uintptr_t mepc)
{
    if ((mcause & MCAUSE_INT) && ((mcause & MCAUSE_CAUSE)  == IRQ_M_TIMER))
    {
        _tx_timer_interrupt();
        handle_m_timer_interrupt();
    }
}

7.  Revision History

For generic code revision information, please refer to the readme_threadx_generic.txt
file, which is included in your distribution. The following details the revision
information associated with this specific port of ThreadX:

TBD         Initial ThreadX version for RISC-V using IAR Tools.


Copyright(c) 1996-2020 Microsoft Corporation


https://azure.com/rtos
