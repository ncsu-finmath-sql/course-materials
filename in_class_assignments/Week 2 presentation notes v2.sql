-- ============================================================
-- FIM 590 | Week 2 | Filtering, sorting, aggregating
-- Table: prices (ticker, trade_date, open_price, high_price,
--                low_price, close_price, volume)
-- ============================================================


-- ------------------------------------------------------------
-- 1. Filtering rows with WHERE
-- ------------------------------------------------------------
SELECT *
FROM prices
WHERE ticker = 'ALPH'
LIMIT 10;

-- Variations on the WHERE clause (swap in one at a time):
--   WHERE ticker <> 'ALPH'
--   WHERE ticker IN ('ALPH', 'HLIO')
--   WHERE ticker NOT IN ('ALPH', 'HLIO')
--   WHERE ticker NOT LIKE 'AL%'

-- Example: combine conditions with AND / OR
SELECT *
FROM prices
WHERE ticker = 'HLIO'
  AND close_price > 100
LIMIT 10;

-- Example: pattern match with LIKE (tickers ending in 'O')
SELECT DISTINCT ticker
FROM prices
WHERE ticker LIKE '%O';


-- ------------------------------------------------------------
-- 2. BETWEEN (inclusive on both ends)
-- ------------------------------------------------------------
SELECT *
FROM prices
WHERE trade_date BETWEEN '2025-03-01' AND '2025-03-31';

-- Example: numeric range
SELECT ticker, trade_date, close_price
FROM prices
WHERE close_price BETWEEN 90 AND 110
ORDER BY close_price
LIMIT 10;

-- Example: NOT BETWEEN, and combined with another filter
SELECT ticker, trade_date, volume
FROM prices
WHERE ticker = 'ALPH'
  AND volume NOT BETWEEN 3000000 AND 8000000;

-- BETWEEN a AND b is the same as >= a AND <= b:
--   WHERE close_price >= 90 AND close_price <= 110


-- ------------------------------------------------------------
-- 3. DISTINCT
-- ------------------------------------------------------------
SELECT DISTINCT ticker
FROM prices;

-- Example: DISTINCT on a combination of columns (one row per ticker-month)
SELECT DISTINCT ticker, MONTH(trade_date) AS month
FROM prices
ORDER BY ticker, month;

-- Example: DISTINCT vs COUNT(DISTINCT) -- list the values, or count them
SELECT DISTINCT trade_date
FROM prices
ORDER BY trade_date
LIMIT 5;


-- ------------------------------------------------------------
-- 4. Sorting with ORDER BY
-- ------------------------------------------------------------
SELECT *
FROM prices
ORDER BY trade_date DESC;

-- Variations (swap in one at a time):
--   ORDER BY trade_date ASC            -- ASC is the default
--   ORDER BY ticker, trade_date        -- by ticker, then date within ticker
--   ORDER BY trade_date, ticker        -- by date, then ticker within date
-- Show: DESC vs ASC, and how column order changes the result.

SELECT *
FROM prices
WHERE ticker = 'ALPH'
ORDER BY trade_date;

-- Example: the 10 highest-volume days
SELECT ticker, trade_date, volume
FROM prices
ORDER BY volume DESC
LIMIT 10;

-- Example: mixed directions (ticker A-Z, newest date first)
SELECT ticker, trade_date, close_price
FROM prices
ORDER BY ticker ASC, trade_date DESC;


-- ------------------------------------------------------------
-- 5. LIMIT and OFFSET
-- ------------------------------------------------------------
-- LIMIT n caps the rows returned. Without ORDER BY, which n rows you
-- get is not guaranteed, so pair them.
SELECT ticker, trade_date, close_price
FROM prices
ORDER BY close_price DESC
LIMIT 5;

-- OFFSET skips rows first: this is "rows 6-10" (page 2 of 5 per page)
SELECT ticker, trade_date, close_price
FROM prices
ORDER BY close_price DESC
LIMIT 5 OFFSET 5;

-- Example: the single most recent row for one ticker
SELECT *
FROM prices
WHERE ticker = 'ALPH'
ORDER BY trade_date DESC
LIMIT 1;

-- Example: the 5 lowest-volume days for one ticker
SELECT ticker, trade_date, volume
FROM prices
WHERE ticker = 'HLIO'
ORDER BY volume ASC
LIMIT 5;


-- ------------------------------------------------------------
-- 6. Aggregate functions
-- ------------------------------------------------------------
SELECT COUNT(ticker) FROM prices;
SELECT SUM(volume)   FROM prices;
SELECT AVG(volume)   FROM prices;
SELECT MIN(volume)   FROM prices;
SELECT MAX(volume)   FROM prices;

SELECT MIN(trade_date), MAX(trade_date)
FROM prices;

