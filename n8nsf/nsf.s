
NES_MAPPER      = 31;mapper number
NES_PRG_BANKS   = 2;number of 16K PRG banks, change to 2 for NROM256
NES_CHR_BANKS   = 1;number of 8K CHR banks
NES_MIRRORING   = 1;0 horizontal, 1 vertical, 8 four screen

PPU_CTRL    =$2000 
PPU_MASK    =$2001
PPU_STAT    =$2002
PPU_OAM_ADDR=$2003
PPU_OAM_DATA=$2004
PPU_SCROLL  =$2005
PPU_ADDR    =$2006
PPU_DATA    =$2007
PPU_OAM_DMA =$4014
PPU_FRCTR   =$4017
DMC_FREQ    =$4010
JOY_PORT1   =$4016
JOY_PORT2   =$4017

NSF_FDS_LO  =$5FF6
NSF_FDS_HI  =$5FF7
NSF_CTRL    =$5FF8
REG_CHIP    =$42FC
REG_EXEC    =$42FE
MEM_EXEC    =$4200

NSF_HDR     =$F000
NSF_SND_NUM =$F006
NSF_SND_ONE =$F007
NSF_INIT    =$F00A
NSF_PLAY    =$F00C
NSF_SNAME   =$F00E
NSF_ANAME   =$F02E
NSF_BANKS   =$F070
NSF_EXPS    =$F07B



JOY_L       =$02
JOY_R       =$01
JOY_STR     =$10
JOY_B       =$80
JOY_A       =$40

VAR_ADDR    =(MEM_EXEC +128)
VAR_JOY     =(MEM_EXEC +129)
VAR_JOY_BUF =(MEM_EXEC +130)
VAR_CUR_SND =(MEM_EXEC +131)
VAR_PAUSE   =(MEM_EXEC +132)
VAR_A       =(MEM_EXEC +133)
VAR_X       =(MEM_EXEC +134)
VAR_Y       =(MEM_EXEC +135)

.macro  set_ptr   addr
    lda #>(addr)
    sta 1
    lda #<(addr)
    sta 0
.endmacro

.macro  set_ppu   addr
    lda #>(addr)
    sta PPU_ADDR
    lda #<(addr)
    sta PPU_ADDR
.endmacro

.macro  print   addr
    set_ptr addr
    jsr put_str
.endmacro

.macro  print_cx   addr
    lda #>(addr)
    sta 1
    lda #<(addr)
    sta 0
    jsr str_center
    jsr put_str
.endmacro


.segment "HEADER"

    .byte $4e,$45,$53,$1a
    .byte NES_PRG_BANKS
    .byte NES_CHR_BANKS
    .byte NES_MIRRORING|((NES_MAPPER & 15)<<4)
    .byte NES_MAPPER&$f0
    .res 8,0

.segment "CODE"
rst:
    sei
    ldx #$ff
    txs
    
    lda #0
    sta PPU_CTRL
    sta PPU_MASK
    sta REG_EXEC + 0

    set_ptr pal
    jsr set_pal

    set_ptr menu
    jsr set_nt

    lda NSF_EXPS
    sta REG_CHIP

    set_ppu $21E0
    print_cx NSF_SNAME

    lda #0
    ldx #0
clwram:
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    inx
    bne clwram
    
    lda #$00
    sta VAR_JOY
    sta VAR_JOY_BUF
    sta VAR_CUR_SND
    sta VAR_PAUSE

    ldx #0
@0:
    lda run_nsf, x
    sta MEM_EXEC, x
    inx
    cpx #128
    bne @0
    
     
    lda #0
    sta PPU_SCROLL
    sta PPU_SCROLL
    jsr vsync

    lda #$0A
    sta PPU_MASK
;*******************************************************************************
player:
    lda #$00
    sta PPU_CTRL

    jsr init_player
    jsr banks_init
    jsr nsf_init

    lda PPU_STAT
    lda #$80
    sta PPU_CTRL
