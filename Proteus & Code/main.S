;-------------------------------------------------------------------
; Kode Assembly untuk Mobil Mini Arduino Go IVAN (PA KELOMPOK 7 MBD)
;-------------------------------------------------------------------
;==================================================================
;Anggota Kelompok 7:
;Adhikananda Wira Januar - 2306267113
;Daffa Sayra Firdaus - 2306267151
;Muhammad Hilmi Al Muttaqi - 2306267082
;Laura Fawzia Sambowo - 2306260145
;==================================================================

#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
; Fungsi-fungsi global
.global LCD_write
.global init_car
.global run_car

; Vektor interupsi
.global INT0_vect

; Definisi alamat I2C PCF8574
.equ PCF8574_ADDR, 0x27  ; Alamat I2C PCF8574 (biasanya 0x27 atau 0x3F)
.equ PCF8574_WRITE, 0x4E ; Alamat PCF8574 untuk operasi tulis (0x27 << 1)

; Definisi bit PCF8574 untuk LCD
.equ LCD_RS, 0    ; P0 -> RS
.equ LCD_RW, 1    ; P1 -> RW
.equ LCD_E, 2     ; P2 -> E
.equ LCD_BL, 3    ; P3 -> Backlight
.equ LCD_D4, 4    ; P4 -> D4
.equ LCD_D5, 5    ; P5 -> D5
.equ LCD_D6, 6    ; P6 -> D6
.equ LCD_D7, 7    ; P7 -> D7

; Definisi bit status TWI
.equ TWI_START, 0x08      ; START telah dikirim
.equ TWI_REP_START, 0x10  ; Repeated START telah dikirim
.equ TWI_MT_SLA_ACK, 0x18 ; SLA+W telah dikirim, ACK diterima
.equ TWI_MT_DATA_ACK, 0x28 ; Data telah dikirim, ACK diterima
;================================================================
;================================================================
; Fungsi-fungsi I2C/TWI
;================================================================
TWI_init:
      ; Konfigurasi pin SCL dan SDA (PC5/AC5 dan PC4/AC4)
      ; Pastikan pin PC4 dan PC5 diatur sebagai input dengan pull-up
      ; Jaga PC0-PC3 tetap sebagai input untuk sensor
      IN    R16, DDRC        ; Baca nilai DDRC saat ini
      ANDI  R16, ~((1<<PC4)|(1<<PC5))  ; Atur PC4 dan PC5 sebagai input
      OUT   DDRC, R16

      ; Aktifkan pull-up hanya pada PC4 dan PC5 untuk I2C
      ; Jaga status pull-up pada PC0-PC3 untuk sensor
      IN    R16, PORTC       ; Baca nilai PORTC saat ini
      ORI   R16, (1<<PC4)|(1<<PC5)     ; Aktifkan pull-up pada PC4 dan PC5
      OUT   PORTC, R16

      ; Reset TWI jika ada kondisi yang tidak diinginkan
      LDI   R16, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
      STS   TWCR, R16
      RCALL delay_ms         ; Tunggu reset selesai

      ; Inisialisasi I2C dengan frekuensi 100kHz (untuk 16MHz clock)
      LDI   R16, 18          ; Nilai untuk TWBR = 18 (100kHz pada 16MHz dengan prescaler 1)
      STS   TWBR, R16
      LDI   R16, 0           ; Prescaler = 1
      STS   TWSR, R16

      ; Aktifkan TWI
      LDI   R16, (1<<TWEN)
      STS   TWCR, R16
      RCALL delay_ms         ; Tunggu TWI siap
      RET

TWI_start:
      ; Kirim kondisi START
      LDI   R16, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
      STS   TWCR, R16

      ; Tunggu sampai TWINT diatur (operasi selesai)
