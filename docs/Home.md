# Apollo OS: The Ultimate Knowledge Base

Selamat datang di Dokumentasi Resmi Apollo OS. "Kitab Suci" ini merangkum setiap tetes keringat, ribuan baris log yang di-*debug*, setiap *kernel panic*, dan setiap keputusan teknis yang membentuk Apollo OS. 

Dokumentasi ini ditulis sebagai pedoman abadi. Jika Anda terputus dari jaringan, lupa tentang sejarah repositori, atau harus memulai ulang pengembangan dari awal, semua kepingan *puzzle* ada di sini.

## Daftar Isi "Kitab Suci"

1. **[Arsitektur dan Visi](Architecture-and-Vision.md)**
   Membahas anatomi Apollo OS: perpaduan OSTree, container `bootc`, dan GTK4 *installer* kustom (`alga`).
   
2. **[Saga Bootloader: Kematian GRUB Dummy dan Kebangkitan systemd-boot](The-Bootloader-Saga.md)**
   Kisah nyata bagaimana kita melawan *bug* bawaan Red Hat / Fedora (`bootupd`), membuang solusi *dummy*, dan menanamkan `bootctl install` murni langsung dari *installer*.

3. **[Mekanika Installer (Alga)](Installer-Mechanics.md)**
   Detail presisi tentang bagaimana *installer* mengatasi *zombie process*, partisi yang terkunci (*device busy*), *btrfs forget*, dan protokol *cancellation* ekstrem (Zeroing & Wipefs).

4. **[Alur Git & Dual Remote](Git-Workflow-and-Remotes.md)**
   Penjelasan mengapa repositori ini memiliki *remote* `gitlab` dan `origin` (GitHub), serta kesepakatan abadi bahwa **GitHub** adalah pabrik utama yang merakit ISO Apollo OS.

5. **[Pabrik ISO & GitHub Actions](05-the-builder-mechanics.md)**
   Bedah tuntas *Containerfile* dan *workflow* GitHub Actions. Membedah bagaimana `podman` dan `bootc-image-builder` menyulap kode menjadi ISO yang siap pakai.

6. **[Anatomi Kode Installer Alga](06-alga-source-code-deep-dive.md)**
   Penyelaman dalam terhadap kode sumber `/src/main.rs`. Bagaimana `tokio`, *multithreading*, *glib channels*, dan logika *progress bar* bekerja menjaga UI tidak *freeze*.

7. **[OSTree & Bootc Mastery](07-ostree-and-bootc-mastery.md)**
   Penguasaan atas konsep partisi *A/B*, transaksi pemutakhiran *atomic* (anti-rusak), serta direktori apa saja yang *read-only* (imutabel) versus *read-write*.

8. **[Kitab Darurat: Troubleshooting & Debugging](08-troubleshooting-and-debugging.md)**
   Panduan ekstrem saat terjadi kiamat sistem: menembus *TTY console*, meretas penguncian (*lock*) *cache btrfs*, dan menganalisis log *kernel panic* menggunakan `strace`!

---
*Dokumentasi ini dijaga keakuratannya layaknya sebuah jurnal sejarah. Setiap kalimat dalam halaman-halaman berikutnya adalah hukum operasional yang tidak boleh dilupakan.*
