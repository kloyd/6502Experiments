  .org $0000

; Apple 1 Wozmon.
ECHO = $FFEF
WOZENTRY = $FF00

  ldx #0
out_hello_string:
  lda hello, x 
  beq done_hello
  jsr ECHO
  inx 
  jmp out_hello_string

done_hello:
  lda #$0D     ; cr
  jsr ECHO
  
  jmp WOZENTRY

hello: .asciiz "Welcome to Wozmon!"