TWI_start_wait:
      LDS   R16, TWCR
      SBRS  R16, TWINT
      RJMP  TWI_start_wait

      ; Periksa status
      LDS   R16, TWSR
      ANDI  R16, 0xF8        ; Masking bit prescaler

      ; Periksa apakah START atau REPEATED START berhasil
      CPI   R16, TWI_START
      BREQ  TWI_start_ok
      CPI   R16, TWI_REP_START
      BREQ  TWI_start_ok

      ; Jika tidak berhasil, coba lagi
      RCALL TWI_stop
      RCALL delay_ms
      RJMP  TWI_start

TWI_start_ok:
      RET

TWI_write:
      ; R16 berisi data yang akan dikirim
      STS   TWDR, R16        ; Muat data ke register data

      ; Kirim data
      LDI   R17, (1<<TWINT)|(1<<TWEN)
      STS   TWCR, R17

      ; Tunggu sampai TWINT diatur (operasi selesai)
TWI_write_wait:
      LDS   R17, TWCR
      SBRS  R17, TWINT
      RJMP  TWI_write_wait

      ; Periksa status
      LDS   R17, TWSR
      ANDI  R17, 0xF8        ; Masking bit prescaler

      ; Periksa apakah SLA+W atau DATA berhasil dikirim dan ACK diterima
      CPI   R17, TWI_MT_SLA_ACK
      BREQ  TWI_write_done
      CPI   R17, TWI_MT_DATA_ACK
      BREQ  TWI_write_done

      ; Jika gagal, kirim STOP dan kembalikan status error di R17
      RCALL TWI_stop

TWI_write_done:
      RET

TWI_stop:
      ; Kirim kondisi STOP
      LDI   R16, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
      STS   TWCR, R16

      ; Tunggu sedikit untuk memastikan STOP dikirim
      RCALL delay_ms
      RET

;================================================================
; Fungsi-fungsi LCD dengan I2C PCF8574
;================================================================
LCD_write:
      ; Inisialisasi I2C
      RCALL TWI_init
      RCALL delay_ms         ; Tunggu LCD menyala

      ; Inisialisasi LCD
      RCALL LCD_init

      ; Kembali ke pemanggil - kontrol mobil akan menangani tampilan
      RET
;================================================================
; Fungsi untuk mengirim byte ke PCF8574
PCF8574_write:
      ; R16 berisi data yang akan dikirim ke PCF8574
      PUSH  R16               ; Simpan data
      PUSH  R17               ; Simpan R17 yang akan digunakan

      ; Kirim kondisi START
      RCALL TWI_start

      ; Kirim alamat PCF8574 untuk operasi tulis
      LDI   R16, PCF8574_WRITE
      RCALL TWI_write

      ; Periksa status penulisan alamat
      CPI   R17, TWI_MT_SLA_ACK
      BRNE  PCF8574_write_error

      ; Kirim data
      POP   R17               ; Kembalikan R17
      POP   R16               ; Ambil kembali data
      PUSH  R16               ; Simpan lagi untuk digunakan nanti
      RCALL TWI_write

      ; Periksa status penulisan data
      CPI   R17, TWI_MT_DATA_ACK
      BRNE  PCF8574_write_error

      ; Kirim kondisi STOP
      RCALL TWI_stop
      POP   R16               ; Bersihkan stack
      RET

PCF8574_write_error:
      ; Jika terjadi error, kirim STOP dan coba lagi
      RCALL TWI_stop
      RCALL delay_ms
      POP   R16               ; Ambil kembali data
      RCALL PCF8574_write     ; Coba lagi
      RET

