# AprioriMart - Market Basket Analysis (Apriori)

Aplikasi Market Basket Analysis E-Commerce menggunakan Algoritma Apriori untuk tugas besar mata kuliah Konsep Data Mining, S1 Sistem Informasi Universitas Gunadarma. Aplikasi ini dibuat dengan Flutter dan bisa diakses langsung lewat web browser.

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

1. **Dataset Utama (1.500 Transaksi - Rekomendasi Dosen)**:
   - File: `market_basket_dataset.csv` / `market_basket_dataset.arff` / `market_basket_dataset.xlsx`
   - Karakteristik: 1.500 transaksi, 10 atribut produk (`Milk, Bread, Butter, Cheese, Eggs, Juice, Chips, Soda, Chicken, Apples`).
   - Kondisi Data: Memiliki 8.670 sel kosong (*missing values* alami 57,8%) untuk pengujian tahap Data Understanding dan Data Cleaning sebelum dianalisis dengan algoritma Apriori.

2. **Dataset Cadangan / Benchmark (7.501 Transaksi - Kaggle)**:
   - File: `Market_Basket_Optimisation.csv` / `Market_Basket_Optimisation.arff` / `Market_Basket_Optimisation.xlsx`
   - Karakteristik: 7.501 struk belanja riil kasir dengan 119 kategori produk untuk pengujian skala besar.

- **Metode**: Market Basket Analysis dengan Algoritma Apriori.
- **Tools Pengujian Terintegrasi**:
  - **Aplikasi Web & Android (AprioriMart)**: Dashboard interaktif dengan simulasi kasir, dynamic partition split (80:20, 70:30, 100%), dan ekspor kaidah asosiasi.
  - **WEKA Explorer 3.8.7**: Pengujian visualisasi missing value pada tab *Preprocess* dan mining aturan asosiasi pada tab *Associate*.
  - **Python Jupyter / Google Colab**: Eksekusi end-to-end dengan library `pandas` dan `mlxtend` (`notebook_market_basket_dataset_apriori.ipynb`).
  - **Microsoft Excel**: File spreadsheet dengan kolom terpisah rapi (A s.d. J) untuk dokumentasi laporan.
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
