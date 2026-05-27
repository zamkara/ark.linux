# Mekanika Installer (Alga)

Alga bukan sekadar pembungkus grafis. Ia adalah "komandan operasi" yang menjamin pemasangan berjalan tanpa henti dan membersihkan setiap masalah secara diam-diam. Berikut adalah rekayasa mekanik di dalam `main.rs` yang menjadi fondasi stabilitas instalasi Apollo OS.

## 1. Pembersihan Log & Ekstraksi Progress
`bootc` menghasilkan keluaran teks (stdout) yang kasar, repetitif, dan sangat teknis. Untuk pengguna akhir, informasi ini bisa mengintimidasi.
Alga menggunakan fungsi `sanitize_log` di `main.rs` untuk:
- Mencegat keluaran log baris demi baris menggunakan `tokio::process`.
- Mencari kemunculan pola angka (misalnya `[=====] 45%`) dan mengekstraknya sebagai penanda progress UI di bilah judul aplikasi (misal: **45% Installing...**).
- Memfilter ribuan baris log sampah (*blacklist*) seperti informasi sektor memori atau `ioctl`.
- Mengubah istilah teknis menjadi pesan mesra pengguna. (Contoh: "initializing ostree layout" diterjemahkan menjadi *"Initializing immutable system layout..."*).

## 2. Anti-Device Busy (The Kernel Cache Trap)
Kerap kali kernel Linux "mengingat" struktur disk dari sesi sebelumnya. Saat *installer* mencoba menimpa struktur disk, instalasi akan meledak dengan galat `Device or resource busy`.
**Solusi Alga:**
Sebelum perintah `bootc install to-disk` dimulai, Alga akan melepaskan pukulan mematikan:
`btrfs device scan --forget`
Perintah ini memaksa modul kernel BTRFS untuk melupakan semua *cache* pemetaan disk lama, membebaskan disk dari status "sibuk".

## 3. Zombie Process Killer
Jika terjadi *error* atau jika pengguna membatalkan (cancel) instalasi di tengah jalan, komponen biner `bootc` atau `skopeo` sering kali meninggalkan *zombie process* yang memakan RAM dan tetap mengunci disk.
**Solusi Alga:**
Setiap kali alur dimulai atau dihentikan, perintah `killall -9 bootc skopeo` secara agresif ditembakkan tanpa ampun untuk membersihkan panggung sebelum operasi kritis dijalankan.

## 4. Protokol Pembatalan Brutal (The Zeroing Sequence)
Ketika pengguna menekan tombol "Cancel", kita tidak bisa hanya membiarkan disk berantakan. Pengguna sangat menekankan aturan: *"Kalau cancel, drive harus kembali benar-benar kosong, unformatted, tanpa partisi, unschema (bukan GPT, bukan MBR)."*
**Tindakan Alga:**
1. Hentikan (kill) *installer thread*.
2. `umount -l` (Lazy Unmount) secara rekursif terhadap semua partisi target agar disk tidak terkunci.
3. `wipefs -af` (Menghapus *magic strings* dan identitas partisi secara instan).
4. `dd if=/dev/zero of=<DISK> bs=1M count=10` (Menghancurkan 10MB pertama disk secara fisik, melenyapkan Master Boot Record (MBR) maupun tabel GPT, mengembalikannya ke kondisi pabrik mentah).
5. `partprobe` (Memaksa kernel membaca ulang disk agar sistem *host* sadar bahwa disk tersebut sudah kosong).

Dengan protokol ini, "Cancel" berarti benar-benar "Kembali ke 0".

## 5. Sinkronisasi Bootloader Murni
Seperti yang tertulis pada *Saga Bootloader*, Alga juga memiliki logika akhir untuk mencari partisi EFI berdasarkan GUID `c12a7328-f81f-11d2-ba4b-00a0c93ec93b` dan memasang `systemd-boot` secara *native* pada tahap akhir instalasi (di kondisi 95% selesai).