; Fungsi untuk mengirim nibble ke LCD melalui PCF8574
LCD_send_nibble:
      ; R16 berisi data nibble (di 4 bit tinggi)
      ; R17 berisi flag RS (0=command, 1=data)

      PUSH  R16               ; Simpan data
      PUSH  R17               ; Simpan flag RS
      PUSH  R18               ; Simpan register yang digunakan
      PUSH  R19               ; Simpan register tambahan

      ; Siapkan data untuk PCF8574
      ; Format: P7(D7) P6(D6) P5(D5) P4(D4) P3(BL) P2(E) P1(RW) P0(RS)

      ; Ambil 4 bit tinggi dari data dan posisikan di bit 4-7 (D4-D7)
      MOV   R18, R16
      ANDI  R18, 0xF0         ; Masking 4 bit tinggi

      ; Atur bit RS sesuai flag
      MOV   R19, R17          ; Salin flag RS ke R19
      ANDI  R19, 0x01         ; Pastikan hanya bit 0 yang digunakan
      OR    R18, R19          ; Gabungkan dengan data

      ; Atur RW = 0 (write) dan backlight ON
      ORI   R18, (1<<LCD_BL)  ; Backlight ON

      ; Kirim dengan E = 0
      MOV   R16, R18
      RCALL PCF8574_write
      RCALL delay_short       ; Delay lebih pendek untuk karakter

      ; Kirim dengan E = 1
      ORI   R18, (1<<LCD_E)   ; E = 1
      MOV   R16, R18
      RCALL PCF8574_write
      RCALL delay_us          ; Delay lebih pendek untuk karakter

      ; Kirim dengan E = 0
      ANDI  R18, ~(1<<LCD_E)  ; E = 0
      MOV   R16, R18
      RCALL PCF8574_write
      RCALL delay_us          ; Delay lebih pendek untuk karakter

      POP   R19               ; Kembalikan register
      POP   R18
      POP   R17
      POP   R16
      RET

LCD_init:
      ; Tunggu LCD menyala (lebih lama untuk memastikan stabilitas)
      LDI   R16, 10
init_delay_loop:
      RCALL delay_ms
      DEC   R16
      BRNE  init_delay_loop

      ; Inisialisasi PCF8574 dengan semua pin low kecuali backlight
      LDI   R16, (1<<LCD_BL)  ; Backlight ON, semua pin lain LOW
      RCALL PCF8574_write
      RCALL delay_ms

      ; Inisialisasi dalam mode 4-bit menggunakan protokol reset standar
      ; Pertama kirim 0x3 tiga kali
      LDI   R16, 0x30         ; 0011 0000 - bit 4-7 adalah 0011, RS=0
      LDI   R17, 0            ; RS = 0 (command)
      RCALL LCD_send_nibble

      ; Tunggu lebih dari 4.1ms
      LDI   R16, 5
init_delay1:
      RCALL delay_ms
      DEC   R16
      BRNE  init_delay1

      ; Kirim 0x3 lagi
      LDI   R16, 0x30
      LDI   R17, 0            ; RS = 0 (command)
      RCALL LCD_send_nibble

      ; Tunggu lebih dari 100us
      RCALL delay_ms

      ; Kirim 0x3 ketiga kalinya
      LDI   R16, 0x30
      LDI   R17, 0            ; RS = 0 (command)
      RCALL LCD_send_nibble
      RCALL delay_ms

      ; Sekarang kirim 0x2 untuk mengatur mode 4-bit
      LDI   R16, 0x20
      LDI   R17, 0            ; RS = 0 (command)
      RCALL LCD_send_nibble
      RCALL delay_ms

      ; Sekarang kita bisa menggunakan command_wrt untuk perintah lengkap
      LDI   R16, 0x28         ; LCD 2 baris, matriks 5x7, mode 4-bit
      RCALL command_wrt
      RCALL delay_ms

      LDI   R16, 0x08         ; Display off
      RCALL command_wrt
      RCALL delay_ms

      LDI   R16, 0x01         ; Bersihkan LCD
      RCALL command_wrt

      ; Tunggu lebih lama untuk perintah clear display
      LDI   R16, 5
clear_delay:
      RCALL delay_ms
      DEC   R16
      BRNE  clear_delay

      LDI   R16, 0x06         ; Entry mode set: increment, no shift
      RCALL command_wrt
      RCALL delay_ms

      LDI   R16, 0x0C         ; Display on, cursor off, blink off
      RCALL command_wrt
      RCALL delay_ms

      RET
