# Market Basket Analysis E-Commerce — Algoritma Apriori
### Universitas Gunadarma • Fakultas Ilmu Komputer & Teknologi Informasi
**Program Studi S1 Sistem Informasi • Kelas 3KA31 • Kelompok 4 (2026)**

---

## 📌 Ringkasan Proyek

Aplikasi **Market Basket Analysis** ini dibangun untuk menganalisis pola transaksi belanja konsumen pada platform e-commerce menggunakan **Algoritma Apriori**. Sistem ini mengekstraksi kombinasi produk yang sering dibeli bersamaan (*Frequent Itemsets*) dan menghasilkan aturan asosiasi (*Association Rules*) yang valid berdasarkan metrik **Support**, **Confidence**, dan **Lift Ratio**.

Hasil analisis diintegrasikan secara langsung ke dalam fitur **Simulasi Kasir Cerdas (*Smart Checkout*)** untuk memberikan rekomendasi produk pelengkap secara otomatis dan *real-time*.

---

## 🏛️ Informasi Akademik

* **Perguruan Tinggi:** Universitas Gunadarma
* **Fakultas:** Fakultas Ilmu Komputer dan Teknologi Informasi (FIKTI)
* **Program Studi:** S1 Sistem Informasi
* **Kelas:** 3KA31
* **Mata Kuliah:** Konsep Data Mining
* **Dosen Pengampu:** Dr. Dina Anggraini, S.Kom., M.M.S.I.

### 👥 Anggota Kelompok 4

| No | Nama Anggota | NPM | Peran / Kontribusi |
|:---:|:---|:---:|:---|
| 1 | **Firdaus Dhuha Prabowo** | 10124497 | Ketua Kelompok & Lead Researcher |
| 2 | **Bagas Sena Dwi Jatmika** | 10124237 | Algoritma Apriori & Data Engine |
| 3 | **Fabio Arvin Aeneas** | 10124402 | Frontend UI/UX & Mobile Developer |
| 4 | **Farid Hilmy Cordova** | 10124442 | Data Mining Analyst & Preprocessing |
| 5 | **Hesti Setiana** | 10124563 | Business Intelligence & Evaluation |
| 6 | **Nur Bian'Aziza** | 11124490 | Dokumentasi Riset & Presentasi |

---

## ⚡ Arsitektur & Teknologi

* **Frontend:** **Flutter SDK (Dart)**
  * Antarmuka responsif untuk Mobile (Android & iOS) dan Web.
  * Desain mengadopsi prinsip **Apple iOS Human Interface Guidelines (HIG)** dengan komponen *Cupertino Inset Grouped*, tipografi *Plus Jakarta Display*, dan deteksi platform dinamis.
* **Backend / Computation Engine:** **Client-Side Edge Computing**
  * Seluruh kalkulasi Algoritma Apriori dijalankan langsung pada memori perangkat pengguna (*In-Memory Client-Side Engine*), menjamin kecepatan komputasi instan tanpa ketergantungan server terpusat.
* **Database & Storage:** **In-Memory (Client-Side RAM)**
  * Dataset transaksi diunggah via file picker (`.csv` / `.json`) dan diolah langsung di memori aplikasi (`AprioriStateManager`).
  * Data tiap pengguna bersifat terisolasi dan aman di perangkat masing-masing.
* **Layanan Cloud (Microservice):** **EmailJS REST API**
  * Layanan pengiriman kode OTP / verifikasi pendaftaran akun pengguna.
* **Infrastruktur & Hosting:** **GitHub & Netlify**
  * Repository terpusat di GitHub dengan otomatisasi publikasi web via Netlify.

---

## 🚀 Fitur Utama

1. **Dashboard Aturan Asosiasi (Apriori Analytics):**
   * Visualisasi tabel aturan asosiasi ($Antecedent \rightarrow Consequent$).
   * Pengaturan parameter interaktif: slider **Minimum Support** dan **Minimum Confidence**.
   * Indikator validitas berbasis **Lift Ratio** ($Lift > 1.0$).
2. **Simulasi Rekomendasi Kasir (Smart Checkout):**
   * Simulasi katalog belanja kasir interaktif.
   * Rekomendasi produk komplementer muncul otomatis seketika produk dimasukkan ke keranjang belanja.
3. **Manajemen Dataset Transaksi:**
   * Fitur import file dataset mandiri (format CSV / JSON).
   * Opsi *Muat Dataset Contoh* (10 transaksi retail e-commerce) untuk keperluan demonstrasi.
   * Fitur pembersihan dataset (*Clear Memory*).
4. **Navigasi & Tata Letak iOS:**
   * Struktur navigasi elegan dengan bottom navigation bar.
   * Modal informasi sistem dan profil akademik terpadu.

---

## 📊 Metrik Data Mining

Sistem mengevaluasi aturan asosiasi dengan 3 metrik utama:

1. **Support:**
   $$\text{Support}(A \cup B) = \frac{\text{Jumlah transaksi berisi } A \text{ dan } B}{\text{Total seluruh transaksi}}$$

2. **Confidence:**
   $$\text{Confidence}(A \rightarrow B) = \frac{\text{Support}(A \cup B)}{\text{Support}(A)}$$

3. **Lift Ratio:**
   $$\text{Lift}(A \rightarrow B) = \frac{\text{Confidence}(A \rightarrow B)}{\text{Support}(B)}$$
   * Nilai **Lift > 1.0** menandakan adanya hubungan asosiasi yang positif dan kuat antar produk.

---

## 🛠️ Panduan Instalasi & Menjalankan Aplikasi

### Prasyarat
* [Flutter SDK](https://flutter.dev) (versi $\ge$ 3.2.0)
* [Git](https://git-scm.com)
* Web Browser (Chrome / Edge / Safari) atau Android Device / Emulator

### Langkah-langkah
1. **Clone repositori:**
   ```bash
   git clone https://github.com/Firdaus1802/data-mining-universitas-gunadarma.git
   cd data-mining-universitas-gunadarma
   ```

2. **Unduh dependensi pustaka:**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi (Mode Debug):**
   ```bash
   # Menjalankan di Chrome (Web)
   flutter run -d chrome

   # Menjalankan di perangkat Android
   flutter run -d android
   ```

4. **Kompilasi versi Web Release (untuk Netlify):**
   ```bash
   flutter build web --release
   ```

---

## 📜 Hak Cipta & Lisensi

Proyek ini dikembangkan untuk keperluan akademik tugas besar mata kuliah **Konsep Data Mining**, Program Studi S1 Sistem Informasi, Fakultas Ilmu Komputer dan Teknologi Informasi, **Universitas Gunadarma** © 2026.
