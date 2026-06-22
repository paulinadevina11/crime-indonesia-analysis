# **Analisis Kriminalitas Indonesia**
 
Pipeline lengkap dari ekstraksi data PDF → SQL database → Machine Learning → Dashboard HTML interaktif untuk menganalisis dan memprediksi tingkat kriminalitas 34 provinsi di Indonesia.
 
---
 
## Tentang Project
 
Project ini membangun end-to-end data pipeline menggunakan data resmi BPS (Badan Pusat Statistik) dari publikasi *Statistik Kriminal* tahun 2015–2024. Tujuannya adalah mengklasifikasikan **danger level** tiap provinsi dan memprediksi crime rate ke depan menggunakan model Machine Learning.
 
**Highlights:**
- Ekstraksi otomatis dari PDF BPS dengan `pdfplumber`
- Database SQLite dengan star schema + SQL views
- 3 model klasifikasi (Logistic Regression, Random Forest, XGBoost)
- 2 model regresi (Linear Regression, Ridge Regression)
- Dashboard interaktif 7 halaman berbasis HTML standalone + Plotly.js (tanpa server)
---
 
## Struktur Project
 
```
crime-indonesia-analysis/
│
├── data/
│   ├── raw/                        ← PDF & CSV mentah dari BPS
│   │   ├── BPS-statistik-kriminal-*.pdf
│   │   ├── Population...Province, *.csv
│   │   ├── Tingkat Pengangguran...*.csv
│   │   └── gadm41_IDN_1.json.zip   ← GeoJSON batas provinsi Indonesia
│   ├── extracted/                  ← Hasil ekstraksi
│   │   ├── crime_raw.csv
│   │   ├── population_raw.csv
│   │   └── unemployment_raw.csv
│   ├── cleaned/                    ← Data bersih & merged
│   │   ├── crime_merged.csv
│   │   ├── crime_cleaned.csv
│   │   ├── population_cleaned.csv
│   │   └── unemployment_cleaned.csv
│   └── features/                   ← Dataset ML siap pakai
│       ├── ml_dataset.csv
│       ├── ml_dataset_scaled.csv
│       ├── scaler_info.csv
│       ├── train.csv / test.csv
│       ├── features_final.csv
│       ├── features_train.csv
│       ├── features_test.csv
│       ├── feature_summary.csv
│       ├── feature_importance.csv
│       ├── classification_report.csv
│       ├── regression_report.csv
│       └── predictions.csv
│
├── database/
│   ├── crime_indonesia.db          ← SQLite database
│   └── schema.sql                  ← DDL dokumentasi
│
├── models/
│   ├── clf_logistic.pkl
│   ├── clf_random_forest.pkl
│   ├── clf_xgboost.pkl
│   ├── reg_linear.pkl
│   └── reg_ridge.pkl
│
├── notebooks/
│   ├── 01_extract_pdf.ipynb        ← Ekstraksi PDF & CSV
│   ├── 02_cleaning.ipynb           ← Cleaning, validasi, merge
│   ├── 03_load_sql_db.ipynb        ← Build SQLite database
│   ├── 04_preprocessing.ipynb      ← Preprocessing untuk ML
│   ├── 05_feature_engineering.ipynb ← Feature engineering
│   └── 06_modelling.ipynb          ← Training & evaluasi model
│
├── dashboard/
│   ├── dashboard.html              ← Dashboard HTML interaktif (file utama)
│   └── requirements.txt            ← Dependensi pembangkit dashboard
│
└── README.md
```
 
---
 
## Cara Menjalankan
 
### 1. Clone & Setup
 
```bash
git clone https://github.com/username/crime-indonesia-analysis.git
cd crime-indonesia-analysis
pip install pandas numpy scikit-learn xgboost pdfplumber plotly
```
 
### 2. Siapkan Data Mentah
 
Letakkan file PDF dan CSV BPS di folder `data/raw/` (sudah tersedia di repo).
 
### 3. Jalankan Pipeline (via Notebook)
 
Buka dan jalankan notebook secara berurutan di folder `notebooks/`:
 
```
01_extract_pdf.ipynb       → Ekstraksi PDF & CSV
02_cleaning.ipynb          → Cleaning & merge
03_load_sql_db.ipynb       → Build SQLite database
04_preprocessing.ipynb     → Preprocessing ML
05_feature_engineering.ipynb → Feature engineering
06_modelling.ipynb         → Training & evaluasi model
```
 
### 4. Buka Dashboard
 
Dashboard berupa file HTML standalone — cukup buka langsung di browser, tanpa perlu menjalankan server:
 
```bash
open dashboard/dashboard.html      # macOS
# atau klik dua kali file dashboard/dashboard.html
```
 
---
 
## Alur Pipeline
 