;================================================================
command_wrt:
      ; Kirim perintah (RS=0) ke LCD melalui PCF8574
      ; R16 berisi perintah yang akan dikirim

      PUSH  R16               ; Simpan perintah
      PUSH  R17               ; Simpan register yang digunakan
      PUSH  R18               ; Simpan register tambahan
      PUSH  R19               ; Simpan register tambahan untuk flag

      ; Simpan perintah untuk pengecekan
      MOV   R19, R16

      ; Kirim nibble tinggi terlebih dahulu
      MOV   R18, R16          ; Salin perintah ke R18
      ANDI  R18, 0xF0         ; Ambil hanya 4 bit tinggi
      LDI   R17, 0            ; RS = 0 (command)
      MOV   R16, R18          ; Pindahkan data ke R16
      RCALL LCD_send_nibble

      ; Kirim nibble rendah
      POP   R19               ; Ambil kembali flag perintah
      POP   R18               ; Ambil kembali register tambahan
      POP   R17               ; Ambil kembali register
      POP   R16               ; Ambil kembali perintah asli
      PUSH  R16               ; Simpan lagi untuk digunakan nanti
      PUSH  R17               ; Simpan lagi
      PUSH  R19               ; Simpan flag perintah

      SWAP  R16               ; Tukar nibble (bit rendah ke bit tinggi)
      ANDI  R16, 0xF0         ; Ambil hanya 4 bit tinggi (yang tadinya rendah)
      LDI   R17, 0            ; RS = 0 (command)
      RCALL LCD_send_nibble

      ; Periksa jenis perintah untuk menentukan delay
      POP   R19               ; Ambil kembali flag perintah

      ; Perintah yang memerlukan delay lebih lama
      CPI   R19, 0x01         ; Clear display?
      BREQ  cmd_long_delay
      CPI   R19, 0x02         ; Return home?
      BREQ  cmd_long_delay
      CPI   R19, 0x03         ; Entry mode set?
      BREQ  cmd_long_delay

      ; Perintah normal, delay pendek
      RCALL delay_short
      RJMP  cmd_done

cmd_long_delay:
      ; Perintah yang memerlukan waktu lebih lama
      RCALL delay_ms

cmd_done:
      POP   R17               ; Kembalikan register
      POP   R16               ; Kembalikan perintah
      RET
;================================================================
data_wrt:
      ; Kirim data (RS=1) ke LCD melalui PCF8574
      ; R16 berisi data yang akan dikirim

      PUSH  R16               ; Simpan data
      PUSH  R17               ; Simpan register yang digunakan
      PUSH  R18               ; Simpan register tambahan

      ; Kirim nibble tinggi terlebih dahulu
      MOV   R18, R16          ; Salin data ke R18
      ANDI  R18, 0xF0         ; Ambil hanya 4 bit tinggi
      LDI   R17, 1            ; RS = 1 (data)
      MOV   R16, R18          ; Pindahkan data ke R16
      RCALL LCD_send_nibble

      ; Kirim nibble rendah
      POP   R18               ; Ambil kembali register tambahan
      POP   R17               ; Ambil kembali register
      POP   R16               ; Ambil kembali data asli
      PUSH  R16               ; Simpan lagi untuk digunakan nanti
      PUSH  R17               ; Simpan lagi

      SWAP  R16               ; Tukar nibble (bit rendah ke bit tinggi)
      ANDI  R16, 0xF0         ; Ambil hanya 4 bit tinggi (yang tadinya rendah)
      LDI   R17, 1            ; RS = 1 (data)
      RCALL LCD_send_nibble

      ; Tunggu sangat singkat untuk karakter
      RCALL delay_short

      POP   R17               ; Kembalikan register
      POP   R16               ; Kembalikan data
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

    ; Inisialisasi I2C dan LCD
    RCALL LCD_write

    ; Inisialisasi PORTC untuk sensor IR dan I2C
    ; PC5 dan PC4 digunakan untuk I2C (SCL dan SDA)
    ; PC0-PC3 sebagai input untuk sensor IR
    IN    R16, DDRC         ; Baca nilai DDRC saat ini
    ANDI  R16, 0xC0         ; Pertahankan bit lain, atur PC0-PC5 sebagai input (1100 0000)
    OUT   DDRC, R16

    ; Aktifkan resistor pull-up untuk input sensor dan I2C
    IN    R16, PORTC        ; Baca nilai PORTC saat ini
    ORI   R16, 0x3F         ; Aktifkan pull-up pada PC0-PC5 (0011 1111)
    OUT   PORTC, R16

    ; Gunakan PB0 sebagai output untuk buzzer (menggantikan PC5)
    SBI   DDRB, 0           ; Atur PB0 sebagai output untuk buzzer

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

    ; Konfigurasi pin motor dan buzzer
    ; PB0 untuk buzzer
    ; PB1 (IN4), PB2 (IN3) untuk motor kiri/kanan
    ; PB3 (ENA), PB4 (IN2), PB5 (IN1) untuk motor maju/mundur
    LDI   R16, 0x3F         ; Atur PB0-PB5 sebagai output (0011 1111)
    OUT   DDRB, R16

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

    ; Tunda sangat kecil untuk pembacaan sensor yang lebih responsif
    LDI   R17, 1
