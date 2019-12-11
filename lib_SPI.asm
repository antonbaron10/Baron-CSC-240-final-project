; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------
; lib_SPI
; Author: Kristof Aldenderfer (aldenderfer.github.io)
; Description: control of Serial Peripherl Interface on ATTiny416 without interrupts.
;     Heavily influenced by the datasheet.
; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------

; --------------------------------------------------------------------------------
; Description: directives
; --------------------------------------------------------------------------------
.equ                        SPI_PIN_MOSI    = 1 ; PORTA PIN1
.equ                        SPI_PIN_MISO    = 2 ; PORTA PIN2
.equ                        SPI_PIN_CLK     = 3 ; PORTA PIN3
.equ                        SPI_PIN_CS      = 4 ; PORTA PIN4

; --------------------------------------------------------------------------------
; Description: initializes SPI device as master
; subroutine type:
;   - PUBLIC
; dependencies:
;   - none
; --------------------------------------------------------------------------------
SPI_master_initialize:

                            ldi             r16, (1<<SPI_PIN_MOSI)|(1<<SPI_PIN_MISO)|(1<<SPI_PIN_CLK)|(1<<SPI_PIN_CS)
                            sts             PORTA_DIR, r16
                            ldi             r16, 0
                            sts             PORTA_OUT, r16
                            ldi             r16, (1<<5)|(0<<4)|(1<<0)               ; MSB transmitted first, master mode, no clock doubling,
                            sts             SPI0_CTRLA, r16                         ; 4x prescaler, enable.
                            ret

; --------------------------------------------------------------------------------
; Description: initializes SPI devies as slave
; subroutine type:
;   - PUBLIC
; dependencies:
;   - none
; --------------------------------------------------------------------------------
SPI_slave_initialize:
                            ldi             r16, (0<<SPI_PIN_MOSI)|(0<<SPI_PIN_MISO)|(0<<SPI_PIN_CLK)|(0<<SPI_PIN_CS)
                            sts             PORTA_DIR, r16
                            ldi             r16, 0
                            sts             PORTA_OUT, r16
                            ldi             r16, (0<<5)|(0<<4)|(1<<0)               ; MSB transmitted first, master mode, no clock doubling,
                            sts             SPI0_CTRLA, r16                         ; 4x prescaler, enable.
                            ret

; --------------------------------------------------------------------------------
; Description: sends a byte of information from the master
; subroutine type:
;   - PUBLIC
; dependencies:
;   - r17: byte to be sent
; --------------------------------------------------------------------------------
SPI_master_transmit:
                            sts             SPI0_DATA, r17                          ; Start transmission of data
    SPI_master_transmit_wait:
                            lds             r16, SPI0_INTFLAGS
                            sbrs            r16, 7                                  ; wait until IF is set
                            rjmp            SPI_master_transmit_wait                ; "
                            lds             r16, SPI0_DATA                          ; clear IF
                            ret

; --------------------------------------------------------------------------------
; Description: receives a byte of information from the slave
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - r17: byte received ends up here
; --------------------------------------------------------------------------------
SPI_master_receive:
                            sts             SPI0_DATA, r16                          ; Start transmission of data
    SPI_slave_receive_wait:
                            lds             r16, SPI0_INTFLAGS
                            sbrs            r16, 7                                  ; wait until IF is set
                            rjmp            SPI_slave_receive_wait                  ; "
                            lds             r17, SPI0_DATA                          ; fetch data and clear IF
                            ret

; --------------------------------------------------------------------------------
; Description: sends a byte of infomation from the slave
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - r17: byte to be sent
; --------------------------------------------------------------------------------
SPI_slave_transmit:
                            sts             SPI0_DATA, r17                          ; Start transmission of data
    SPI_slave_transmit_wait:
                            lds             r16, SPI0_INTFLAGS
                            sbrs            r16, 7                                  ; wait until IF is set
                            rjmp            SPI_slave_transmit_wait                 ; "
                            lds             r16, SPI0_DATA                          ; clear IF
                            ret

; --------------------------------------------------------------------------------
; Description: receives a byte of infomation from the master
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - r17: byte received ends up here
; --------------------------------------------------------------------------------
SPI_slave_receive:
                            lds             r16, SPI0_INTFLAGS
                            sbrs            r16, 7                                  ; wait until IF is set
                            rjmp            SPI_slave_receive                       ; "
                            lds             r17, SPI0_DATA                          ; fetch data and clear IF
                            ret

; --------------------------------------------------------------------------------
.exit
; --------------------------------------------------------------------------------