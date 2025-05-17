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

;================================================================
; Fungsi operasi utama mobil
;================================================================
; Handler interupsi INT0 untuk tombol darurat
INT0_vect:
    ; Simpan register yang digunakan
    PUSH  R16

    ; Toggle status emergency_stop
    LDS   R16, emergency_stop
    CPI   R16, 0
    BRNE  emergency_to_normal

    ; Normal -> Darurat: Simpan arah saat ini dan berhenti
    LDS   R16, car_direction
    STS   prev_direction, R16
    LDI   R16, 1
    STS   emergency_stop, R16
    RCALL motor_stop
    RCALL buzzer_on
    RJMP  int0_exit

emergency_to_normal:
    ; Darurat -> Normal: Kembalikan arah sebelumnya
    LDI   R16, 0
    STS   emergency_stop, R16
    RCALL buzzer_off

    ; Kembalikan arah sebelumnya dan mulai bergerak lagi
    LDS   R16, prev_direction
    STS   car_direction, R16

    ; Periksa arah mana yang akan dikembalikan dan mulai motor sesuai
    CPI   R16, 0            ; Jika arah sebelumnya adalah berhenti, tetap berhenti
    BREQ  restore_done

    CPI   R16, 1            ; Maju?
    BRNE  restore_check_backward
    RCALL motor_forward
    RJMP  restore_done

restore_check_backward:
    CPI   R16, 2            ; Mundur?
    BRNE  restore_check_left
    RCALL motor_backward
    RJMP  restore_done

restore_check_left:
    CPI   R16, 3            ; Kiri?
    BRNE  restore_check_right
    RCALL motor_left
    RJMP  restore_done

restore_check_right:
    CPI   R16, 4            ; Kanan?
    BRNE  restore_done
    RCALL motor_right

restore_done:
    RJMP  int0_exit

int0_exit:
    ; Kembalikan register
    POP   R16
    RETI

run_car:
    ; Simpan register yang digunakan
    PUSH  R16
    PUSH  R17

    ; Atur arah awal ke maju
    LDI   R16, 1
    STS   car_direction, R16
    RCALL motor_forward

car_loop:
    ; Periksa apakah dalam mode berhenti darurat
    LDS   R16, emergency_stop
    CPI   R16, 1
    BRNE  normal_operation
    JMP   emergency_display

normal_operation:

    ; Operasi normal - baca sensor dan lanjutkan
    ; Baca semua sensor IR
    RCALL read_sensors

    ; Periksa arah saat ini dan sensor yang sesuai
    LDS   R16, car_direction

    CPI   R16, 0            ; Berhenti?
    BRNE  not_stopped       ; Jika tidak berhenti, lanjutkan pemeriksaan

    ; Ketika berhenti, periksa semua arah untuk melihat apakah kita dapat bergerak lagi
    RCALL check_front       ; Coba bergerak maju jika memungkinkan
    RCALL check_left        ; Coba belok kiri jika memungkinkan
    RCALL check_right       ; Coba belok kanan jika memungkinkan
    RCALL check_back        ; Coba bergerak mundur jika memungkinkan
    RJMP  do_update_display ; Jika semua arah memiliki hambatan, hanya perbarui tampilan

not_stopped:
    CPI   R16, 1            ; Maju?
    BRNE  not_forward
    LDS   R16, front_status
    CPI   R16, 1            ; Hambatan?
    BRNE  buzzer_check_done ; Tidak ada hambatan, lanjutkan

    ; Penanganan hambatan di depan
    RCALL handle_forward_obstacle
    RJMP  do_update_display

not_forward:
    CPI   R16, 2            ; Mundur?
    BRNE  not_backward
    LDS   R16, back_status
    CPI   R16, 1            ; Hambatan?
    BRNE  buzzer_check_done ; Tidak ada hambatan, lanjutkan

    ; Penanganan hambatan di belakang
    RCALL handle_backward_obstacle
    RJMP  do_update_display

not_backward:
    CPI   R16, 3            ; Kiri?
    BRNE  not_left
    LDS   R16, left_status
    CPI   R16, 1            ; Hambatan?
    BRNE  buzzer_check_done ; Tidak ada hambatan, lanjutkan

    ; Penanganan hambatan di kiri
    RCALL handle_left_obstacle
    RJMP  do_update_display

not_left:
    CPI   R16, 4            ; Kanan?
    BRNE  buzzer_check_done
    LDS   R16, right_status
    CPI   R16, 1            ; Hambatan?
    BRNE  buzzer_check_done ; Tidak ada hambatan, lanjutkan

    ; Penanganan hambatan di kanan
    RCALL handle_right_obstacle
    RJMP  do_update_display

buzzer_check_done:
    ; Lanjutkan untuk memperbarui tampilan
    RJMP  do_update_display

; Fungsi penanganan untuk hambatan di berbagai arah
handle_forward_obstacle:
    RCALL buzzer_on         ; Nyalakan buzzer untuk hambatan di depan
    RCALL check_left        ; Coba temukan arah alternatif
    RCALL check_right
    RCALL check_back
    RCALL buzzer_off        ; Matikan buzzer
    ; Jika kita sampai di sini, semua arah memiliki hambatan
    RCALL motor_stop
    LDI   R16, 0
    STS   car_direction, R16
    RET

handle_backward_obstacle:
    RCALL buzzer_on         ; Nyalakan buzzer untuk hambatan di belakang
    RCALL check_left        ; Coba temukan arah alternatif
    RCALL check_right
    RCALL check_front
    RCALL buzzer_off        ; Matikan buzzer
    ; Jika kita sampai di sini, semua arah memiliki hambatan
    RCALL motor_stop
    LDI   R16, 0
    STS   car_direction, R16
    RET

handle_left_obstacle:
    RCALL buzzer_on         ; Nyalakan buzzer untuk hambatan di kiri
    RCALL check_right       ; Coba temukan arah alternatif
    RCALL check_front
    RCALL check_back
    RCALL buzzer_off        ; Matikan buzzer
    ; Jika kita sampai di sini, semua arah memiliki hambatan
    RCALL motor_stop
    LDI   R16, 0
    STS   car_direction, R16
    RET

handle_right_obstacle:
    RCALL buzzer_on         ; Nyalakan buzzer untuk hambatan di kanan
    RCALL check_left        ; Coba temukan arah alternatif
    RCALL check_front
    RCALL check_back
    RCALL buzzer_off        ; Matikan buzzer
    ; Jika kita sampai di sini, semua arah memiliki hambatan
    RCALL motor_stop
    LDI   R16, 0
    STS   car_direction, R16
    RET

emergency_display:
    ; Dalam mode berhenti darurat, hanya perbarui tampilan dan lanjutkan loop
    RCALL display_status

    ; Tampilkan pesan "EMERGENCY" atau indikator khusus
    ; Ini ditangani dalam fungsi display_status

    ; Tunda kecil
    LDI   R17, 2
emergency_delay_loop:
    RCALL delay_ms
    DEC   R17
    BRNE  emergency_delay_loop

    ; Lanjutkan loop utama
    RJMP  car_loop

do_update_display:
    ; Perbarui LCD dengan status saat ini
    RCALL display_status

    ; Tunda kecil
    LDI   R17, 2
delay_loop:
    RCALL delay_ms
    DEC   R17
    BRNE  delay_loop

    ; Lanjutkan loop utama
    RJMP  car_loop

run_car_exit:
    ; Kembalikan register dan kembali (hanya dicapai jika kita secara eksplisit melompat ke sini)
    POP   R17
    POP   R16
    RET