emergency_delay_loop:
    RCALL delay_short
    DEC   R17
    BRNE  emergency_delay_loop

    ; Lanjutkan loop utama
    RJMP  car_loop

do_update_display:
    ; Perbarui LCD dengan status saat ini
    RCALL display_status

    ; Tunda sangat kecil untuk pembacaan sensor yang lebih responsif
    LDI   R17, 1
delay_loop:
    RCALL delay_short
    DEC   R17
    BRNE  delay_loop

    ; Lanjutkan loop utama
    RJMP  car_loop

run_car_exit:
    ; Kembalikan register dan kembali (hanya dicapai jika kita secara eksplisit melompat ke sini)
    POP   R17
    POP   R16
    RET

;================================================================
; Periksa arah untuk hambatan dan ubah arah jika diperlukan
;================================================================
check_left:
    LDS   R16, left_status
    CPI   R16, 1            ; Hambatan di kiri?
    BREQ  check_left_exit   ; Ya, keluar

    ; Tidak ada hambatan di kiri, belok kiri
    LDI   R16, 3
    STS   car_direction, R16
    RCALL motor_left
    RCALL display_status

    ; Tunda kecil untuk memungkinkan belok
    LDI   R17, 10
left_delay:
    RCALL delay_ms
    DEC   R17
    BRNE  left_delay

    ; Kembali ke loop utama
    RJMP  car_loop

check_left_exit:
    RET

check_right:
    LDS   R16, right_status
    CPI   R16, 1            ; Hambatan di kanan?
    BREQ  check_right_exit  ; Ya, keluar

    ; Tidak ada hambatan di kanan, belok kanan
    LDI   R16, 4
    STS   car_direction, R16
    RCALL motor_right
    RCALL display_status

    ; Tunda kecil untuk memungkinkan belok
    LDI   R17, 10
right_delay:
    RCALL delay_ms
    DEC   R17
    BRNE  right_delay

    ; Kembali ke loop utama
    RJMP  car_loop

check_right_exit:
    RET

check_back:
    LDS   R16, back_status
    CPI   R16, 1            ; Hambatan di belakang?
    BREQ  check_back_exit   ; Ya, keluar

    ; Tidak ada hambatan di belakang, mundur
    LDI   R16, 2
    STS   car_direction, R16
    RCALL motor_backward
    RCALL display_status

    ; Tunda kecil untuk memungkinkan pergerakan
    LDI   R17, 10
back_delay:
    RCALL delay_ms
    DEC   R17
    BRNE  back_delay

    ; Kembali ke loop utama
    RJMP  car_loop