-- COUNT(*) vs COUNT(col) vs COUNT(DISTINCT col)
SELECT COUNT(*)                     AS n_rows,     -- 984
       COUNT(close_price)           AS n_closes,   -- 984 (no NULLs, so same as COUNT(*))
       COUNT(DISTINCT ticker)       AS n_tickers,  -- 8
       COUNT(DISTINCT trade_date)   AS n_days      -- 123
FROM prices;

-- Aggregates and WHERE: filter first, then summarize.

-- Example: several aggregates for one ticker
SELECT COUNT(*)         AS n_days,
       AVG(close_price) AS avg_close,
       MIN(close_price) AS low_close,
       MAX(close_price) AS high_close
FROM prices
WHERE ticker = 'ALPH';

-- Example: aggregate over a date window
SELECT SUM(volume) AS q1_volume
FROM prices
WHERE trade_date BETWEEN '2025-01-01' AND '2025-03-31';


-- ------------------------------------------------------------
-- 7. ROUND
-- ------------------------------------------------------------
-- Raw aggregates carry many decimals; ROUND(x, n) keeps n places.
SELECT ticker,
       AVG(close_price)           AS avg_raw,
       ROUND(AVG(close_price), 2) AS avg_close
FROM prices
GROUP BY ticker;

-- Example: round a return to a percent with 2 decimals
SELECT ticker,
       ROUND(100 * (MAX(close_price) / MIN(close_price) - 1), 2) AS pct_range
FROM prices
GROUP BY ticker
ORDER BY pct_range DESC;

-- Example: negative digits round to the left of the decimal point
SELECT ticker,
       ROUND(AVG(volume), -3) AS avg_volume_thousands
FROM prices
GROUP BY ticker;

-- Round only for display; don't round before further math,
-- or the rounding error compounds.


-- ------------------------------------------------------------
-- 8. Data types and CAST
-- ------------------------------------------------------------
-- Every column has a type. DESCRIBE shows them; typeof() shows one value's.
DESCRIBE prices;

SELECT typeof(ticker)      AS ticker_type,       -- VARCHAR (string)
       typeof(trade_date)  AS date_type,         -- DATE
       typeof(close_price) AS close_type,        -- DOUBLE (decimal)
       typeof(volume)      AS volume_type        -- BIGINT (integer)
FROM prices
LIMIT 1;

-- CAST(x AS type) converts between types. x::type is shorthand.
-- Integer -> string:
SELECT ticker,
       volume,
       CAST(volume AS VARCHAR) AS volume_text,
       volume::VARCHAR         AS volume_text_short
FROM prices
LIMIT 5;

-- Why it matters: text sorts alphabetically, numbers sort numerically.
-- As text, '9...' comes after '37...' because '9' > '3'.
SELECT volume,
       CAST(volume AS VARCHAR) AS volume_text
FROM prices
ORDER BY volume_text DESC
LIMIT 5;

-- Strings are joined with ||; non-text values must be cast first
-- (DuckDB casts implicitly, but be explicit so the intent is clear).
SELECT ticker || ' closed at ' || CAST(close_price AS VARCHAR) AS message
FROM prices
LIMIT 5;

-- String -> number. Useful for CSV data that loads as text.
SELECT CAST('250' AS INTEGER) + 1       AS int_plus_one,    -- 251
       CAST('3.14' AS DOUBLE) * 2       AS decimal_times_2; -- 6.28

-- CAST errors on bad input; TRY_CAST returns NULL instead.
SELECT TRY_CAST('abc' AS INTEGER)  AS bad_value,    -- NULL
       TRY_CAST('42'  AS INTEGER)  AS good_value;   -- 42

-- Decimal -> integer: DuckDB rounds to nearest, it does not truncate.
SELECT close_price,
       CAST(close_price AS INTEGER) AS close_int
FROM prices
LIMIT 5;

-- Date <-> string.
SELECT CAST(trade_date AS VARCHAR)           AS date_text,     -- '2025-01-02'
       strftime(trade_date, '%b %d, %Y')     AS date_pretty,   -- 'Jan 02, 2025'
       CAST('2025-03-01' AS DATE)            AS text_to_date
FROM prices
LIMIT 3;

