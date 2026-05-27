# OSTree & Bootc Mastery (Sistem Imutabilitas)

Memahami teknologi di bawah kap Apollo OS sangat penting. Tanpa pemahaman ini, struktur *filesystem* bisa membingungkan pengembang yang terbiasa dengan distro Linux lawas (Arch, Debian, Ubuntu).

## 1. Konsep "Git for Operating Systems" (OSTree)
OSTree sering dijuluki sebagai "Git untuk sistem operasi". OSTree tidak menaruh peduli pada file biner atau *package manager* (`pacman` atau `apt`). Yang ia pedulikan hanyalah *tree hash* dari seluruh root *filesystem*.
- Di Apollo OS, folder `/usr` tidak bisa dimodifikasi begitu saja (Imutabilitas).
- Segala sesuatu yang membentuk sistem operasi berada di dalam `/ostree/repo`. 
- Saat Anda menyalakan sistem, kernel tidak membaca `/usr` layaknya folder biasa, melainkan me-*mount* *hardlink* (tautan keras) dari objek biner di `/ostree`. Ini membuat sistem super cepat, mustahil dihancurkan pengguna awam, dan kebal dari "ketergantungan paket" (Dependency Hell).

## 2. Partisi A/B dan Transaksi Pembaruan Atomik (Atomic Updates)
Apollo OS tidak pernah menimpa file OS lama saat melakukan *update*.
**Bagaimana proses update terjadi?**
1. Anda memanggil perintah `bootc upgrade`.
2. `bootc` menarik (pull) *image container* terbaru dari `ghcr.io` di latar belakang (seolah Anda sedang mengunduh Docker image).
3. `bootc` membangun struktur *filesystem* (Tree) baru secara paralel, bersembunyi di dalam direktori sistem tanpa menyentuh *deployment* OS Anda saat ini yang sedang menyala!
4. Jika proses mati lampu di tengah jalan? Tidak masalah, karena OS lama belum disentuh sama sekali.
5. Setelah unduhan 100% selesai, `bootc` memperbarui *Bootloader Configuration* (BLS entries di partisi EFI) untuk menunjuk ke Tree yang baru.
6. Saat Anda *reboot*, Anda masuk ke versi OS terbaru.
7. Jika versi baru mengandung cacat (*kernel panic*, *blank screen*), Anda cukup me-*reboot*, menekan spasi/F8 di menu `systemd-boot`, dan memilih Tree OS sebelumnya (Rollback Instan).

## 3. Peta Wilayah: Apa yang Bisa Diedit?
Karena `/usr` bersifat *Read-Only*, sistem tradisional harus beradaptasi.
- `/etc` (Konfigurasi): Bebas diedit. OSTree menggunakan *3-way merge* secara ajaib agar pengaturan Anda tidak terhapus saat *update* OS.
- `/var` (Data Variabel): Ini adalah tempat data dinamis. `/var/home` adalah tempat file pengguna (*home folder*). 
- Aplikasi pihak ketiga? Instal via Flatpak! Pembaruan *base OS* tidak akan pernah merusak aplikasi Anda yang berada dalam *sandbox* Flatpak.

## 4. Derived Images (Sistem Turunan)
Salah satu kekuatan super Apollo OS (`bootc`) adalah siapa pun bisa membuat varian Apollo OS (seperti *Gaming Edition* atau *Developer Edition*) hanya dengan membuat `Containerfile` sebaris:
```dockerfile
FROM ghcr.io/apollo-linux/apollo-nvidia:latest
RUN pacman -S --noconfirm steam lutris
```
Dan boom! Anda punya OS baru. Ini adalah sihir *Bootable Containers*.
