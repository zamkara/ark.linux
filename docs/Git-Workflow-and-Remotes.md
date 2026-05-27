# Alur Git & Dual Remote

Repositori ini memiliki konfigurasi Git yang tidak biasa. Untuk mencegah kebingungan pengembang dan mencegah *error push* yang keliru, pahamilah aturan *remote* berikut:

## Struktur Remotes
Saat Anda mengetik `git remote -v`, Anda akan melihat dua remote berbeda:
1. `gitlab` (git@gitlab.com:zamkara/apollo.build.git)
2. `origin` (https://github.com/zamkara/apollo.builder.git)

## The Golden Rule (Aturan Emas)
**GitHub (`origin`) adalah PUSAT SEGALA AKTIVITAS BUILD.**

Semua kode yang ditulis, diperbaiki, dan disepakati **harus di-push ke GitHub (`origin`)**.
Alasannya: Proyek ini sangat bergantung pada ekosistem **GitHub Actions** untuk merakit *container*, mengkompilasi *alga*, dan membungkus hasil akhirnya ke dalam file `.iso`. Jika kode didorong ke GitLab, GitHub Actions tidak akan mendeteksinya, dan ISO terbaru tidak akan pernah tercipta.

## Tragedi Push Nyasar
Sejarah mencatat (seperti yang terjadi pada pengembangan fitur `APOLLO-2705261449-setup-checkpoint-script` yang memperbaiki bootloader) bahwa AI *agent* (Antigravity) sempat salah melakukan `git push` ke *branch tracking default* yang ternyata mengarah ke GitLab. Ini berakibat pada kepanikan singkat karena perubahan tidak muncul di GitHub.

Untuk mencegahnya, setiap kali Anda membuat *branch* baru atau merilis fitur kunci, **selalu gunakan perintah eksplisit**:
`git push origin HEAD` (untuk memastikan dorongan langsung mengarah ke GitHub).

GitLab dapat digunakan sebagai cadangan atau tujuan asimilasi internal, namun rilis produksi selalu ada di GitHub.
