# Pabrik ISO & GitHub Actions (The Builder Mechanics)

Halaman ini membedah anatomi dari "pabrik" yang merakit Apollo OS. Tidak ada ISO yang dikompilasi secara manual di komputer pengembang; semuanya diotomatisasi melalui GitHub Actions dan Dockerfile/Containerfile.

## 1. Membedah Containerfile
`Containerfile` adalah resep masakan untuk sistem operasi Anda. Tidak seperti distribusi tradisional yang merakit ISO dengan *chroot* berjam-jam, kita merakit *container image* yang nantinya akan dikonversi menjadi ISO.

Berikut adalah fase krusial dalam `Containerfile` (`apollo.builder`):
- **Base Image:** `FROM ghcr.io/apollo-linux/apollo-nvidia:latest`. Ini adalah fondasi Arch Linux yang sudah dikonfigurasi dengan *driver* NVIDIA dan *desktop environment* oleh tim *upstream*.
- **Inject AUR Packages:** `COPY aur-packages/*.pkg.tar.zst /tmp/`. Semua paket AUR lokal yang sudah dikompilasi (termasuk *installer* Alga jika dipaketkan sebagai `.pkg.tar.zst`) disuntikkan ke dalam *image*.
- **Instalasi Dependency Kritis:**
  ```dockerfile
  RUN pacman -Syu --noconfirm && \
      pacman -S --noconfirm util-linux openssl grub efibootmgr dosfstools ostree skopeo btrfs-progs podman composefs
  ```
  Alat-alat ini adalah nyawa dari `bootc`. `skopeo` untuk menarik *image*, `ostree` untuk menata struktur direktori OS, `composefs` untuk verifikasi *read-only*, dan `btrfs-progs` karena kita menggunakan *filesystem* BTRFS.
- **The "No-Bootupd" Policy:** Seperti yang dibahas di *Saga Bootloader*, `bootupd` dihilangkan atau dikonfigurasi sebagai program pasif. Tidak ada lagi `grub-mkimage` dummy. `bootc` dipaksa patuh pada perintah `--bootloader none` nantinya.

## 2. Bedah Tuntas GitHub Actions (`build-iso.yml`)
Pabrik sejati Apollo OS ada di awan (*cloud*). 
- Saat Anda menekan `git push origin HEAD`, GitHub secara otomatis membaca `.github/workflows/`.
- **Fase 1: Podman Build.** *Runner* GitHub akan mengeksekusi `podman build -t apollo-os .`. Ini akan mengeksekusi instruksi di `Containerfile`.
- **Fase 2: bootc-image-builder.** Image yang sudah jadi tidak bisa langsung di-flash ke *flashdisk*. Kita menggunakan alat resmi Red Hat yaitu `bootc-image-builder` (sering dipanggil via container) untuk mengubah OCI Container Image menjadi file `install.iso`.
- **Fase 3: Artifact Upload.** ISO yang telah jadi akan diunggah ke GitHub Releases atau GitHub Actions Artifacts agar Anda bisa mengunduhnya.

## 3. Keuntungan Pendekatan Container-Native
Dengan pendekatan ini, **tidak ada dependensi yang hilang**. Jika `pacman` gagal menginstal sesuatu, proses `podman build` akan meledak di GitHub Actions, dan ISO yang cacat TIDAK AKAN PERNAH dirilis ke pengguna. 
Ini menjamin garansi bahwa setiap ISO yang berhasil diunduh adalah ISO yang strukturnya sudah diverifikasi secara komputasi.
