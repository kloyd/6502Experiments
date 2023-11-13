;-------------------------------------
; input_lcd
;
; Author: Kelly Loyd
; Setup LCD output
; Prompt User for a string
; write string to LCD
; Repeat until empty string.
;

; --- 65C22 PIA ports and data direction registers.
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600c
IFR = $600d
IER = $600e
; --- 65C22 control Lines.
; E, RW, RS lines on LCD connected to PB6, PB5, PB4
E  = %01000000
RW = %00100000
RS = %00010000
; Serial port
ACIA_DATA   = $5000
ACIA_STATUS = $5001
ACIA_CMD    = $5002
ACIA_CTRL   = $5003
; --- Wozmon entry points and defines.
WOZMON = $FF00
IN    = $0200                          ; Input buffer
ECHO  = $FFEF
save_y = $50
save_x = $51

; ------- program start. 
; Start at 01000x in RAM using WozMon
  .org $1000

; Program entry point. Initialize LCD.
input_lcd:
  jsr lcd_setup

;
;
; Code starts here
;
; Output line 1 to the LCD panel at PORT B on the 65C22 PIA.
out_line_1:
  ldx #0
print_line_1:
  lda line_1,x
  beq out_line_2
  jsr print_char
  inx
  jmp print_line_1

out_line_2:
; move LCD cursor to line 2.
  lda #%10000000 ; set dram address - add in the character offset 
; for 16 x 2 display, second line starts at 40
  ora #40 ; try to get to 40
  jsr lcd_instruction
;
  ldx #0
print_line_2:
  lda line_2,x
  beq lcd_done
  jsr print_char
  inx
  jmp print_line_2

lcd_done:
  ldx #0    ;note for future. is some way to set up zero page pointer to each message string and send it? 
  ; Print STR subroutine.
print_prompt_loop:
  lda prompt,x
  beq prompt_done
  jsr ECHO
  inx
  jmp print_prompt_loop

prompt_done:

; now setup with default messages.
; Reset LCD to first char.
  lda #%10000000 ; set dram address - add in the character offset 
  jsr lcd_instruction
; grab buffer
  jsr get_input
  ldx #0
out_lcd:
  lda IN,x 
  cmp #$0D
  beq done
  jsr print_char
  inx 
  jmp out_lcd

done:
  jmp WOZMON  ; return to wozmon.


; Message to print for line 1 and line 2 of the LCD.
line_1: .asciiz " "
line_2: .asciiz ". 65C02 Computer"
;                1234567890123456   ;; 16 chars
prompt: .asciiz "Enter a string: "

get_input:

  ldy #$00

read_char:
  lda     ACIA_STATUS    ; Check status.
  and     #$08           ; Key ready?
  beq     read_char       ; Loop until ready.
  lda     ACIA_DATA      ; Load character. B7 will be '0'.
  sta     IN,Y           ; Add to text buffer.
  jsr     ECHO           ; Display character.
  ;; custom version of GETLINE from Wozmon.
  cmp     #$08           ; Backspace key?
  beq     backspace      ; Yes.
  cmp     #$1B           ; ESC?
  beq     escape         ; Yes.
  cmp     #$0D    ; CR?
  beq     input_done

  sty save_y
  iny                    ; Advance text index.
  bmi     escape       ; Auto ESC if line longer than 127.
  jmp read_char

escape:
  lda     #$5C           ; "\".
  jsr     ECHO           ; Output it.
  jmp get_input

backspace:      
  dey                    ; Back up text index.
  bmi     get_input        ; Beyond start of line, reinitialize.
  jmp read_char

input_done:
  sty save_y
  rts


lcd_setup:
  pha          ; Save A
; Initialize the LCD display - first 65C22 all outputs.
; get ready to set the LCD
  lda #$ff      ; Port B = All output
  sta DDRB
  lda #$ff      ; Port A = All output for blinkenlights!
  sta DDRA

; -- LCD Configuration. 4 bit mode, 2 line display
  jsr lcd_init
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Entry Mode Set - Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  
  pla   ; restore A
  rts
;
; output a character to current LCD char position.
;
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

