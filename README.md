# Data Mining - Market Basket Analysis (Apriori)

Project tugas besar mata kuliah Konsep Data Mining untuk menganalisis pola pembelian konsumen menggunakan Algoritma Apriori. Aplikasi ini dibuat dengan Flutter dan bisa diakses langsung lewat web browser.

Live Demo: [https://data-mining-universitas-gunadarma.vercel.app](https://data-mining-universitas-gunadarma.vercel.app)

---

## Informasi Tim

- Kampus: Universitas Gunadarma
- Fakultas / Jurusan: FIKTI / S1 Sistem Informasi
- Kelas: 3KA31 (Kelompok 4)
- Dosen Pengampu: Dr. Dina Anggraini, S.Kom., M.M.S.I.

**Anggota Kelompok:**

1. Firdaus Dhuha Prabowo (10124497)
2. Bagas Sena Dwi Jatmika (10124237)
3. Fabio Arvin Aeneas (10124402)
4. Farid Hilmy Cordova (10124442)
5. Hesti Setiana (10124563)
6. Nur Bian'Aziza (11124490)

---

## Fitur Aplikasi

- Dashboard Apriori: Menghitung nilai Support, Confidence, dan Lift Ratio secara otomatis dari dataset transaksi.
- Skenario Split Data: Pilihan pengujian dataset master (100%, 80:20, 70:30, dan 60:40) sesuai kebutuhan analisis.
- Simulasi Kasir & Rekomendasi: Simulasi keranjang belanja interaktif yang menampilkan rekomendasi produk terkait berdasarkan hasil aturan asosiasi.
- Manajemen Data Transaksi: Dukungan impor dataset riil (format CSV/JSON) serta penambahan transaksi belanja secara manual.
- Salin Hasil Aturan: Tombol salin hasil aturan asosiasi ke clipboard dalam format tabel untuk mempermudah pengerjaan laporan.
- Dasar Teori & Jurnal: Dilengkapi popup referensi jurnal SINTA 3 (JMIB) dan sumber dataset Kaggle.

---

## Dataset & Metode

- Dataset: Groceries Market Basket Dataset (1.000 data transaksi terpilih).
- Metode: Market Basket Analysis dengan Algoritma Apriori.
- Metrik Evaluasi:
  - Support: Mengukur seberapa sering kombinasi produk dibeli bersamaan.
  - Confidence: Mengukur kepastian pembelian produk B setelah produk A dibeli.
  - Lift Ratio: Mengukur kekuatan validitas aturan (Lift > 1 menandakan asosiasi yang kuat).

---

## Cara Menjalankan Project

Pastikan sudah menginstall Flutter SDK di komputer.

1. Clone repository:

   ```bash
   git clone https://github.com/Firdaus1802/data-mining-universitas-gunadarma.git
   cd data-mining-universitas-gunadarma
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Jalankan aplikasi di browser Chrome:

   ```bash
   flutter run -d chrome
   ```
