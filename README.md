# **Indonesia Crime Analysis**

A complete pipeline from PDF data extraction → SQL database → Machine Learning → interactive HTML dashboard to analyze and predict crime levels across 34 provinces in Indonesia.

---

## About the Project

This project builds an end-to-end data pipeline using official data from BPS (Statistics Indonesia), drawn from the *Crime Statistics* (Statistik Kriminal) publications for 2015–2024. The goal is to classify the **danger level** of each province and predict crime rates using Machine Learning models.

**Highlights:**
- Automated extraction from BPS PDFs with `pdfplumber`
- SQLite database with a star schema + SQL views
- 3 classification models (Logistic Regression, Random Forest, XGBoost)
- 2 regression models (Linear Regression, Ridge Regression)
- Interactive 7-page standalone HTML dashboard + Plotly.js (no server required)
- Bilingual interface (Indonesian / English toggle)

---

## Project Structure

```
crime-indonesia-analysis/
│
├── data/
│   ├── raw/                        ← Raw PDFs & CSVs from BPS
│   │   ├── BPS-statistik-kriminal-*.pdf
│   │   ├── Population...Province, *.csv
│   │   ├── Tingkat Pengangguran...*.csv
│   │   └── gadm41_IDN_1.json.zip   ← Indonesia province boundaries (GeoJSON)
│   ├── extracted/                  ← Extraction output
│   │   ├── crime_raw.csv
│   │   ├── population_raw.csv
│   │   └── unemployment_raw.csv
│   ├── cleaned/                    ← Cleaned & merged data
│   │   ├── crime_merged.csv
│   │   ├── crime_cleaned.csv
│   │   ├── population_cleaned.csv
│   │   └── unemployment_cleaned.csv
│   └── features/                   ← ML-ready datasets
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
│   └── schema.sql                  ← DDL documentation
│
├── models/
│   ├── clf_logistic.pkl
│   ├── clf_random_forest.pkl
│   ├── clf_xgboost.pkl
│   ├── reg_linear.pkl
│   └── reg_ridge.pkl
│
├── notebooks/
│   ├── 01_extract_pdf.ipynb        ← PDF & CSV extraction
│   ├── 02_cleaning.ipynb           ← Cleaning, validation, merge
│   ├── 03_load_sql_db.ipynb        ← Build SQLite database
│   ├── 04_preprocessing.ipynb      ← Preprocessing for ML
│   ├── 05_feature_engineering.ipynb ← Feature engineering
│   └── 06_modelling.ipynb          ← Model training & evaluation
│
├── dashboard/
│   ├── dashboard.html              ← Interactive HTML dashboard (main file)
│   ├── 07_dashboard.ipynb          ← Notebook that generates the dashboard
│   └── requirements.txt            ← Dependencies for the generator
│
└── README.md
```

---

## How to Run

### 1. Clone & Setup

```bash
git clone https://github.com/paulinadevina11/crime-indonesia-analysis.git
cd crime-indonesia-analysis
pip install pandas numpy scikit-learn xgboost pdfplumber plotly
```

### 2. Prepare Raw Data

Place the BPS PDF and CSV files in `data/raw/` (already included in the repo).

### 3. Run the Pipeline (via Notebooks)

Open and run the notebooks in order inside `notebooks/`:

```
01_extract_pdf.ipynb        → PDF & CSV extraction
02_cleaning.ipynb           → Cleaning & merge
03_load_sql_db.ipynb        → Build SQLite database
04_preprocessing.ipynb      → ML preprocessing
05_feature_engineering.ipynb → Feature engineering
06_modelling.ipynb          → Model training & evaluation
```

### 4. Open the Dashboard

The dashboard is a standalone HTML file — just open it directly in a browser, no server needed:

```bash
open dashboard/dashboard.html      # macOS
# or double-click the file dashboard/dashboard.html
```

---

## Pipeline Flow

