# Anatomi Kode Installer Alga (Source Code Deep Dive)

Kode *source* `alga` (`/src/main.rs`) adalah jantung grafis dan logistik dari Apollo OS. Kita menggunakan Rust dan GTK4 (via *binding* `gtk4-rs` dan `libadwaita`). Berikut adalah bedah tuntas bagaimana kode ini bekerja.

## 1. Antarmuka Grafis (UI) & Libadwaita
Fungsi utama GUI didefinisikan dalam `build_ui(app: &Application)`.
- **`adw::ApplicationWindow`**: Membuat jendela aplikasi utama dengan desain bundar modern.
- **`gtk::DropDown`**: Digunakan untuk menampilkan daftar penyimpanan (disk). Fungsi `get_host_drives()` melakukan pemindaian sistem operasi secara waktu nyata (*real-time*) dengan memanggil perintah `lsblk -d -n -o NAME,SIZE,MODEL`. Hasil dari pemindaian ini dimasukkan ke dalam `gtk::StringList` agar pengguna bisa memilih *drive* yang akan dieksekusi.
- **`gtk::TextView`**: Sebagai konsol terminal mini di dalam UI. Di sinilah log `bootc` akan dicetak baris demi baris, sehingga proses instalasi terlihat transparan.

## 2. Asynchronous Multithreading (Tokio & Glib Channel)
Satu kesalahan terbesar pembuat *installer* amatir adalah meletakkan proses instalasi (`Command::new(...)`) di dalam benang eksekusi GUI (*Main Thread*). Akibatnya, UI akan *freeze* atau *Not Responding*.

**Cara Alga Mencegah Ini:**
1. **`glib::MainContext::channel`**: Ini adalah pipa komunikasi (jembatan) antara benang eksekusi latar belakang dengan UI. UI (GTK) mendengarkan pipa ini menggunakan `receiver.attach(...)`.
2. **`std::thread::spawn` & `tokio::runtime::Runtime`**: Saat pengguna mengklik tombol "Install", kita memutar (*spawn*) benang *thread* baru sepenuhnya terpisah dari UI. Di dalam *thread* ini, kita menyalakan mesin `tokio` (Asynchronous Runtime).
3. Melalui mesin `tokio`, kita mengeksekusi `bootc install to-disk` secara asinkron (`tokio::process::Command`), menangkap `stdout` dan `stderr` tanpa memblokir sistem. Setiap kali sebaris log baru dicetak oleh `bootc`, `tokio` mengirimkannya ke UI menggunakan `sender.send(...)`. UI kemudian secara magis memperbarui teks konsolnya tanpa patah-patah (*lag*).

## 3. Ekstraksi Progress Bar (Logika `sanitize_log`)
Bagaimana `alga` tahu bahwa instalasi sudah 45%? 
Logika ekstraksinya terdapat dalam fungsi kustom `sanitize_log(raw: &str)`.
- Sistem mendeteksi karakter `%` di setiap baris log masuk.
- Sistem berjalan mundur dari indeks `%` untuk mengumpulkan karakter numerik (`45`, `90`, dst.).
- Persentase ini kemudian dikirim ke UI untuk memodifikasi teks bilah judul (`title4.set_label`).
- Selain mengekstrak persentase, fungsi ini juga meredam (*mute*) baris sampah seperti "I/O size", "Wiping", "Disk identifier", agar terminal mini di layar pengguna terlihat sangat rapi dan profesional.

## 4. Mekanisme Pembatalan (Tokio Select)
Fitur tercanggih di `alga` adalah implementasi `tokio::select!`.
Makro ini menunggu **dua hal secara bersamaan**:
1. Menunggu log baru dari perintah instalasi.
2. Menunggu sinyal "Batal" (`kill_rx`) yang dipicu jika pengguna menekan tombol "Back/Cancel".

Jika sinyal `kill_rx` diterima lebih dulu, `tokio` langsung "memenggal" eksekusi instalasi (`child_install.kill()`) seketika, dan meluncurkan protokol Pembatalan Brutal (`wipefs`, `dd`, `umount`, `partprobe`) yang dibahas di *Installer Mechanics*.
