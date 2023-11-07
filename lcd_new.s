;-------------------------------------
; lcd_new.s
;
; Author: Kelly Loyd
; Derived from examples provided by Ben Eater ( https://eater.net/6502 )
;

; --- 65C22 PIA ports and data direction registers.
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600c
IFR = $600d
IER = $600e

; E, RW, RS lines on LCD connected to PB6, PB5, PB4
E  = %01000000
RW = %00100000
RS = %00010000

; $8000 base address of EEROM
  .org $8000

; Initialization - Set the Stack pointer to $1FF
reset:
  ldx #$ff
  txs

; get ready to set the LCD
  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%00000000 ; Set all pins on port A to input
  sta DDRA

  jsr lcd_init
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction
;
;
; Code starts here
;
; Output a a message to the LCD panel at PORT B on the 65C22 PIA.
  ldx #0
print:
  lda message,x
  beq loop
  jsr print_char
  inx
  jmp print

loop:
  jmp loop

; Message text zero terminated.
; LCD DRAM holds 40 locations per line. 
; To start on second line, the text must start at character 41
; It would be smarter to use character cursor position commands on the LCD. For a future iteration.
; LCD char positions.      11111111112222222222333333333344444444445
;                 12345678901234567890123456789012345678901234567890
message: .asciiz " 65C02 Computer                          Kelly Loyd MMR"


; LCD subroutines
lcd_wait:
  pha
  lda #%11110000  ; LCD data is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB       ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcdbusy

  lda #RW
  sta PORTB
  lda #%11111111  ; LCD data is output
  sta DDRB
  pla
  rts

lcd_init:
  lda #%00000010 ; Set 4-bit mode
  sta PORTB
  ora #E
  sta PORTB
  lda #%00001000 ; 2 lines
  and #%00001111
  sta PORTB
  ora #E
  sta PORTB
  eor #E
  sta PORTB
  rts

lcd_instruction:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  pla
  and #%00001111 ; Send low 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  rts

print_char:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr             ; Send high 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  pla
  and #%00001111  ; Send low 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  rts


; Put Reset Vector @ $FFFC as per 6502 documentation.
  .org $fffc
  .word reset
; Pad rom out to 32K
  .word $0000