```
PDF BPS (2015–2024)
       ↓
01_extract_pdf.ipynb  →  crime_raw.csv, population_raw.csv, unemployment_raw.csv
       ↓
02_cleaning.ipynb     →  crime_merged.csv  (331 baris × 34 provinsi × 10 tahun)
       ↓
03_load_sql_db.ipynb  →  crime_indonesia.db  (star schema + 3 SQL views)
       ↓
04_preprocessing.ipynb →  ml_dataset.csv  (imputasi, encoding, StandardScaler)
       ↓
05_feature_engineering.ipynb → features_final.csv  (lag, MA, YoY, danger level)
       ↓
06_modelling.ipynb    →  5 model .pkl + classification/regression report
       ↓
dashboard/dashboard.html  →  Dashboard HTML interaktif (7 halaman)
```
 
---
 
## Machine Learning
 
### Fitur
 
| Fitur | Deskripsi |
|-------|-----------|
| `crime_rate_lag1` | Crime rate tahun sebelumnya (t-1) |
| `crime_rate_lag2` | Crime rate 2 tahun sebelumnya (t-2) |
| `crime_rate_ma3` | Moving average 3 tahun |
| `crime_rate_yoy_change` | % perubahan year-over-year |
| `trend_direction_enc` | Arah tren: Naik(1) / Stabil(0) / Turun(-1) |
| `population_density` | Kepadatan penduduk (jiwa/km²) |
| `unemployment_rate` | Tingkat pengangguran (%) |
| `unemp_x_density` | Interaksi: pengangguran × kepadatan |
| `crime_per_density` | Crime rate relatif terhadap kepadatan |
 
### Target Klasifikasi: Danger Level
 
| Label | Threshold (crime rate/100K) |
|-------|----------------------------|
| Rendah | < 100 |
| Sedang | 100 – 200 |
| Tinggi | 200 – 350 |
| Berbahaya | ≥ 350 |
 
### Split Data
 
- **Train**: 2015–2021 (time-based, bukan random)
- **Test**: 2022–2024
### Hasil Model
 
| Model | Accuracy | F1-Macro |
|-------|----------|----------|
| Logistic Regression | ~0.67 | ~0.60 |
| Random Forest | ~0.71 | ~0.63 |
| XGBoost | ~0.73 | ~0.65 |
 
| Model | RMSE | R² |
|-------|------|-----|
| Linear Regression | ~45 | ~0.74 |
| Ridge Regression | ~43 | ~0.76 |
 
---
 
## Database Schema
 
```sql
dim_province  (id, provinsi, pulau, region)
dim_year      (id, tahun)
fact_crime    (province_id, tahun, crime_total, is_outlier, crime_rate_per100k)
fact_population (province_id, tahun, population, population_density, is_extrapolated)
fact_unemployment (province_id, tahun, unemployment_rate)
 
-- Views
v_crime_summary    -- join semua fakta per provinsi per tahun
v_top_dangerous    -- ranking provinsi paling berbahaya per tahun
v_trend_national   -- rata-rata nasional crime rate per tahun
```
 
---
 
## Dashboard — 7 Halaman

| Halaman | Konten |
|---------|--------|
| 🏠 Beranda | KPI cards, top 10 provinsi berbahaya, distribusi danger level, tren nasional |
| 🗺️ Peta | Bubble map interaktif per provinsi, warna berdasarkan danger level |
| 📈 Tren | Line chart multi-provinsi, YoY change, statistik ringkasan + insight per grafik |
| 🤖 Klasifikasi ML | Evaluasi model, feature importance, prediksi interaktif + interpretasi per grafik |
| 🔗 Korelasi | Scatter plot antar variabel + matriks korelasi + interpretasi per grafik |
| 📝 Interpretasi | Ringkasan eksekutif, temuan utama, insight, keterbatasan, rekomendasi & future works |
| 🗄️ Data Explorer | Filter tabel, eksplorasi data, download CSV |
 
---
 
## Tech Stack
 
| Kategori | Library |
|----------|---------|
| Ekstraksi PDF | `pdfplumber` |
| Data Processing | `pandas`, `numpy` |
| Database | `sqlite3` |
| Machine Learning | `scikit-learn`, `xgboost` |
| Visualisasi | `plotly` / Plotly.js |
| Dashboard | HTML + JavaScript (standalone, Plotly.js) |
 
---
 
## Sumber Data
 
- **BPS Statistik Kriminal** — [www.bps.go.id](https://www.bps.go.id)
- Publikasi tahunan: Statistik Kriminal 2016 s.d. 2024
- Cakupan: 34 provinsi, tahun 2015–2024
---
 
## 👤 Author
 
**Paulina Devina Wijayaa** — Data Analyst Portfolio Project
