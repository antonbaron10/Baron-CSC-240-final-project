; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------
; lib_delay
; Author: Alan Ford
; Specific to ATTiny416 running at 20MHz, default prescalar (6).
; Functional clock speed: 3.333MHz
; All delays generated by delay loop calculator at http://www.bretmulvey.com/avrdelay.html
; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------

; --------------------------------------------------------------------------------
; Delay 3 333 000 cycles,   1s at 3.333 MHz
; --------------------------------------------------------------------------------
delay_1s:
                            ldi             r18, 17
                            ldi             r19, 233
                            ldi             r20, 134
    delay_1s_cont:
                            dec             r20
                            brne            delay_1s_cont
                            dec             r19
                            brne            delay_1s_cont
                            dec             r18
                            brne            delay_1s_cont
                            ret

; --------------------------------------------------------------------------------
; Delay 333 300 cycles,     100ms at 3.333 MHz
; --------------------------------------------------------------------------------
delay_100ms:
                            ldi             r28, 2
                            ldi             r29, 177
                            ldi             r30, 217
    delay_100ms_cont:
                            dec             r30
                            brne            delay_100ms_cont
                            dec             r29
                            brne            delay_100ms_cont
                            dec             r28
                            brne            delay_100ms_cont
                            nop
                            ret

; --------------------------------------------------------------------------------
; Delay 33 330 cycles,      10ms at 3.333 MHz
; --------------------------------------------------------------------------------
delay_10ms:
                            ldi             r18, 44
                            ldi             r19, 72
    delay_10ms_cont:
                            dec             r19
                            brne            delay_10ms_cont
                            dec             r18
                            brne            delay_10ms_cont
                            nop
                            ret

; --------------------------------------------------------------------------------
; Delay 3 333 cycles,       1ms at 3.333 MHz
; --------------------------------------------------------------------------------
delay_1ms:
                            ldi             r18, 5
                            ldi             r19, 83
    delay_1ms_cont:
                            dec             r19
                            brne            delay_1ms_cont
                            dec             r18
                            brne            delay_1ms_cont
                            nop
                            ret

; --------------------------------------------------------------------------------
.exit
; --------------------------------------------------------------------------------