check_back_exit:
    RET

check_front:
    LDS   R16, front_status
    CPI   R16, 1            ; Hambatan di depan?
    BREQ  check_front_exit  ; Ya, keluar

    ; Tidak ada hambatan di depan, maju
    LDI   R16, 1
    STS   car_direction, R16
    RCALL motor_forward
    RCALL display_status

    ; Tunda kecil untuk memungkinkan pergerakan
    LDI   R17, 10
front_delay:
    RCALL delay_ms
    DEC   R17
    BRNE  front_delay

    ; Kembali ke loop utama
    RJMP  car_loop

check_front_exit:
    RET

;================================================================
; Fungsi kontrol motor
;================================================================
motor_forward:
    ; Atur IN1=HIGH, IN2=LOW untuk maju
    SBI   PORTB, 5          ; IN1 = HIGH
    CBI   PORTB, 4          ; IN2 = LOW

    ; Hentikan motor kiri/kanan saat bergerak maju
    CBI   PORTB, 2          ; IN3 = LOW (PB2)
    CBI   PORTB, 1          ; IN4 = LOW (PB1/pin9) - diubah dari PC4/A4
    RET

motor_backward:
    ; Atur IN1=LOW, IN2=HIGH untuk mundur
    CBI   PORTB, 5          ; IN1 = LOW
    SBI   PORTB, 4          ; IN2 = HIGH

    ; Hentikan motor kiri/kanan saat bergerak mundur
    CBI   PORTB, 2          ; IN3 = LOW (PB2)
    CBI   PORTB, 1          ; IN4 = LOW (PB1/pin9) - diubah dari PC4/A4
    RET

motor_left:
    ; Hentikan motor maju/mundur saat berbelok ke kiri
    CBI   PORTB, 5          ; IN1 = LOW
    CBI   PORTB, 4          ; IN2 = LOW

    ; Atur motor kiri/kanan untuk berbelok ke kiri
    SBI   PORTB, 2          ; IN3 = HIGH (PB2)
    CBI   PORTB, 1          ; IN4 = LOW (PB1/pin9) - diubah dari PC4/A4
    RET

motor_right:
    ; Hentikan motor maju/mundur saat berbelok ke kanan
    CBI   PORTB, 5          ; IN1 = LOW
    CBI   PORTB, 4          ; IN2 = LOW

    ; Atur motor kiri/kanan untuk berbelok ke kanan
    CBI   PORTB, 2          ; IN3 = LOW (PB2)
    SBI   PORTB, 1          ; IN4 = HIGH (PB1/pin9) - diubah dari PC4/A4
    RET

motor_stop:
    ; Hentikan motor maju/mundur
    CBI   PORTB, 5          ; IN1 = LOW
    CBI   PORTB, 4          ; IN2 = LOW

    ; Hentikan motor kiri/kanan
    CBI   PORTB, 2          ; IN3 = LOW (PB2)
    CBI   PORTB, 1          ; IN4 = LOW (PB1/pin9) - diubah dari PC4/A4
    RET

;================================================================
; Fungsi pembacaan sensor
;================================================================
read_sensors:
    ; Baca sensor depan (PC2)
    IN    R16, PINC
    ANDI  R16, 0x04         ; Masking untuk PC2
    CPI   R16, 0            ; Jika 0, hambatan terdeteksi (active low)
    BREQ  front_obstacle
    LDI   R16, 0            ; Tidak ada hambatan
    RJMP  store_front
front_obstacle:
    LDI   R16, 1            ; Hambatan terdeteksi
store_front:
    STS   front_status, R16

    ; Baca sensor belakang (PC3)
    IN    R16, PINC
    ANDI  R16, 0x08         ; Masking untuk PC3
    CPI   R16, 0            ; Jika 0, hambatan terdeteksi (active low)
    BREQ  back_obstacle
    LDI   R16, 0            ; Tidak ada hambatan
    RJMP  store_back
