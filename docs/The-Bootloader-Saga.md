# Saga Bootloader: Kematian GRUB Dummy dan Kebangkitan systemd-boot

Halaman ini mendokumentasikan peperangan terlama dalam pengembangan instalasi Apollo OS: Menghadirkan *bootloader* yang bersih, *native*, dan tidak rentan rusak.

## Latar Belakang Masalah
Utilitas instalasi `bootc` secara baku mendelegasikan instalasi dan konfigurasi bootloader kepada binari pihak ketiga bernama `bootupd`. Masalahnya: `bootupd` dikembangkan oleh Red Hat dengan asumsi mutlak bahwa OS menggunakan Fedora/CentOS.

Apollo OS menggunakan **Arch Linux**. Arsitektur Arch Linux mendistribusikan `systemd-boot` (file `systemd-bootx64.efi`) murni tanpa dibungkus modul *Secure Boot* (*shim*) yang dipaksakan atau di-*sign* dengan kunci spesifik ala Fedora.

## Percobaan 1: Solusi "GRUB Dummy"
Pada awalnya, `bootupd` menolak keras untuk membuat metadata karena tidak mendeteksi eksistensi komponen bootloader yang familiar baginya. 
Untuk "menipu" mekanisme ini, kita sempat memasukkan trik ke dalam `Containerfile`:
1. Membuat direktori palsu `/usr/lib/efi/dummy/`.
2. Menghasilkan *image* GRUB kosong (*dummy*) menggunakan `grub-mkimage`.
3. Menulis skrip `rpm` palsu agar `bootupd` mengira ia berjalan di Fedora.

**Mengapa ini dihapus?**
Solusi ini berhasil membiarkan *image* dikonstruksi tanpa *error*. Namun, saat ISO dirakit dan `bootc install to-disk` dieksekusi di *host* QEMU/GNOME Boxes nyata, partisi EFI (`/boot/efi`) berujung **kosong**. GRUB palsu tersebut tidak bisa diterjemahkan oleh OSTree sebagai bootloader yang valid. Akibatnya, instalasi sukses tetapi OS tidak bisa *booting*.
Pengguna pun secara eksplisit menyatakan: *"Itu namanya harus dummy gitu? Kesannya kek amatir bgt."* — sebuah kritik tajam namun sangat valid.

## Percobaan 2: Menundukkan bootupd (Gagal)
Kami kemudian mencoba memaksa `bootupd` agar mengenali `systemd-bootx64.efi` secara murni. Kami menghapus trik GRUB dan memasukkan komponen EFI systemd-boot. 
Hasilnya? `bootupctl backend generate-update-metadata` mengalami **Kernel Panic / Rust Panic** secara internal (dengan galat: `assertion failed: efi_components.len() > 1`). 
Usut punya usut (setelah melakukan `strace`), `bootupd` ternyata tidak dirancang untuk menangani instalasi `systemd-boot` di Arch Linux karena ia mewajibkan eksistensi banyak versi file (misal: x64, ia32, atau file pendamping *shim*) dalam folder `/usr/lib/efi` yang merupakan standar distro spesifik, bukan standar Arch.

## Solusi Final: Hybrid "Native Alga"
Daripada memaksa alat yang cacat (*bootupd*), kita mengambil jalan paling profesional:
1. **Pembersihan Total:** Kata "dummy" dan instalasi `bootupctl backend` dihapus tanpa sisa dari `Containerfile`.
2. **Bypass:** `bootc` diperintahkan secara tegas untuk tidak mengurus bootloader dengan argumen `--bootloader none`.
3. **Instalasi Murni (The Elegance):** Segera setelah `bootc` selesai dan sukses memindahkan sistem file, *installer* bawaan kita (`alga`) mengambil alih kendali! 
   `alga` secara dinamis mendeteksi letak partisi EFI (`c12a7328-f81f-11d2-ba4b-00a0c93ec93b`), melakukan *mount* ke folder `/tmp/efi_mnt`, dan langsung memanggil perintah `bootctl install --esp-path=/tmp/efi_mnt`.

**Hasil Akhir:** Apollo OS memiliki instalasi *systemd-boot* yang 100% *native*, elegan, legal di mata Arch Linux, terbaca sempurna oleh mekanisme BLS (*Boot Loader Specification*), dan bebas dari trik amatir!