```
BPS PDFs (2015–2024)
       ↓
01_extract_pdf.ipynb  →  crime_raw.csv, population_raw.csv, unemployment_raw.csv
       ↓
02_cleaning.ipynb     →  crime_merged.csv  (331 rows × 34 provinces × 10 years)
       ↓
03_load_sql_db.ipynb  →  crime_indonesia.db  (star schema + 3 SQL views)
       ↓
04_preprocessing.ipynb →  ml_dataset.csv  (imputation, encoding, StandardScaler)
       ↓
05_feature_engineering.ipynb → features_final.csv  (lag, MA, YoY, danger level)
       ↓
06_modelling.ipynb    →  5 .pkl models + classification/regression reports
       ↓
dashboard/dashboard.html  →  Interactive HTML dashboard (7 pages)
```

---

## Machine Learning

### Features

| Feature | Description |
|---------|-------------|
| `crime_rate_lag1` | Crime rate of the previous year (t-1) |
| `crime_rate_lag2` | Crime rate two years prior (t-2) |
| `crime_rate_ma3` | 3-year moving average |
| `crime_rate_yoy_change` | Year-over-year % change |
| `trend_direction_enc` | Trend direction: Up(1) / Stable(0) / Down(-1) |
| `population_density` | Population density (people/km²) |
| `unemployment_rate` | Unemployment rate (%) |
| `unemp_x_density` | Interaction: unemployment × density |
| `crime_per_density` | Crime rate relative to density |

### Classification Target: Danger Level

| Label | Threshold (crime rate / 100K) |
|-------|-------------------------------|
| Low (Rendah) | < 100 |
| Medium (Sedang) | 100 – 200 |
| High (Tinggi) | 200 – 350 |
| Dangerous (Berbahaya) | ≥ 350 |

### Data Split

- **Train**: 2015–2021 (time-based, not random)
- **Test**: 2022–2024

### Model Results

| Model | Accuracy | F1-Macro | ROC-AUC |
|-------|----------|----------|---------|
| Logistic Regression | ~0.67 | ~0.60 | ~0.75 |
| Random Forest | ~0.59 | ~0.49 | ~0.90 |
| XGBoost | ~0.61 | ~0.54 | ~0.83 |

| Model | RMSE | R² |
|-------|------|-----|
| Linear Regression | ~45 | ~0.74 |
| Ridge Regression | ~43 | ~0.76 |

> Note: the "Dangerous" class is the hardest to predict because it has the fewest samples (class imbalance).

---

## Database Schema

```sql
dim_province  (id, provinsi, pulau, region)
dim_year      (id, tahun)
fact_crime    (province_id, tahun, crime_total, is_outlier, crime_rate_per100k)
fact_population (province_id, tahun, population, population_density, is_extrapolated)
fact_unemployment (province_id, tahun, unemployment_rate)

-- Views
v_crime_summary    -- joins all facts per province per year
v_top_dangerous    -- ranking of most dangerous provinces per year
v_trend_national   -- national average crime rate per year
```

---

## Dashboard — 7 Pages

| Page | Content |
|------|---------|
| 🏠 Home | KPI cards, top 10 dangerous provinces, danger level distribution, national trend |
| 🗺️ Map | Interactive bubble map per province, colored by danger level |
| 📈 Trends | Multi-province line chart, YoY change, summary statistics + per-chart insights |
| 🤖 ML Classification | Model evaluation, feature importance, interactive prediction + per-chart interpretation |
| 🔗 Correlation | Scatter plots between variables + correlation matrix + per-chart interpretation |
| 📝 Interpretation | Executive summary, key findings, insights, limitations, recommendations & future work |
| 🗄️ Data Explorer | Filterable table, data exploration, CSV download |

The interface includes an **Indonesian / English language toggle**.

---

## Tech Stack

| Category | Library |
|----------|---------|
| PDF extraction | `pdfplumber` |
| Data processing | `pandas`, `numpy` |
| Database | `sqlite3` |
| Machine Learning | `scikit-learn`, `xgboost` |
| Visualization | `plotly` / Plotly.js |
| Dashboard | HTML + JavaScript (standalone, Plotly.js) |

---

## Data Source

- **BPS Crime Statistics (Statistik Kriminal)** — [www.bps.go.id](https://www.bps.go.id)
- Annual publications: Statistik Kriminal 2016 through 2024
- Coverage: 34 provinces, years 2015–2024
- All figures reflect *recorded* crime (reported to and registered by the police), not total actual incidents.

---

## 👤 Author

**Paulina Devina Wijaya** — Data Analyst Portfolio Project
