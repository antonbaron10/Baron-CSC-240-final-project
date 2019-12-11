; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------
; lib_SSD1306_OLED
; Author: Kristof Aldenderfer (aldenderfer.github.io)
; Description: basic control for Adafruit SSD1306 OLED screen (via SPI only)
;     on ATTiny416. This assumes that actual access to pixel locations are
;     divided by 8, i.e. real height = OLED_HEIGHT/8, real width = OLED_WIDTH/8 .
; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------

; --------------------------------------------------------------------------------
; Description: directives
; --------------------------------------------------------------------------------
.equ                        OLED_PIN_RST    = 5 ; PORTA PIN5
.equ                        OLED_PIN_DC     = 6 ; PORTA PIN6

.include                    "lib_SPI.asm"                                           ; include SPI library

; --------------------------------------------------------------------------------
; Description: initialises OLED screen.
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - none
; --------------------------------------------------------------------------------
OLED_initialize:
                            rcall           SPI_master_initialize
                            lds             r16, PORTA_DIR
                            sbr             r16, (1<<OLED_PIN_RST)|(1<<OLED_PIN_DC)
                            sts             PORTA_DIR, r16
                            
                            lds             r16, PORTA_OUT
                            sbr             r16, (1<<OLED_PIN_RST)
                            sts             PORTA_OUT, r16
                            rcall           delay_1ms
                            lds             r16, PORTA_OUT
                            cbr             r16, (1<<OLED_PIN_RST)
                            sts             PORTA_OUT, r16
                            rcall           delay_1ms
                            lds             r16, PORTA_OUT
                            sbr             r16, (1<<OLED_PIN_RST)
                            sts             PORTA_OUT, r16
                            rcall           delay_1ms
                            ldi             ZL, low(array_OLED_init_commands<<1)
                            ldi             ZH, high(array_OLED_init_commands<<1)
    OLED_init_cmds:
                            lpm             r17, Z+
                            cpi             r17, 0xFF
                            breq            OLED_init_end
                            rcall           _OLED_write_command
                            rjmp            OLED_init_cmds
    OLED_init_end:
                            ret

; --------------------------------------------------------------------------------
; Description: writes a command to one of the screen's registers.
; Subroutine type:
;   - PRIVATE
; Dependencies:
;   - r17: command
; --------------------------------------------------------------------------------
_OLED_write_command:
                            lds             r16, PORTA_OUT
                            cbr             r16, (1<<SPI_PIN_CS)
                            sts             PORTA_OUT, r16
                            lds             r16, PORTA_OUT
                            cbr             r16, (1<<OLED_PIN_DC)
                            sts             PORTA_OUT, r16
                            rcall           SPI_master_transmit
                            lds             r16, PORTA_OUT
                            sbr             r16, (1<<SPI_PIN_CS)
                            sts             PORTA_OUT, r16
                            ret

; --------------------------------------------------------------------------------
; Description: writes a byte of data to one of the screen's registers.
; Subroutine type:
;   - PRIVATE
; Dependencies:
;   - r17: data
; --------------------------------------------------------------------------------
_OLED_write_data:
                            lds             r16, PORTA_OUT
                            cbr             r16, (1<<SPI_PIN_CS)
                            sts             PORTA_OUT, r16
                            lds             r16, PORTA_OUT
                            sbr             r16, (1<<OLED_PIN_DC)
                            sts             PORTA_OUT, r16
                            rcall           SPI_master_transmit
                            lds             r16, PORTA_OUT
                            sbr             r16, (1<<SPI_PIN_CS)
                            sts             PORTA_OUT, r16
                            ret

; --------------------------------------------------------------------------------
; Description: public version of _OLED_write_data.
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - r17: data
; --------------------------------------------------------------------------------
OLED_write_data:
                            rcall           _OLED_write_data
                            ret

; --------------------------------------------------------------------------------
; Description: initialisation sequence for screen.
; Nicked from https://github.com/adafruit/Adafruit_SSD1306/blob/master/Adafruit_SSD1306.cpp
; (Starts on line 543.)
; Comments below are on separate lines because Atmel Studio doesn't like inline comments on continued lines.
; --------------------------------------------------------------------------------
array_OLED_init_commands:   .db             0xAE, \
                                            0xD5, 0x80, \
                                            0xA8, 0x3F, \
                                            0xD3, 0x00, \
                                            0x40, \
                                            0x8D, 0x14, \
                                            0x20, 0x00, \
                                            0xA1, \
                                            0xC8, \
                                            0xDA, 0x12, \
                                            0x81, 0xCF, \
                                            0xD9, 0xF1, \
                                            0xDB, 0x40, \
                                            0xA4, \
                                            0xA6, \
                                            0x2E, \
                                            0xAF, \
                                            0xFF, 0xFF

                                            ; set disp (off),
                                            ; set disp clock div rat/osc freq
                                            ; set mux ratio
                                            ; set disp offset
                                            ; set disp start line (0)
                                            ; enable charge pump reg
                                            ; set mem addr mode - horiz
                                            ; set seg remap (remapped)
                                            ; set COM out scan dir (remapped)
                                            ; set com pins hw config
                                            ; set contrast ctrl
                                            ; set prechrg per
                                            ; set Vcom reg out
                                            ; entire disp (on)
                                            ; set inverse/normal (norm)
                                            ; deactivate scroll (deactivate)
                                            ; set disp (on)
                                            ; END COMMAND SET (my marker)

; --------------------------------------------------------------------------------
.exit
; --------------------------------------------------------------------------------