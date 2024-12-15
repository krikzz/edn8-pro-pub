
NES_MAPPER      = 0;mapper number
NES_PRG_BANKS   = 2;number of 16K PRG banks, change to 2 for NROM256
NES_CHR_BANKS   = 1;number of 8K CHR banks
NES_MIRRORING   = 1;0 horizontal, 1 vertical, 8 four screen

PPU_CTRL	=$2000 
PPU_MASK	=$2001
PPU_STATUS	=$2002
PPU_OAM_ADDR    =$2003
PPU_OAM_DATA    =$2004
PPU_SCROLL	=$2005
PPU_ADDR	=$2006
PPU_DATA	=$2007
PPU_OAM_DMA	=$4014
PPU_FRAMECNT    =$4017
DMC_FREQ	=$4010
CTRL_PORT1	=$4016
CTRL_PORT2	=$4017

OS_ZRAM = $90
GFX_PTR = OS_ZRAM+2
PRG_PTR = OS_ZRAM+4
CTR1 = OS_ZRAM+6
CTR2 = OS_ZRAM+7


.define cmd_addr1 $4400
.define cmd_data1 $4401
.define cmd_addr2 $4402
.define cmd_data2 $4403

.define reg_spi 0
.define reg_usb 1
.define reg_cfg 2
.define reg_state 3
.define reg_key 4
.define reg_fpga 5
.define reg_fpga_nc 6
.define reg_map 7
.define reg_bios_cfg 9

.define freg_srm_map 129

.define srm_bank_os 7
.define srm_bank_tileset 8

.export start,__STARTUP__:absolute=1
.import __RAM_START__   ,__RAM_SIZE__
.import __ROM0_START__  ,__ROM0_SIZE__
.import __STARTUP_LOAD__,__STARTUP_RUN__,__STARTUP_SIZE__
.import	__CODE_LOAD__   ,__CODE_RUN__   ,__CODE_SIZE__
.import	__RODATA_LOAD__ ,__RODATA_RUN__ ,__RODATA_SIZE__

FT_BASE_ADR = $0100;page in RAM, should be $xx00
.include "zeropage.inc"
.import initlib, push0, popa, popax, _main, zerobss, copydata
.import _main

.segment "HEADER"

    .byte $4e,$45,$53,$1a
    .byte NES_PRG_BANKS
    .byte NES_CHR_BANKS
    .byte NES_MIRRORING|((NES_MAPPER & 15)<<4)
    .byte NES_MAPPER&$f0
    .res 8,0

.segment "STARTUP"
start:
    
    sei
    ldx #$ff
    txs

    lda #0
    sta $5100

    ldx #0
    stx PPU_MASK
    stx PPU_CTRL
    
    ldy #0
    lda #0
clram:
    sta $0000, y
    sta $0100, y
    sta $0200, y
    sta $0300, y
    sta $0400, y
    sta $0500, y
    sta $0600, y
    sta $0700, y
    iny
    bne clram


    jsr	zerobss
    jsr	copydata

    lda #<(__RAM_START__+__RAM_SIZE__)
    sta	sp
    lda	#>(__RAM_START__+__RAM_SIZE__)
    sta	sp+1            ; Set argument stack ptr

    jsr	initlib

    jmp _main


nmi:
    rti
irq:
    rti

.segment "VECTORS"

.word nmi ;$fffa vblank nmi
.word start ;$fffc reset
.word irq ;$fffe irq / brk

.segment "CHARS" 
.incbin "font.chr"
