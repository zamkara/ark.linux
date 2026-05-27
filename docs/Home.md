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

---
*Dokumentasi ini dijaga keakuratannya layaknya sebuah jurnal sejarah. Setiap kalimat dalam halaman-halaman berikutnya adalah hukum operasional yang tidak boleh dilupakan.*
