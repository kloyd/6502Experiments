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
  jmp WOZENTRY

hello: .asciiz "Welcome to Wozmon!"


;0000: A2 00 B5 10 F0 07 20 EF FF E8 4C 02 00 4C 00 FF
;0010: 57 65 6C 63 6F 6D 65 20 74 6F 20 57 6F 7A 6D 6F
;0020: 6E 21 00 