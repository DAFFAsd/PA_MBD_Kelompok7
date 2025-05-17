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
;================================================================
delay_short:
      NOP
      NOP
      RET
;------------------------
delay_us:
      LDI   R20, 90
l3:   RCALL delay_short
      DEC   R20
      BRNE  l3
      RET
;-----------------------
delay_ms:
      LDI   R21, 40
l4:   RCALL delay_us
      DEC   R21
      BRNE  l4
      RET
;================================================================
delay_seconds:        ;subrutin loop bersarang (tunda maksimal 3.11 detik)
    LDI   R20, 255    ;penghitung loop luar
l5: LDI   R21, 255    ;penghitung loop tengah
l6: LDI   R22, 20     ;penghitung loop dalam untuk memberikan tunda 0.25 detik
l7: DEC   R22         ;kurangi loop dalam
    BRNE  l7          ;loop jika tidak nol
    DEC   R21         ;kurangi loop tengah
    BRNE  l6          ;loop jika tidak nol
    DEC   R20         ;kurangi loop luar
    BRNE  l5          ;loop jika tidak nol
    RET               ;kembali ke pemanggil
;----------------------------------------------------------------

;================================================================
; Fungsi-fungsi Kontrol Mobil
;================================================================

; Variabel untuk status mobil
.section .data
    car_direction:  .byte 0  ; 0=berhenti, 1=maju, 2=mundur, 3=kiri, 4=kanan
    front_status:   .byte 0  ; 0=aman, 1=bahaya
    back_status:    .byte 0
    left_status:    .byte 0
    right_status:   .byte 0
    emergency_stop: .byte 0  ; 0=operasi normal, 1=berhenti darurat
    prev_direction: .byte 0  ; Simpan arah sebelumnya sebelum berhenti darurat

.section .text

;================================================================
; Inisialisasi komponen mobil (motor, sensor, buzzer)
;================================================================
init_car:
    ; Simpan register yang digunakan
    PUSH  R16
    PUSH  R17

    ; Inisialisasi LCD terlebih dahulu - ini akan mengatur PORTD dan PORTB untuk LCD
    RCALL LCD_write

    ; Sekarang inisialisasi PORTC untuk sensor IR dan buzzer
    LDI   R16, 0x20         ; Atur PC5 sebagai output untuk buzzer, PC0-PC3 sebagai input
    OUT   DDRC, R16

    ; Aktifkan resistor pull-up untuk input sensor
    LDI   R16, 0x0F         ; Atur pull-up PC0-PC3
    OUT   PORTC, R16

    ; Konfigurasi INT0 (PD2) untuk tombol darurat
    ; Atur PD2 sebagai input dengan pull-up
    CBI   DDRD, 2           ; Atur PD2 sebagai input
    SBI   PORTD, 2          ; Aktifkan pull-up pada PD2

    ; Konfigurasi INT0 untuk dipicu pada falling edge (penekanan tombol)
    LDI   R16, (1<<ISC01)   ; Falling edge dari INT0 menghasilkan interupsi
    STS   EICRA, R16

    ; Aktifkan interupsi INT0
    LDI   R16, (1<<INT0)
    OUT   EIMSK, R16

    ; Inisialisasi emergency_stop ke 0 (operasi normal)
    LDI   R16, 0
    STS   emergency_stop, R16

    ; Aktifkan interupsi global
    SEI

    ; Re-inisialisasi PORTB untuk kontrol motor sambil mempertahankan pin LCD
    ; PB0 (E) dan PB1 (RS) digunakan oleh LCD
    ; PB5 (IN1), PB4 (IN2), PB3 (ENA) untuk motor maju/mundur
    IN    R16, DDRB         ; Baca nilai DDRB saat ini
    ORI   R16, 0x38         ; Atur PB3, PB4, PB5 sebagai output sambil mempertahankan bit lainnya
    OUT   DDRB, R16

    ; Konfigurasi PB2 (IN3) untuk kontrol motor kiri/kanan
    ; PB2 (IN3), PC4/A4 (IN4) untuk motor kiri/kanan
    ; Bit yang lebih tinggi dari PORTD digunakan untuk data LCD
    IN    R16, DDRB         ; Baca nilai DDRB saat ini
    ORI   R16, 0x04         ; Atur PB2 sebagai output sambil mempertahankan bit lainnya
    OUT   DDRB, R16

    ; Konfigurasi PC4 (A4/IN4) untuk kontrol motor kiri/kanan
    IN    R16, DDRC         ; Baca nilai DDRC saat ini
    ORI   R16, 0x10         ; Atur PC4 sebagai output sambil mempertahankan bit lainnya
    OUT   DDRC, R16

    ; Inisialisasi Timer2 untuk PWM pada PB3 (OC2A)
    LDI   R16, (1<<WGM20)|(1<<WGM21)|(1<<COM2A1)  ; Mode Fast PWM, mode non-inverting
    STS   TCCR2A, R16
    LDI   R16, (1<<CS21)    ; Prescaler = 8
    STS   TCCR2B, R16
    LDI   R16, 200          ; Atur siklus tugas PWM (0-255)
    STS   OCR2A, R16

    ; Tampilkan pesan awal
    RCALL display_status

    ; Kembalikan register
    POP   R17
    POP   R16
    RET