@0:
    jsr joy_wait
    jsr controls

    lda VAR_JOY
    and #(JOY_L | JOY_R)
    bne player

    beq @0

;*******************************************************************************
CMD_MEM_WR      =$1A
REG_FIFO_DATA   = $40F0
ADDR_CFG:
.byte $01, $80, $00, $20
TST:
.byte $55, $AA
return:
    lda VAR_JOY
    cmp #JOY_A
    bne @99

    jsr vsync
    lda #0
    sta PPU_CTRL
    sta PPU_MASK

    ldx #0
@0:
    lda @1, x
    sta $200, x
    inx
    bne @0
    jmp $200

@1:;ram app
    lda #'+'
    sta REG_FIFO_DATA
    eor #$ff
    sta REG_FIFO_DATA
    lda #CMD_MEM_WR
    sta REG_FIFO_DATA
    eor #$ff
    sta REG_FIFO_DATA
    
    lda ADDR_CFG + 3
    sta REG_FIFO_DATA
    lda ADDR_CFG + 2
    sta REG_FIFO_DATA
    lda ADDR_CFG + 1
    sta REG_FIFO_DATA
    lda ADDR_CFG + 0
    sta REG_FIFO_DATA

    lda #1
    sta REG_FIFO_DATA
    lda #0
    sta REG_FIFO_DATA
    sta REG_FIFO_DATA
    sta REG_FIFO_DATA

    sta REG_FIFO_DATA;ack

    lda #$ff
    sta REG_FIFO_DATA

@2:;wait till mcu will recive command
    lda TST + 0
    cmp #$55
    beq @2
    lda TST + 0
    cmp #$AA
    beq @2

    jmp ($FFFC)
@99:
    rts

vsync:
    bit PPU_STAT
@0:
    bit PPU_STAT
    bpl @0
    rts

set_pal:
    set_ppu $3f00
    ldy #0
@0:
    lda (0), y
    sta PPU_DATA
    iny
    cpy #16
    bne @0
    rts

set_nt:
    set_ppu $2000
    ldx #4
    ldy #0
@0:
    lda (0), y
    sta PPU_DATA
    iny
    bne @0
    inc 1
    dex
    bne @0
    rts

str_center:
    ldy #0
    ldx #32
@0:
    lda (0), y
    beq @1
    iny
    dex
    cpx #4
    bne @0
@1:    
    txa
    lsr
    tax
    lda #0
@2:
    lda PPU_DATA
    dex
    bne @2

    rts

put_str:
    ldy #0
@0:
    lda (0), y
    beq @1
    sta PPU_DATA
    iny
    cpy #28
    bne @0
@1:
    rts


init_player:
    ldx #0
    lda #0
@0:
    sta $4000,x
    inx
    cpx #$14
    bne @0
    
    sta $4015
    lda #$0f
    sta $4015
    lda #$40
    sta $4017

    rts

joy_wait:
@0:
    lda VAR_JOY_BUF
    bne @0
@1:
    lda VAR_JOY_BUF
    beq @1
    sta VAR_JOY
    rts


controls:
    jsr song_inc
    jsr song_dec
    jsr song_pause
    jsr return
    rts


song_pause:
    lda VAR_JOY
    cmp #JOY_B
    bne @99
    lda VAR_PAUSE
    eor #1
    sta VAR_PAUSE

    bne @0
    lda #$ff
    sta $4015
    lda NSF_EXPS
    sta REG_CHIP
    jmp @99
@0:;mute
    lda #$00
    sta $4015
    lda #0
    sta REG_CHIP
@99:
    rts

song_inc:
    lda VAR_JOY
    cmp #JOY_R
    bne @99
    ldx VAR_CUR_SND
    inx
    cpx NSF_SND_NUM
    beq @99
    stx VAR_CUR_SND
    lda #0
    sta VAR_PAUSE
