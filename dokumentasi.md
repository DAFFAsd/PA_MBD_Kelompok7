# Dokumentasi Mobil Mini Arduino

## Deskripsi Umum
Kode ini adalah implementasi Assembly untuk mobil mini Arduino GO IVAN yang dilengkapi dengan layar LCD, dua motor DC yang dikontrol oleh driver L298 dengan PWM, dan sensor IR untuk deteksi hambatan di empat arah (depan, belakang, kiri, kanan) dengan buzzer untuk peringatan.

## Komponen Utama
1. **Layar LCD** - Menampilkan status mobil dan pembacaan sensor
2. **Motor DC** - Dua motor untuk gerakan maju/mundur dan kiri/kanan
3. **Sensor IR** - Empat sensor untuk mendeteksi hambatan di depan, belakang, kiri, dan kanan
4. **Buzzer** - Memberikan peringatan saat hambatan terdeteksi
5. **Tombol Darurat** - Tombol yang terhubung ke interupsi INT0 untuk berhenti darurat

## Konfigurasi Pin
### LCD
- E terhubung ke PB0
- RW terhubung ke Ground
- RS terhubung ke PB1
- Data LCD menggunakan nibble tinggi PORTD (PD4-PD7)

### Motor
- Motor maju/mundur:
  - IN1 terhubung ke PB5
  - IN2 terhubung ke PB4
  - ENA (PWM) terhubung ke PB3 (OC2A)
- Motor kiri/kanan:
  - IN3 terhubung ke PB2
  - IN4 terhubung ke PC4 (A4)

### Sensor IR
- Sensor depan terhubung ke PC2
- Sensor belakang terhubung ke PC3
- Sensor kiri terhubung ke PC0
- Sensor kanan terhubung ke PC1
- Semua sensor bersifat active low (0 = hambatan terdeteksi, 1 = tidak ada hambatan)

### Buzzer
- Buzzer terhubung ke PC5

### Tombol Darurat
- Tombol darurat terhubung ke PD2 (INT0)

## Struktur Kode
Kode dibagi menjadi beberapa bagian utama:

### 1. Inisialisasi dan Konfigurasi
- `LCD_write` - Inisialisasi LCD
- `init_car` - Inisialisasi komponen mobil (motor, sensor, buzzer, interupsi)

### 2. Kontrol Motor
- `motor_forward` - Menggerakkan mobil ke depan
- `motor_backward` - Menggerakkan mobil ke belakang
- `motor_left` - Memutar mobil ke kiri
- `motor_right` - Memutar mobil ke kanan
- `motor_stop` - Menghentikan semua motor

### 3. Pembacaan Sensor
- `read_sensors` - Membaca status semua sensor IR

### 4. Penanganan Hambatan
- `handle_forward_obstacle` - Menangani hambatan di depan
- `handle_backward_obstacle` - Menangani hambatan di belakang
- `handle_left_obstacle` - Menangani hambatan di kiri
- `handle_right_obstacle` - Menangani hambatan di kanan

### 5. Fungsi Tampilan
- `display_status` - Menampilkan status mobil dan sensor pada LCD

### 6. Interupsi Darurat
- `INT0_vect` - Handler interupsi untuk tombol darurat

## Cara Kerja

### Inisialisasi
1. Program dimulai dengan inisialisasi LCD dan konfigurasi pin I/O
2. Mengatur pin sensor sebagai input dengan pull-up
3. Mengatur pin motor dan buzzer sebagai output
4. Mengkonfigurasi interupsi INT0 untuk tombol darurat
5. Mengatur Timer2 untuk PWM pada motor

### Loop Utama
1. Mobil mulai bergerak maju
2. Secara terus-menerus membaca status sensor
3. Jika hambatan terdeteksi di arah pergerakan saat ini:
   - Buzzer diaktifkan
   - Mencoba mencari arah alternatif (kiri, kanan, belakang, atau depan)
   - Jika semua arah memiliki hambatan, mobil berhenti
4. Status mobil dan sensor ditampilkan pada LCD

### Tombol Darurat
1. Saat tombol darurat ditekan, interupsi INT0 dipicu
2. Mobil berhenti dan buzzer diaktifkan
3. Arah pergerakan sebelumnya disimpan
4. Saat tombol ditekan lagi, mobil kembali ke operasi normal dengan arah pergerakan sebelumnya

### Tampilan LCD
1. Baris pertama menampilkan arah pergerakan mobil (DEPAN, BELAKANG, KIRI, KANAN, STOP) atau "EMERGENCY" saat dalam mode darurat
2. Baris kedua menampilkan status sensor dengan format:
   - D:x B:x K:x N:x (Depan, Belakang, Kiri, Kanan)
   - Nilai x adalah 1 jika hambatan terdeteksi, 0 jika tidak ada hambatan

## Fungsi Utama

### run_car
Fungsi utama yang menjalankan mobil. Ini membaca sensor, menangani hambatan, dan memperbarui tampilan LCD.

### read_sensors
Membaca status semua sensor IR dan menyimpan hasilnya dalam variabel global.

### display_status
Memperbarui tampilan LCD dengan arah pergerakan saat ini dan status sensor.

### INT0_vect
Handler interupsi untuk tombol darurat yang menghentikan mobil saat ditekan dan melanjutkan operasi normal saat ditekan lagi.

## Catatan Penting
- Sensor IR bersifat active low, artinya 0 menunjukkan hambatan terdeteksi dan 1 menunjukkan tidak ada hambatan
- Buzzer hanya aktif berdasarkan nilai sensor yang sesuai dengan arah pergerakan saat ini
- Tombol darurat menggunakan interupsi INT0 yang dipicu pada falling edge
