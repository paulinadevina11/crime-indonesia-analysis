-- Auto-generated schema

CREATE TABLE dim_province (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    provinsi TEXT    NOT NULL UNIQUE,
    pulau    TEXT,
    region   TEXT
);

CREATE TABLE dim_year (
    tahun INTEGER PRIMARY KEY
);

CREATE TABLE fact_crime (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    province_id        INTEGER NOT NULL REFERENCES dim_province(id),
    tahun              INTEGER NOT NULL REFERENCES dim_year(tahun),
    crime_total        INTEGER,
    is_outlier         INTEGER DEFAULT 0,   -- 1 = outlier, nilai crime_total = NULL
    crime_rate_per100k REAL,
    UNIQUE (province_id, tahun)
);

CREATE TABLE fact_population (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    province_id        INTEGER NOT NULL REFERENCES dim_province(id),
    tahun              INTEGER NOT NULL REFERENCES dim_year(tahun),
    population         INTEGER,
    population_density REAL,
    is_extrapolated    INTEGER DEFAULT 0,   -- 1 = dihitung dari ekstrapolasi mundur
    UNIQUE (province_id, tahun)
);

CREATE TABLE fact_unemployment (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    province_id          INTEGER NOT NULL REFERENCES dim_province(id),
    tahun                INTEGER NOT NULL REFERENCES dim_year(tahun),
    unemployment_rate    REAL,    -- rata-rata Feb + Agustus
    UNIQUE (province_id, tahun)
);

CREATE TABLE sqlite_sequence(name,seq);

CREATE VIEW v_crime_summary AS
SELECT
    p.provinsi,
    p.pulau,
    p.region,
    c.tahun,
    c.crime_total,
    c.is_outlier,
    c.crime_rate_per100k,
    pop.population,
    pop.population_density,
    pop.is_extrapolated  AS pop_extrapolated,
    u.unemployment_rate
FROM fact_crime c
JOIN dim_province p   ON p.id    = c.province_id
LEFT JOIN fact_population   pop ON pop.province_id = c.province_id AND pop.tahun = c.tahun
LEFT JOIN fact_unemployment u   ON u.province_id   = c.province_id AND u.tahun   = c.tahun;

CREATE VIEW v_top_dangerous AS
SELECT
    tahun,
    provinsi,
    crime_rate_per100k,
    crime_total,
    population,
    ROW_NUMBER() OVER (PARTITION BY tahun ORDER BY crime_rate_per100k DESC) AS ranking
FROM v_crime_summary
WHERE crime_rate_per100k IS NOT NULL
  AND is_outlier = 0;

CREATE VIEW v_trend_national AS
SELECT
    tahun,
    SUM(crime_total)                        AS total_crime_nasional,
    ROUND(AVG(crime_rate_per100k), 1)       AS avg_crime_rate,
    MAX(crime_rate_per100k)                 AS max_crime_rate,
    MIN(crime_rate_per100k)                 AS min_crime_rate,
    COUNT(DISTINCT provinsi)                AS jumlah_provinsi
FROM v_crime_summary
WHERE is_outlier = 0
  AND crime_total IS NOT NULL
GROUP BY tahun
ORDER BY tahun;

