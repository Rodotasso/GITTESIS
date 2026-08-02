# Extraccion ligera de la base de egresos (DuckDB, sin cargar en memoria)
# - conteo total y por ano
# - distribucion de frecuencias de DIAG1 (calibracion Pareto)
# - export parquet diag1 + year para el benchmark fase 3
# Salida: benchmark/

import duckdb

# Datos NO incluidos en el repo (licencias DEIS): ajustar a la ruta local
CSV = "data/EH_2010_2022_Pasantes_v2_encrip.csv"
OUT = "benchmark"

con = duckdb.connect()

base = f"""
SELECT
  DIAG1 AS diag1,
  TRY_CAST(left(FECHA_EGRESO_FMT_DEIS, 4) AS INTEGER) AS year
FROM read_csv('{CSV}', delim=';', header=true, all_varchar=true,
              null_padding=true, ignore_errors=true)
"""

print("=== total de registros ===")
print(con.execute(f"SELECT count(*) FROM ({base})").fetchall())

print("=== registros por ano ===")
for row in con.execute(
    f"SELECT year, count(*) FROM ({base}) GROUP BY year ORDER BY year"
).fetchall():
    print(row)

print("=== nulos/vacios en DIAG1 ===")
print(con.execute(
    f"SELECT count(*) FROM ({base}) WHERE diag1 IS NULL OR trim(diag1) = ''"
).fetchall())

print("=== codigos unicos DIAG1 ===")
print(con.execute(
    f"SELECT count(DISTINCT upper(trim(diag1))) FROM ({base})"
).fetchall())

print("=== top 20 codigos ===")
top = con.execute(f"""
SELECT upper(trim(diag1)) AS codigo, count(*) AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 3) AS pct,
       round(100.0 * sum(count(*)) OVER (ORDER BY count(*) DESC), 3) AS pct_acum
FROM ({base})
WHERE diag1 IS NOT NULL AND trim(diag1) <> ''
GROUP BY codigo ORDER BY n DESC LIMIT 20
""").fetchall()
for row in top:
    print(row)

print("=== concentracion: cuantos codigos cubren el 80% ===")
print(con.execute(f"""
WITH freq AS (
  SELECT upper(trim(diag1)) AS codigo, count(*) AS n
  FROM ({base})
  WHERE diag1 IS NOT NULL AND trim(diag1) <> ''
  GROUP BY codigo
),
acum AS (
  SELECT codigo, n,
         sum(n) OVER (ORDER BY n DESC) * 1.0 / sum(n) OVER () AS frac_acum
  FROM freq
)
SELECT count(*) FROM acum WHERE frac_acum <= 0.8
""").fetchall())

print("=== export parquet diag1 + year ===")
con.execute(f"""
COPY (SELECT diag1, year FROM ({base}))
TO '{OUT}/egresos-diag1-year.parquet' (FORMAT PARQUET, COMPRESSION ZSTD)
""")
print("parquet escrito")

print("=== export distribucion completa de frecuencias ===")
con.execute(f"""
COPY (
  SELECT upper(trim(diag1)) AS codigo, count(*) AS n
  FROM ({base})
  WHERE diag1 IS NOT NULL AND trim(diag1) <> ''
  GROUP BY codigo ORDER BY n DESC
) TO '{OUT}/distribucion-diag1-2010-2022.csv' (HEADER, DELIMITER ',')
""")
print("distribucion escrita")
