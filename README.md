# PA_MBD_Kelompok7
Repository Proyek Akhir Praktikum MBD Kelompok 7 Teknik Komputer Universitas Indonesia Semester Genap 2024/2025

## Member Kelompok 7
- Adhikananda Wira Januar - 2306267113
- Daffa Sayra Firdaus - 2306267151
- Muhammad Hilmi Al Muttaqi - 2306267082
- Laura Fawzia Sambowo - 2306260145

## Introduction to the problem and the solution
## Hardware design and implementation details
## Software implementation details
## Test results and performance evaluation

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


   


## Conclusion and future work
