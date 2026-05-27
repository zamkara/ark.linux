# Arsitektur dan Visi Apollo OS

Halaman ini mengabadikan visi inti dan struktur teknis dari Apollo OS, memastikan agar tujuan pengembangan tidak pernah menyimpang dari fondasi awalnya.

## Visi Utama
Apollo OS bukan sekadar distribusi Linux tradisional. Apollo OS adalah sistem operasi berbasis *image* (Image-Based OS) masa depan. Filosofinya adalah imutabilitas (tidak dapat diubah sembarangan di level akar), kemudahan pemulihan (*rollback*), dan distribusi berbasis *container*. Jika sebuah sistem rusak, pengguna dapat dengan mudah memulihkan sistem tersebut ke versi *container* sebelumnya.

## Anatomi Sistem

Apollo OS dirangkai dari tiga komponen reaktor utama:

### 1. OSTree & Container-Native (bootc)
Apollo OS didistribusikan selayaknya sebuah *image Docker/Podman*. Berbeda dengan instalasi Linux tradisional yang mengurai paket `.rpm` atau `.pkg.tar.zst` satu per satu di mesin pengguna, Apollo OS dirakit penuh di peladen CI/CD (GitHub Actions).
Alat utama yang digunakan adalah `bootc` (Bootable Containers). `bootc` mengonversi *image* OCI menjadi sistem *file* yang dapat langsung di-*boot* menggunakan arsitektur OSTree.

### 2. Alga: Installer Cerdas Berbasis Rust + GTK4
Alih-alih menggunakan *installer* generik seperti Calamares atau Anaconda, Apollo OS memiliki *installer* independen bernama **Alga**.
- **Bahasa:** Rust, memberikan keamanan memori, konkurensi (melalui `tokio`), dan performa tinggi tanpa kompromi.
- **Antarmuka:** GTK4 + Libadwaita, menjamin tampilan *Modern Web/GNOME-like* yang cantik, responsif, dan elegan.
- **Tugas Utama:** Alga bertugas mengatur disk (BTRFS), mengeksekusi `bootc install to-disk`, menangani *error parsing*, serta menyuntikkan *bootloader*.

### 3. CI/CD Pipeline (Pabrik ISO)
Semuanya dirangkai secara otomatis. Kode *base* ada di `ghcr.io/apollo-linux/apollo-nvidia:latest`. Repositori `apollo.builder` memiliki *Containerfile* yang mengambil basis tersebut, menyuntikkan komponen lokal (paket AUR), mengkompilasi installer, dan membungkusnya menjadi `.iso` mandiri melalui GitHub Actions.

## Mengapa Harus Demikian?
Dengan pendekatan ini, keadaan ("state") dari sistem operasi dapat diprediksi secara matematis. Tidak ada lagi ketergantungan paket yang rusak parsial di sisi pengguna. Setiap instalasi Apollo OS di seluruh dunia secara *bit-for-bit* identik dengan apa yang lulus tes di GitHub Actions.

---
*Catatan Sejarah: Struktur ini disepakati setelah eksperimen berdarah-darah untuk memisahkan logika kotor bootloader dari dalam container (lihat [Saga Bootloader](The-Bootloader-Saga.md)).*
