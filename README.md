# Sistem Kelulusan Penceramah PPD Klang

Prototaip ini menterjemahkan flow kelulusan penceramah PPD kepada sistem web app ringkas yang boleh dibuka melalui browser dan dipasang ke telefon apabila dihoskan melalui HTTPS.

## Flow Proses

1. Sekolah melengkapkan borang pelantikan penceramah.
2. Sistem mengelaskan penceramah kepada tiga kategori:
   - Penjawat awam dalam PPD Klang
   - Penjawat awam luar daerah Klang
   - Swasta
3. Jika kategori swasta, sekolah perlu menyediakan surat jemputan kepada penceramah.
4. Sekolah menghantar permohonan kepada PPD bersama dokumen:
   - Surat iringan sekolah
   - Borang pelantikan penceramah
   - Salinan IC penceramah
   - Surat jemputan sekolah jika penceramah swasta
5. PPD menyemak dan memproses permohonan.
6. PPD mengeluarkan dua surat:
   - Surat Kelulusan Program Ceramah
   - Surat Jemputan Kepada Penceramah

## Modul Prototaip

- Dashboard permohonan
- Borang permohonan sekolah
- Semakan dokumen wajib mengikut kategori
- Flow chart proses
- Pratonton dan cetakan surat PPD

## Cadangan Status Sistem

- Draf
- Dihantar Sekolah
- Semakan Dokumen
- Diproses PPD
- Diluluskan
- Surat Dijana

## Nota Pembangunan Seterusnya

Prototaip ini kini disediakan sebagai Progressive Web App (PWA) dengan manifest aplikasi, ikon app, dan service worker cache. Apabila dihoskan melalui HTTPS, ia boleh dipasang pada telefon melalui Add to Home Screen / Install App.

Prototaip ini menggunakan `localStorage` untuk simpanan demo dalam pelayar. Untuk sistem sebenar, sambungkan modul ini kepada pangkalan data, login pengguna, kawalan peranan sekolah/PPD, muat naik dokumen, nombor rujukan rasmi, dan template surat rasmi PPD yang muktamad.
