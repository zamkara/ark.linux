# Kitab Darurat: Troubleshooting & Debugging

Pengembangan OS tingkat rendah terkadang seperti bermain api. Bencana *(panic, kernel freeze, bootloop)* bisa saja terjadi selama eksperimen. Kitab darurat ini merangkum teknik untuk selamat dari kiamat tersebut.

## 1. Menangani "Device or resource busy" (BTRFS Cache Lock)
Jika instalasi meledak karena disk target menolak di-*unmount*, itu karena modul kernel BTRFS me-lokalisasi (lock) partisi tersebut.
**Tindakan Darurat:**
- Jalankan di terminal *installer / host*: `btrfs device scan --forget`
- Diikuti oleh: `for p in /dev/sda*; do umount -l $p; done`
- Paksa pembersihan identitas disk: `wipefs -af /dev/sda*`

## 2. Bootloader Gagal Ditemukan (Blank Screen pada VM)
Anda menyalakan ISO, menginstal ke *drive* QEMU, mencabut ISO, namun hanya menjumpai layar hitam atau tulisan `No bootable medium`.
**Diagnosis:**
Kemungkinan `systemd-boot` gagal tertulis di EFI (Saga Bootloader), atau `bootctl` kekurangan hak akses/berjalan di disk yang salah.
**Cara Investigasi:**
- Buka terminal QEMU Anda saat masih berada di dalam *installer* (*Live ISO*).
- Cek isi direktori: `tree -L 4 /run/media/<user>/EFI-SYSTEM` atau `tree -L 4 /run/bootc/mounts/boot/efi`.
- Jika folder kosong atau hanya berisi file `.cfg` generik, konfigurasi instalasi bootloader di kode Alga (`main.rs`) perlu diperiksa karena `bootctl` gagal menyalin file biner `systemd-bootx64.efi`.

## 3. Menyelamatkan TTY (Akses Terminal)
Jika grafis GTK4 Alga meledak (Segmentation Fault) dan Anda terjebak di layar hitam dengan *cursor* berkedip, jangan matikan mesin virtual Anda!
**Langkah Ajaib:**
- Tekan `Ctrl + Alt + F2` atau `Ctrl + Alt + F3` (Pada GNOME Boxes, gunakan tombol *Send Keys* di sudut kanan atas jendela).
- Anda akan dibawa ke sesi *TTY Console* (layar hitam putih).
- *Login* sebagai `root`.
- Dari sini, Anda bisa membaca log menggunakan `journalctl -xe` atau menjalankan `bootc install to-disk` secara manual untuk melihat pesan *error* mentah tanpa filter antarmuka grafis.

## 4. Membaca Pikiran `bootupd` (Strace)
Jika suatu saat kita harus berurusan dengan `bootupctl` lagi dan alat itu mendadak "Kernel Panic", gunakan sihir detektif (Strace) untuk membaca *syscalls*:
```bash
strace -e trace=file bootupctl backend generate-update-metadata /
```
Perintah ini akan mencetak secara persis di direktori mana `bootupctl` berusaha mencari file `.efi` dan di baris mana program itu menyerah. (Inilah senjata rahasia yang menemukan bug `bootupd` Arch Linux).

## 5. Merestorasi Git Remote yang Hilang
Jika proyek Anda terpotong *remote*-nya, ingat konfigurasi suci ini:
```bash
git remote add origin https://github.com/zamkara/apollo.builder.git
git remote add gitlab git@gitlab.com:zamkara/apollo.build.git
```
Selalu ingat: `git push origin HEAD` adalah jalan kebenaran menuju pabrik ISO (GitHub).
