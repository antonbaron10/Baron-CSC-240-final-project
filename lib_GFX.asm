; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------
; lib_GFX
; Author: Kristof Aldenderfer (aldenderfer.github.io)
; Description: controls higher-level functionaity for OLED screens.
; Dependencies:
;   - some lower-level screen library, such as lib_SSD1306_OLED
; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------

; --------------------------------------------------------------------------------
; Description: reserved space in data memory for screen grid (8x8 squares).
; --------------------------------------------------------------------------------
.dseg
screen_array:               .byte           OLED_HEIGHT*OLED_WIDTH/64               ; datamem array that is written to screen
.cseg                                                                               ; return to code segment
.include                    "character_map.asm"                                     ; table of ascii pixel char arrays

; --------------------------------------------------------------------------------
; Description: calculates exact location in screen array (X-pointer).
;              Used to display something at that location.
;              Note - to find array location: loc = (y*OLED_WIDTH/8) + x .
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - r18: screen array x position [subroutine does not change this value]
;   - r19: screen array y position [subroutine does not change this value]
; --------------------------------------------------------------------------------
GFX_set_array_pos:     
                            push            r16                                     ; push all used registers to preserve them
                            push            r17
                            push            r20
                            ldi             XL, low(screen_array<<1)
                            ldi             XH, high(screen_array<<1)
                            mov             r16, r18
                            mov             r17, r19
                            ldi             r20, OLED_WIDTH/8                       ; width = OLED_WIDTH/8
    GFX_set_array_pos_yshift:                                                       ; screen position = (y*width) + x
                            cpi             r20, 1                                  ; have we mul'ed y by 2 enough?
                            breq            GFX_set_array_pos_offset
                            lsl             r17                                     ; mul y by 2
                            lsr             r20                                     ; div width by 2 to calculate how many muls by 2 to do
                            rjmp            GFX_set_array_pos_yshift
    GFX_set_array_pos_offset:
                            add             r17, r16                                
                            add             XL, r17                                 ; add calculated location to pointer
                            brcc            GFX_set_array_pos_end
                            inc             XH
    GFX_set_array_pos_end:
                            pop             r20                                     ; reinstate all pushed registers
                            pop             r17
                            pop             r16
                            ret

; --------------------------------------------------------------------------------
; Description: clears array of all information (equivalent to clearing the screen).
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - none
; --------------------------------------------------------------------------------
GFX_clear_array:
                            push            r17                                     ; push to preserve
                            push            r18
                            push            r19
                            clr             r17                                     ; used for: blank char
                            clr             r18                                     ; used for: counting columns
                            clr             r19                                     ; used for: counting rows
                            ldi             XL, low(screen_array<<1)
                            ldi             XH, high(screen_array<<1)
    GFX_clear_col:                                                                  ; for each col
                            cpi             r19, OLED_HEIGHT/8
                            brcc            GFX_clear_done
        GFX_clear_row:                                                              ; for each row
                            cpi             r18, OLED_WIDTH/8
                            brcc            GFX_clear_nr
                            st              X+, r17
                            inc             r18
                            rjmp            GFX_clear_row
            GFX_clear_nr:                                                           ; move to next row
                            clr             r18
                            inc             r19
                            rjmp            GFX_clear_col
    GFX_clear_done:                                                                 ; done clearing
                            pop             r19
                            pop             r18
                            pop             r17
                            ret

; --------------------------------------------------------------------------------
; Description: writes the entire screen array from dmem to the OLED.
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - none
; --------------------------------------------------------------------------------
GFX_refresh_screen:
                            push            r18                                    ; push to preserve
                            push            r19
                            ldi             XL, low(screen_array<<1)
                            ldi             XH, high(screen_array<<1)
                            clr             r18                                    ; used for: counting columns 
                            clr             r19                                    ; used for: counting rows
    GFX_refresh_screen_col:                                                        ; for each col
                            cpi             r19, OLED_HEIGHT/8
                            brcc            GFX_refresh_screen_done
        GFX_refresh_screen_row:                                                    ; for each row
                            cpi             r18, OLED_WIDTH/8
                            brcc            GFX_refresh_screen_nr
                            ld              r17, X+
                            rcall           _GFX_draw_shape
                            inc             r18
                            rjmp            GFX_refresh_screen_row
            GFX_refresh_screen_nr:                                                 ; move to next row
                            clr             r18
                            inc             r19
                            rjmp            GFX_refresh_screen_col
    GFX_refresh_screen_done:                                                       ; done drawing array
                            pop             r19
                            pop             r18
                            ret

; --------------------------------------------------------------------------------
; Description: stores character reference in pixel array.
; Subroutine type:
;   - PRIVATE
; Dependencies:
;   - r17: character number from your character map (e.g. for Char_005, use 5)
; --------------------------------------------------------------------------------
_GFX_draw_shape:
                            push            r0                                      ; push to preserve
                            push            r1
                            push            r21
                            push            r22
                            ldi             ZL, low(Char_000<<1)                    ; load char 0 into Z
                            ldi             ZH, high(Char_000<<1)
                            mov             r21, r17
                            ldi             r22, 8                                  ; size (in bytes) of each char
                            mul             r21, r22
                            add             ZL, r0                                  ; add calculated offset to pointer
                            adc             ZH, r1
                            clr             r21
    _GFX_draw_shape_loop:
                            lpm             r17, Z+
                            rcall           OLED_write_data
                            inc             r21
                            cpi             r21, 8
                            breq            _GFX_draw_shape_end
                            rjmp            _GFX_draw_shape_loop
    _GFX_draw_shape_end:
                            pop             r22
                            pop             r21
                            pop             r1
                            pop             r0
                            ret

; --------------------------------------------------------------------------------
.exit
; --------------------------------------------------------------------------------