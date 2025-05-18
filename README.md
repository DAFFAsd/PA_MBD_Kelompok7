# PA_MBD_Kelompok7
Repository Proyek Akhir Praktikum MBD Kelompok 7 - Teknik Komputer Universitas Indonesia - Semester Genap 2024/2025

## Member Kelompok 7
- Adhikananda Wira Januar - 2306267113
- Daffa Sayra Firdaus - 2306267151
- Laura Fawzia Sambowo - 2306260145
- Muhammad Hilmi Al Muttaqi - 2306267082

## Content
[Introduction to the Problem and the Solution](#introduction-to-the-problem-and-the-solution)
[Hardware Design and Implementaion Details](#hardware-design-and-implementation-details)
[Software Implementation Details](#software-implementation-details)
[Test Results and Performance Evaluation](#test-results-and-performance-evaluation)
[Conclusion and Future Work](#conclusion-and-future-work)

## Introduction to the Problem and the Solution
Proyek ini mengatasi kebutuhan sistem pengantaran barang ringan otomatis di lingkungan kerja seperti kantor, restoran, atau hotel. Pengantaran manual oleh staf manusia sering memakan waktu, mengganggu alur kerja, dan menambah beban operasional. GoVan (Go I.V.A.N - Integrated Vehicle for Autonomous Navigation) adalah prototipe mobil mini otomatis yang dirancang untuk bergerak secara mandiri dan menghindari hambatan menggunakan sensor serta logika navigasi berbasis mikrokontroler. Mobil ini dilengkapi dengan empat sensor inframerah untuk mendeteksi hambatan dari empat arah berbeda, dengan pengambilan keputusan melalui logika pemrograman berurutan (polling) berdasarkan prioritas arah.

## Hardware design and implementation details
Komponen utama yang digunakan dalam perancangan hardware GoVan meliputi:
- 4 Infrared Sensor untuk mendeteksi obstruksi dari empat arah
- 2 DC Motor untuk menggerakkan roda
- Monitor LCD sebagai indikator visual
- Button untuk emergency stop
- Buzzer sebagai indikator audio
- Arduino Uno sebagai pengontrol utama sistem
- L298N Motor Driver untuk mengendalikan motor

Sistem ini menggunakan mikrokontroler Arduino Uno sebagai otak utama, dengan sensor inframerah yang dipasang di empat sisi untuk mendeteksi hambatan. Motor DC dikendalikan melalui driver L298N untuk mengatur pergerakan roda. Indikator visual (LCD) dan audio (buzzer) memberikan umpan balik real-time tentang status sistem.

## Software Implementation Details
Perangkat lunak ditulis dalam bahasa Assembly AVR, dengan menggunakan AVR Studio IDE untuk pengembangan. Sistem dirancang untuk bergerak maju secara default dan menghindari rintangan dengan mengecek arah alternatif (kanan/kiri/belakang) menggunakan sensor IR. Logika pengecekan obstacle dilakukan secara berurutan (polling) dengan prioritas: depan → kiri → kanan → belakang.

Komponen-komponen kunci dari perangkat lunak ini mencakup:
- Inisialisasi tampilan LCD untuk menampilkan status arah dan sensor
- Pembacaan input digital dari sensor IR untuk mendeteksi hambatan
- Penggunaan interupsi eksternal untuk mengaktifkan mode berhenti darurat
- Logika navigasi berdasarkan data sensor
- Kontrol motor untuk bergerak maju, mundur, berbelok, atau berhenti
- Aktivasi buzzer sebagai peringatan saat terdapat hambatan

## Test Results and Performance Evaluation

1. Secara default bergerak ke depan misalkan tidak ada obstacle
   ![image](https://github.com/user-attachments/assets/9ea5d7fd-a53e-441c-9b27-26f4cdfe9d95)
2. Jika obstacle terdeteksi didepan, maka ia polling cek sensor. walaupun kanan aman, ia akan ke kiri dulu karena sensor kiri lah yang dicek lebih awal
   ![image](https://github.com/user-attachments/assets/96a2cc68-3b2c-44ff-aa6f-309db72fee1b)
3. Selebihnya seperti yang sudah dijelaskan di dokumentasi, terkait pergerakan mobilnya. Untuk tombol digunakan sebagai emergency STOP yang menghentikan 2 motor
   ![image](https://github.com/user-attachments/assets/0a23823c-28e1-4cc3-aaed-3951c18dfb6a)
4. Evaluasi dan kekurangan dari rangkaian serta kode ini adalah terkait delay yang ada dari infrared kadang agak lama (bisa dilihat testpin seharusnya nilainya sama dengan vout, tapi ada delay sehingga beda)
   ![image](https://github.com/user-attachments/assets/aaf90bf9-4e85-4e85-a232-a9060d1e6b25)
5. Nyalanya Buzzer juga sebenarnya kurang sesuai ketentuan , mungkin lain kali akan memakai IC saja (permasalahannya sekarang ia nyala terus, mati kalau emergency/stop)
   ![image](https://github.com/user-attachments/assets/968069f0-04da-4d5e-bde3-2e2169fb5741)

## Conclusion and Future Work
Proyek GoVan telah berhasil memenuhi tujuan utama yaitu mampu bergerak maju secara otomatis dan melakukan navigasi dengan sensor infrared multi-arah yang efektif dalam mendeteksi dan menghindari hambatan. Sistem pengendalian motor menggunakan sinyal PWM menghasilkan pergerakan yang halus dan stabil, sementara fitur emergency stop berfungsi dengan baik untuk menghentikan mobil secara instan.

Beberapa kendala yang ditemukan dalam pengujian meliputi delay sensor infrared yang memperlambat respons terhadap hambatan, serta buzzer yang terus menyala saat deteksi hambatan yang kurang efisien. Untuk pengembangan masa depan, optimasi sensor atau penggantian dengan yang lebih cepat serta kontrol buzzer yang lebih teratur disarankan untuk meningkatkan performa sistem secara keseluruhan.