-- Integer division: 7 / 2 is 3.5 in DuckDB (// gives 3), but many
-- databases (SQL Server, SQLite, Postgres) return 3 for integer / integer.
-- Cast one side to a decimal when you need a decimal result everywhere.
SELECT 7 / 2                    AS duckdb_divide,   -- 3.5
       7 // 2                   AS int_divide,      -- 3
       CAST(7 AS DOUBLE) / 2    AS safe_divide;     -- 3.5

-- Example: volume in millions
SELECT ticker, trade_date,
       ROUND(volume / 1000000.0, 2) AS volume_millions
FROM prices
LIMIT 5;


-- ------------------------------------------------------------
-- 9. Date functions
-- ------------------------------------------------------------
SELECT *,
       DAYOFWEEK(trade_date) AS day_of_week,
       MONTH(trade_date)     AS month,
       YEAR(trade_date)      AS year
FROM prices
WHERE ticker = 'ALPH'
  AND trade_date BETWEEN '2025-06-01' AND '2025-06-05';

-- Example: filter on a date part (all of May)
SELECT ticker, trade_date, close_price
FROM prices
WHERE MONTH(trade_date) = 5
  AND ticker = 'ALPH';

-- Example: day name, and keep only Mondays
SELECT ticker, trade_date, DAYNAME(trade_date) AS weekday, close_price
FROM prices
WHERE DAYNAME(trade_date) = 'Monday'
  AND ticker = 'ALPH';


-- ------------------------------------------------------------
-- 10. CASE WHEN (if / else inside a query)
-- ------------------------------------------------------------
-- Conditions are checked top to bottom; the first match wins.
-- No ELSE means unmatched rows get NULL.
SELECT ticker, trade_date, open_price, close_price,
       CASE WHEN close_price > open_price THEN 'Up'
            WHEN close_price < open_price THEN 'Down'
            ELSE 'Flat'
       END AS direction
FROM prices
WHERE ticker = 'ALPH'
LIMIT 10;

-- Example: bucket volume into labels
SELECT ticker, trade_date, volume,
       CASE WHEN volume >= 10000000 THEN 'High'
            WHEN volume >= 5000000  THEN 'Medium'
            ELSE 'Low'
       END AS volume_bucket
FROM prices
WHERE ticker = 'ALPH'
LIMIT 10;

-- Example: CASE inside an aggregate -- count up days and down days per ticker
SELECT ticker,
       SUM(CASE WHEN close_price > open_price THEN 1 ELSE 0 END) AS up_days,
       SUM(CASE WHEN close_price < open_price THEN 1 ELSE 0 END) AS down_days,
       COUNT(*)                                                  AS total_days
FROM prices
GROUP BY ticker
ORDER BY up_days DESC;

-- Example: GROUP BY a CASE label
SELECT CASE WHEN volume >= 10000000 THEN 'High'
            WHEN volume >= 5000000  THEN 'Medium'
            ELSE 'Low'
       END AS volume_bucket,
       COUNT(*) AS n_days
FROM prices
GROUP BY volume_bucket
ORDER BY n_days DESC;


-- ------------------------------------------------------------
-- 11. GROUP BY
-- ------------------------------------------------------------
SELECT ticker,
       MIN(close_price) AS min_price,
       MAX(close_price) AS max_price
FROM prices
GROUP BY ticker;

-- What is the range, as a percent of the low?
SELECT ticker,
       MAX(close_price) / MIN(close_price) - 1 AS pct_range
FROM prices
GROUP BY ticker
ORDER BY pct_range DESC;

-- What is the range by month? (one ticker)
SELECT ticker,
       MONTH(trade_date)  AS month,
       YEAR(trade_date)   AS year,
       MIN(close_price)   AS min_price,
       MAX(close_price)   AS max_price,
       AVG(close_price)   AS avg_price
FROM prices
WHERE ticker = 'ALPH'
GROUP BY ticker, MONTH(trade_date), YEAR(trade_date);

-- What is the range between the monthly low and high close_price, for each ticker?
SELECT ticker,
       MONTH(trade_date)                       AS month,
       YEAR(trade_date)                        AS year,
       MAX(close_price) / MIN(close_price) - 1 AS pct_range
FROM prices
GROUP BY ticker, MONTH(trade_date), YEAR(trade_date)
ORDER BY pct_range;

-- Example: trading days and average volume per ticker
SELECT ticker,
       COUNT(*)    AS n_days,
       AVG(volume) AS avg_volume
FROM prices
GROUP BY ticker
ORDER BY avg_volume DESC;

-- Example: total volume by day of week
SELECT DAYNAME(trade_date) AS weekday,
       SUM(volume)         AS total_volume
FROM prices
GROUP BY DAYNAME(trade_date)
ORDER BY total_volume DESC;


-- ------------------------------------------------------------
-- 12. HAVING vs WHERE
-- ------------------------------------------------------------
SELECT ticker,
       COUNT(*) AS n_high_days
FROM prices
WHERE volume > 5000000      -- row filter: which days count
GROUP BY ticker
HAVING COUNT(*) >= 76;      -- group filter: which tickers qualify

-- Example: tickers whose average volume exceeds 5 million
SELECT ticker,
       AVG(volume) AS avg_volume
FROM prices
GROUP BY ticker
HAVING AVG(volume) > 5000000;

-- Example: WHERE and HAVING together (ticker-months with a wide range in H1)
SELECT ticker,
       MONTH(trade_date)                       AS month,
       MAX(close_price) / MIN(close_price) - 1 AS pct_range
FROM prices
WHERE trade_date BETWEEN '2025-01-01' AND '2025-06-30'   -- row filter
GROUP BY ticker, MONTH(trade_date)
HAVING MAX(close_price) / MIN(close_price) - 1 > 0.10    -- group filter
ORDER BY pct_range DESC;
