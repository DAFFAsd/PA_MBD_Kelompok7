#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
; Fungsi-fungsi global
.global LCD_write
.global init_car
.global run_car

; Vektor interupsi
.global INT0_vect
;================================================================
LCD_write:
      ; Atur hanya pin nibble tinggi PORTD sebagai output untuk data LCD
      ; Jaga nibble rendah (termasuk PD2) tersedia untuk penggunaan lain
      IN    R16, DDRD         ; Baca nilai DDRD saat ini
      ORI   R16, 0xF0         ; Atur hanya nibble tinggi (PD4-PD7) sebagai output
      OUT   DDRD, R16         ; Atur port D sebagai output untuk data

      ; Atur semua pin PORTB sebagai output untuk kontrol LCD
      LDI   R16, 0xFF
      OUT   DDRB, R16         ; Atur port B sebagai output untuk perintah

      ; Inisialisasi pin kontrol LCD
      CBI   PORTB, 0          ; EN = 0
      RCALL delay_ms          ; Tunggu LCD menyala

      ; Inisialisasi LCD
      RCALL LCD_init

      ; Kembali ke pemanggil - kontrol mobil akan menangani tampilan
      RET
;================================================================
LCD_init:
      LDI   R16, 0x33         ;inisialisasi LCD untuk data 4-bit
      RCALL command_wrt       ;kirim ke register perintah
      RCALL delay_ms
      LDI   R16, 0x32         ;inisialisasi LCD untuk data 4-bit
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x28         ;LCD 2 baris, matriks 5x7
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x0C         ;tampilan ON, kursor OFF
      RCALL command_wrt
      LDI   R16, 0x01         ;bersihkan LCD
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x06         ;geser kursor ke kanan
      RCALL command_wrt
      RET
;================================================================
command_wrt:
      MOV   R27, R16
      ANDI  R27, 0xF0         ;masking nibble rendah & simpan nibble tinggi

      ; Pertahankan nibble rendah dari PORTD
      IN    R17, PORTD        ;baca nilai PORTD saat ini
      ANDI  R17, 0x0F         ;simpan hanya nibble rendah
      OR    R27, R17          ;gabungkan dengan nibble tinggi dari perintah
      OUT   PORTD, R27        ;output ke port D dengan mempertahankan nibble rendah

      CBI   PORTB, 1          ;RS = 0 untuk perintah
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;perlebar pulsa EN
      CBI   PORTB, 0          ;EN = 0 untuk pulsa H-ke-L
      RCALL delay_us          ;tunda dalam mikrodetik
      ;----------------------------------------------------
      MOV   R27, R16
      SWAP  R27               ;tukar nibble
      ANDI  R27, 0xF0         ;masking nibble rendah & simpan nibble tinggi

      ; Pertahankan nibble rendah dari PORTD
      IN    R17, PORTD        ;baca nilai PORTD saat ini
      ANDI  R17, 0x0F         ;simpan hanya nibble rendah
      OR    R27, R17          ;gabungkan dengan nibble tinggi dari perintah
      OUT   PORTD, R27        ;output ke port D dengan mempertahankan nibble rendah

      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;perlebar pulsa EN
      CBI   PORTB, 0          ;EN = 0 untuk pulsa H-ke-L
      RCALL delay_us          ;tunda dalam mikrodetik
      RET
;================================================================
data_wrt:
      MOV   R27, R16
      ANDI  R27, 0xF0         ;masking nibble rendah & simpan nibble tinggi

      ; Pertahankan nibble rendah dari PORTD
      IN    R17, PORTD        ;baca nilai PORTD saat ini
      ANDI  R17, 0x0F         ;simpan hanya nibble rendah
      OR    R27, R17          ;gabungkan dengan nibble tinggi dari data
      OUT   PORTD, R27        ;output ke port D dengan mempertahankan nibble rendah

      SBI   PORTB, 1          ;RS = 1 untuk data
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;perlebar pulsa EN
      CBI   PORTB, 0          ;EN = 0 untuk pulsa H-ke-L
      RCALL delay_us          ;tunda dalam mikrodetik
      ;----------------------------------------------------
      MOV   R27, R16
      SWAP  R27               ;tukar nibble
      ANDI  R27, 0xF0         ;masking nibble rendah & simpan nibble tinggi

      ; Pertahankan nibble rendah dari PORTD
      IN    R17, PORTD        ;baca nilai PORTD saat ini
      ANDI  R17, 0x0F         ;simpan hanya nibble rendah
      OR    R27, R17          ;gabungkan dengan nibble tinggi dari data
      OUT   PORTD, R27        ;output ke port D dengan mempertahankan nibble rendah

      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;perlebar pulsa EN
      CBI   PORTB, 0          ;EN = 0 untuk pulsa H-ke-L
      RCALL delay_us          ;tunda dalam mikrodetik
      RET