@99:
    rts

song_dec:
    lda VAR_JOY
    cmp #JOY_L
    bne @99
    ldx VAR_CUR_SND
    cpx #0
    beq @99
    dex
    stx VAR_CUR_SND
    lda #0
    sta VAR_PAUSE
@99:
    rts

banks_init:
    ldx #0
@0:
    lda NSF_BANKS, x
    cmp #0
    bne banks_on
    inx 
    cpx #8
    bne @0

banks_off:
    ldx #0
@1:
    txa
    sta NSF_CTRL, x
    inx 
    cpx #8
    bne @1
    rts

banks_on:
    ldx #0
@2:
    lda NSF_BANKS, x
    sta NSF_CTRL, x
    inx 
    cpx #8
    bne @2

    lda NSF_BANKS + 6
    sta NSF_FDS_LO
    lda NSF_BANKS + 7
    sta NSF_FDS_HI

    rts



joy_read:
    lda VAR_JOY_BUF
    pha
    lda #$01
    sta JOY_PORT1
    lda #$00
    sta JOY_PORT1
    ldx #8
@0:
    asl VAR_JOY_BUF
    lda JOY_PORT1
    and #3
    beq @1
    lda #1
@1: ora VAR_JOY_BUF
    sta VAR_JOY_BUF
    dex 
    bne @0

    pla
    cmp VAR_JOY_BUF ;double check due DPCM bug
    bne joy_read

    rts

gfx_update:
    set_ppu $22AF

    lda VAR_PAUSE
    bne @0

    lda #$80
    jmp @1
@0:
    lda #$BA
@1:
    sta PPU_DATA

    lda #0
    sta PPU_SCROLL
    sta PPU_SCROLL
    rts


nsf_init:
    lda #>(MEM_EXEC + (nsf_end - run_nsf)-1)
    pha
    lda #<(MEM_EXEC + (nsf_end - run_nsf)-1)
    pha
    lda NSF_INIT
    sta VAR_ADDR
    lda NSF_INIT+1
    sta VAR_ADDR+1
    lda #0 ; clearing ram in $0-7FF, $6000-7FFF
    tay
    ldx #$7F
    sta $00
    @3:
    stx $01
    @0:
    sta ($00),Y
    iny
    bne @0
    cpx #$60
    bne @1
    ldx #$08
    @1:
    CPX #$02
    BNE @2
    LDX #$01
    @2:
    dex
    bpl @3
    lda VAR_CUR_SND ; return from init
    ldx #0
    jmp MEM_EXEC


nsf_play:
    lda VAR_PAUSE
    cmp #0
    bne @99
    lda #>(MEM_EXEC + (nsf_end - run_nsf)-1)
    pha
    lda #<(MEM_EXEC + (nsf_end - run_nsf)-1)
    pha
    lda NSF_PLAY
    sta VAR_ADDR
    lda NSF_PLAY+1
    sta VAR_ADDR+1
    
    jmp MEM_EXEC
@99:
    rts


nmi:
    sta VAR_A
    stx VAR_X
    sty VAR_Y
    
    jsr gfx_update
    jsr nsf_play
    jsr joy_read
    
    lda VAR_A
    ldx VAR_X
    ldy VAR_Y
    rti

irq:
    rti


run_nsf:
    sta REG_EXEC + 1
    jmp (VAR_ADDR)
nsf_end:
    lda PPU_STAT
    sta REG_EXEC + 0
    rts

.segment "EXE"   
.segment "VECTORS"

.word nmi ;$fffa vblank nmi
.word rst ;$fffc reset
.word irq ;$fffe irq / brk

.segment "CODE"
menu:
.incbin "menu.nam"
pal:
.incbin "menu.pal"

.segment "NSF"
.incbin "nsf-hdr.bin"

.segment "SND"
.incbin "sound.nsf"

.segment "CHARS" 
.incbin "font.bin"