back_obstacle:
    LDI   R16, 1            ; Hambatan terdeteksi
store_back:
    STS   back_status, R16

    ; Baca sensor kiri (PC0)
    IN    R16, PINC
    ANDI  R16, 0x01         ; Masking untuk PC0
    CPI   R16, 0            ; Jika 0, hambatan terdeteksi (active low)
    BREQ  left_obstacle
    LDI   R16, 0            ; Tidak ada hambatan
    RJMP  store_left
left_obstacle:
    LDI   R16, 1            ; Hambatan terdeteksi
store_left:
    STS   left_status, R16

    ; Baca sensor kanan (PC1)
    IN    R16, PINC
    ANDI  R16, 0x02         ; Masking untuk PC1
    CPI   R16, 0            ; Jika 0, hambatan terdeteksi (active low)
    BREQ  right_obstacle
    LDI   R16, 0            ; Tidak ada hambatan
    RJMP  store_right
right_obstacle:
    LDI   R16, 1            ; Hambatan terdeteksi
store_right:
    STS   right_status, R16

    RET

;================================================================
; Fungsi kontrol buzzer
;================================================================
buzzer_on:
    SBI   PORTB, 0          ; Nyalakan buzzer (PB0) - diubah dari PC5
    RET

buzzer_off:
    CBI   PORTB, 0          ; Matikan buzzer (PB0) - diubah dari PC5
    RET

;================================================================
; Fungsi tampilan
;================================================================
display_status:
    ; Bersihkan LCD
    LDI   R16, 0x01
    RCALL command_wrt
    RCALL delay_ms

    ; Periksa apakah dalam mode berhenti darurat
    LDS   R16, emergency_stop
    CPI   R16, 1
    BRNE  disp_normal_mode
    JMP   disp_emergency

disp_normal_mode:
    ; Tampilkan arah pada baris pertama
    LDS   R16, car_direction

    ; Gunakan serangkaian perbandingan dan lompatan alih-alih cabang
    CPI   R16, 0
    BRNE  disp_check_forward
    JMP   disp_stop

disp_check_forward:
    CPI   R16, 1
    BRNE  disp_check_backward
    JMP   disp_forward

disp_check_backward:
    CPI   R16, 2
    BRNE  disp_check_left
    JMP   disp_backward

disp_check_left:
    CPI   R16, 3
    BRNE  disp_check_right
    JMP   disp_left

disp_check_right:
    CPI   R16, 4
    BRNE  disp_not_right
    JMP   disp_right

disp_not_right:
    JMP   disp_unknown

disp_emergency:
    ; Tampilkan "EMERGENCY" pada baris pertama
    LDI   R16, 'E'
    RCALL data_wrt
    LDI   R16, 'M'
    RCALL data_wrt
    LDI   R16, 'E'
    RCALL data_wrt
    LDI   R16, 'R'
    RCALL data_wrt
    LDI   R16, 'G'
    RCALL data_wrt
    LDI   R16, 'E'
    RCALL data_wrt
    LDI   R16, 'N'
    RCALL data_wrt
    LDI   R16, 'C'
    RCALL data_wrt
    LDI   R16, 'Y'
    RCALL data_wrt
    RJMP  disp_sensors

disp_stop:
    LDI   R16, 'S'
    RCALL data_wrt
    LDI   R16, 'T'
    RCALL data_wrt
    LDI   R16, 'O'
    RCALL data_wrt
    LDI   R16, 'P'
    RCALL data_wrt
    RJMP  disp_sensors

disp_forward:
    LDI   R16, 'D'
    RCALL data_wrt
    LDI   R16, 'E'
    RCALL data_wrt
    LDI   R16, 'P'
    RCALL data_wrt
    LDI   R16, 'A'
    RCALL data_wrt
    LDI   R16, 'N'
    RCALL data_wrt
    RJMP  disp_sensors

