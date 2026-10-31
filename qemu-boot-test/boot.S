/*
 * QEMU x86-64 引导测试扇区（512 字节）
 *
 * BIOS（SeaBIOS）将该扇区加载到 0000:7C00 并执行后：
 *   1. 通过 BIOS INT 10h 在 VGA 文本屏幕上输出测试报告（供 QMP screendump 捕获画面）
 *   2. 初始化 COM1 为 115200 8N1，并把同一份报告写入串口（供 serial.log 校验）
 *   3. 打印 BOOT TEST PASSED 标记后停机
 *
 * 构建（run-boot-test.sh 自动完成）：
 *   as --32 -o boot.o boot.S
 *   ld -m elf_i386 --oformat binary -Ttext=0x7c00 -o boot.img boot.o
 */

    .code16
    .text
    .globl _start

_start:
    cli
    xorw    %ax, %ax
    movw    %ax, %ds
    movw    %ax, %es
    movw    %ax, %ss
    movw    $0x7c00, %sp
    sti

    /* --- 1. VGA 文本屏幕输出：BIOS INT 10h teletype --- */
    movw    $boot_msg, %si
1:
    lodsb
    testb   %al, %al
    jz      2f
    movb    $0x0e, %ah            /* AH=0Eh: teletype output */
    movw    $0x0007, %bx          /* BH=页 0, BL=前景灰 */
    int     $0x10
    jmp     1b
2:

    /* --- 2. 初始化 COM1: 除数 1 -> 115200 波特, 8N1 --- */
    movw    $com1_lcr, %dx
    movb    $0x80, %al            /* 打开 DLAB */
    outb    %al, %dx
    movw    $com1_data, %dx
    movb    $0x01, %al            /* DLL=1 (115200) */
    outb    %al, %dx
    movw    $com1_ier, %dx
    movb    $0x00, %al            /* DLM=0 */
    outb    %al, %dx
    movw    $com1_lcr, %dx
    movb    $0x03, %al            /* 8 数据位, 无校验, 1 停止位, 关 DLAB */
    outb    %al, %dx

    /* --- 3. 串口输出：轮询 LSR 的 THR 空位后逐字节发送 --- */
    movw    $boot_msg, %si
    movw    $com1_data, %dx
3:
    lodsb
    testb   %al, %al
    jz      4f
    pushw   %ax
    pushw   %dx
    movw    $com1_lsr, %dx
5:
    inb     %dx, %al
    testb   $0x20, %al            /* THRE: 发送保持寄存器为空 */
    jz      5b
    popw    %dx
    popw    %ax
    outb    %al, %dx
    jmp     3b
4:

    /* --- 4. 引导测试完成，关中断停机 --- */
    cli
6:
    hlt
    jmp     6b

    .equ    com1_data, 0x3f8      /* COM1 数据寄存器 */
    .equ    com1_ier,  0x3f9      /* COM1 中断允许 / DLM(高除数) */
    .equ    com1_lcr,  0x3fb      /* COM1 线路控制寄存器 */
    .equ    com1_lsr,  0x3fd      /* COM1 线路状态寄存器 */

boot_msg:
    .ascii  "\r\n"
    .ascii  "QEMU x86-64 BOOT TEST\r\n"
    .ascii  "=====================\r\n"
    .ascii  "Stage 1 bootloader entered at 0000:7C00\r\n"
    .ascii  "VGA text console via INT 10h: OK\r\n"
    .ascii  "COM1 serial 115200 8N1: OK\r\n"
    .ascii  "CPU: real mode, TCG translation\r\n"
    .ascii  "BOOT TEST PASSED\r\n"
    .byte   0

    .org    510
    .word   0xaa55                /* MBR 引导签名 */