disp_backward:
    LDI   R16, 'B'
    RCALL data_wrt
    LDI   R16, 'E'
    RCALL data_wrt
    LDI   R16, 'L'
    RCALL data_wrt
    LDI   R16, 'A'
    RCALL data_wrt
    LDI   R16, 'K'
    RCALL data_wrt
    LDI   R16, 'A'
    RCALL data_wrt
    LDI   R16, 'N'
    RCALL data_wrt
    LDI   R16, 'G'
    RCALL data_wrt
    RJMP  disp_sensors

disp_left:
    LDI   R16, 'K'
    RCALL data_wrt
    LDI   R16, 'I'
    RCALL data_wrt
    LDI   R16, 'R'
    RCALL data_wrt
    LDI   R16, 'I'
    RCALL data_wrt
    RJMP  disp_sensors

disp_right:
    LDI   R16, 'K'
    RCALL data_wrt
    LDI   R16, 'A'
    RCALL data_wrt
    LDI   R16, 'N'
    RCALL data_wrt
    LDI   R16, 'A'
    RCALL data_wrt
    LDI   R16, 'N'
    RCALL data_wrt
    RJMP  disp_sensors

disp_unknown:
    LDI   R16, '?'
    RCALL data_wrt

disp_sensors:
    ; Pindah ke baris kedua
    LDI   R16, 0xC0
    RCALL command_wrt
    RCALL delay_ms

    ; Tampilkan sensor depan (D:)
    LDI   R16, 'D'
    RCALL data_wrt
    LDI   R16, ':'
    RCALL data_wrt
    LDS   R16, front_status
    CPI   R16, 0      ; Periksa apakah 0 atau 1
    BREQ  front_zero
    LDI   R16, '0'    ; Muat ASCII '0' (tidak ada hambatan untuk active low)
    RJMP  front_display
front_zero:
    LDI   R16, '1'    ; Muat ASCII '1' (hambatan untuk active low)
front_display:
    RCALL data_wrt

    ; Tampilkan spasi
    LDI   R16, ' '
    RCALL data_wrt

    ; Tampilkan sensor belakang (B:)
    LDI   R16, 'B'
    RCALL data_wrt
    LDI   R16, ':'
    RCALL data_wrt
    LDS   R16, back_status
    CPI   R16, 0      ; Periksa apakah 0 atau 1
    BREQ  back_zero
    LDI   R16, '0'    ; Muat ASCII '0' (tidak ada hambatan untuk active low)
    RJMP  back_display
back_zero:
    LDI   R16, '1'    ; Muat ASCII '1' (hambatan untuk active low)
back_display:
    RCALL data_wrt

    ; Tampilkan spasi
    LDI   R16, ' '
    RCALL data_wrt

    ; Tampilkan sensor kiri (K:)
    LDI   R16, 'K'
    RCALL data_wrt
    LDI   R16, ':'
    RCALL data_wrt
    LDS   R16, left_status
    CPI   R16, 0      ; Periksa apakah 0 atau 1
    BREQ  left_zero
    LDI   R16, '0'    ; Muat ASCII '0' (tidak ada hambatan untuk active low)
    RJMP  left_display
left_zero:
    LDI   R16, '1'    ; Muat ASCII '1' (hambatan untuk active low)
left_display:
    RCALL data_wrt

    ; Tampilkan spasi
    LDI   R16, ' '
    RCALL data_wrt

    ; Tampilkan sensor kanan (N:)
    LDI   R16, 'N'
    RCALL data_wrt
    LDI   R16, ':'
    RCALL data_wrt
    LDS   R16, right_status
    CPI   R16, 0      ; Periksa apakah 0 atau 1
    BREQ  right_zero
    LDI   R16, '0'    ; Muat ASCII '0' (tidak ada hambatan untuk active low)
    RJMP  right_display
right_zero:
    LDI   R16, '1'    ; Muat ASCII '1' (hambatan untuk active low)
right_display:
    RCALL data_wrt

    RET
