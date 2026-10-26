# Week 2 In-Class Questions with Answers: Aggregations and GROUP BY

**Course:** FIM 590, Data Analytics with SQL
**Data:** the `prices` table (8 fictional tickers, 123 trading days each, 984 rows)

| Column | Meaning |
|---|---|
| `ticker` | Fictional stock symbol (ALPH, BRVO, CRST, DLTA, ECHO, FNCH, GRNT, HLIO) |
| `trade_date` | Trading day, 2025-01-02 to 2025-06-30 |
| `open_price`, `high_price`, `low_price`, `close_price` | Daily prices |
| `volume` | Shares traded |

The questions build on each other: later ones reuse earlier ones, so keep your queries. Work in order, run each query, and check the row count before moving on.

*Every result below was produced by running the query on the course data. Where a result is long, only the first rows are shown.*


---

## Easy (questions 1-5)

Warm-up: `SELECT`, `WHERE`, `ORDER BY`, `LIMIT` and the basic aggregates.

### Question 1: First rows for one ticker

Show every column for the first 10 trading days of **ALPH** (earliest dates first).

**Answer**

```sql
SELECT *
FROM prices
WHERE ticker = 'ALPH'
ORDER BY trade_date
LIMIT 10;
```

| ticker | trade_date | open_price | high_price | low_price | close_price | volume |
|---|---|---|---|---|---|---|
| ALPH | 2025-01-02 | 112.16 | 113.11 | 112.1 | 112.29 | 5,209,099 |
| ALPH | 2025-01-03 | 112.96 | 117.07 | 112.85 | 115.86 | 4,701,058 |
| ALPH | 2025-01-06 | 116.71 | 117.6 | 116.32 | 117.47 | 2,163,371 |
| ALPH | 2025-01-07 | 117.29 | 118.18 | 115.98 | 117.05 | 6,408,218 |
| ALPH | 2025-01-08 | 117.99 | 118.91 | 116.53 | 118.72 | 2,325,522 |
| ALPH | 2025-01-09 | 118.64 | 121.93 | 118.47 | 120.13 | 3,890,371 |
| ALPH | 2025-01-10 | 119.5 | 120.14 | 118.58 | 119.75 | 2,655,944 |
| ALPH | 2025-01-13 | 120.2 | 121.26 | 119.33 | 119.49 | 2,409,252 |
| ALPH | 2025-01-14 | 119.55 | 122.48 | 119.15 | 121.38 | 3,100,363 |
| ALPH | 2025-01-15 | 121.36 | 122.52 | 120.65 | 122.47 | 7,258,467 |

> **Teaching note:** Without `ORDER BY`, `LIMIT` returns whichever 10 rows the engine finds first, so the order is not guaranteed.

### Question 2: Two tickers, two sort keys

Show `ticker`, `trade_date` and `close_price` for **ALPH and HLIO** only. Sort by `trade_date` (earliest first), then by `ticker`. Keep only the first 6 rows.

**Answer**

```sql
SELECT ticker, trade_date, close_price
FROM prices
WHERE ticker IN ('ALPH', 'HLIO')
ORDER BY trade_date ASC, ticker ASC
LIMIT 6;
```

| ticker | trade_date | close_price |
|---|---|---|
| ALPH | 2025-01-02 | 112.29 |
| HLIO | 2025-01-02 | 303.58 |
| ALPH | 2025-01-03 | 115.86 |
| HLIO | 2025-01-03 | 303.9 |
| ALPH | 2025-01-06 | 117.47 |
| HLIO | 2025-01-06 | 305.6 |

> **Teaching note:** Each date appears twice (once per ticker), so the second sort key decides the order within a date.

### Question 3: Counting rows

(a) How many rows are in `prices`? Name the column `n_rows`.
(b) How many rows belong to tickers **other than** ALPH and HLIO? Name the column `n_rows`.

**Answer (a)**

```sql
SELECT COUNT(*) AS n_rows
FROM prices;
```

| n_rows |
|---|
| 984 |

**Answer (b)**

```sql
SELECT COUNT(*) AS n_rows
FROM prices
WHERE ticker NOT IN ('ALPH', 'HLIO');
```

| n_rows |
|---|
| 738 |

> **Teaching note:** `NOT LIKE 'AL%'` also gives 861 here, but it excludes every ticker starting with AL. `NOT IN` says exactly what you mean.

### Question 4: Counting distinct values

In one query, report the number of different tickers (`n_tickers`) and the number of different trading days (`n_days`).

**Answer**

```sql
SELECT COUNT(DISTINCT ticker)     AS n_tickers,
       COUNT(DISTINCT trade_date) AS n_days
FROM prices;
```

| n_tickers | n_days |
|---|---|
| 8 | 123 |

> **Teaching note:** 8 tickers x 123 days = 984 rows, which matches question 3(a). Keep that cross-check in mind for question 19.

### Question 5: Summary of the whole table

In one query, show the first date (`first_day`), the last date (`last_day`), the smallest volume (`min_volume`), the largest volume (`max_volume`) and the average volume rounded to a whole number (`avg_volume`).

**Answer**

```sql
SELECT MIN(trade_date)       AS first_day,
       MAX(trade_date)       AS last_day,
       MIN(volume)           AS min_volume,
       MAX(volume)           AS max_volume,
       ROUND(AVG(volume))    AS avg_volume
FROM prices;
```

| first_day | last_day | min_volume | max_volume | avg_volume |
|---|---|---|---|---|
| 2025-01-02 | 2025-06-30 | 646,560 | 37,754,767 | 6,359,131 |

> **Teaching note:** Five aggregates, no `GROUP BY`: the whole table collapses into one row.


---

## Medium (questions 6-15)

`GROUP BY`, date functions, monthly statistics, `HAVING` vs `WHERE`.

### Question 6: Filter first, then summarize

For **ALPH** in **June 2025**, report the number of trading days (`n_days`), the lowest close (`lowest_close`) and the highest close (`highest_close`).

**Answer**

```sql
SELECT COUNT(*)         AS n_days,
       MIN(close_price)  AS lowest_close,
       MAX(close_price)  AS highest_close
FROM prices
WHERE ticker = 'ALPH'
  AND trade_date BETWEEN '2025-06-01' AND '2025-06-30';
```

| n_days | lowest_close | highest_close |
|---|---|---|
| 20 | 107.61 | 115.05 |

> **Teaching note:** `WHERE` runs before the aggregates, so only June rows are counted. `BETWEEN` includes both end dates.

### Question 7: Your first GROUP BY

For **every** ticker, show `ticker`, `min_close` and `max_close` across all days. Sort by `ticker`.

**Answer**

```sql
SELECT ticker,
       MIN(close_price) AS min_close,
       MAX(close_price) AS max_close
FROM prices
GROUP BY ticker
ORDER BY ticker;
```

| ticker | min_close | max_close |
|---|---|---|
| ALPH | 107.61 | 127 |
| BRVO | 43.3 | 59.48 |
| CRST | 216.96 | 268.05 |
| DLTA | 9.28 | 20.97 |
| ECHO | 78.53 | 93.91 |
| FNCH | 146.87 | 171.97 |
| GRNT | 49.67 | 73.85 |
| HLIO | 299.19 | 521.95 |

> **Teaching note:** Question 6 gave one row for one ticker and month. `GROUP BY ticker` repeats it for every ticker.

### Question 8: Total and average volume

For every ticker, show `ticker`, `total_volume` (sum of volume) and `avg_volume` (average volume, rounded to a whole number). Put the ticker with the most total volume first.

**Answer**

```sql
SELECT ticker,
       SUM(volume)           AS total_volume,
       ROUND(AVG(volume))    AS avg_volume
FROM prices
GROUP BY ticker
ORDER BY total_volume DESC;
```

| ticker | total_volume | avg_volume |
|---|---|---|
| DLTA | 1,851,255,100 | 15,050,854 |
| BRVO | 1,224,381,081 | 9,954,318 |
| GRNT | 950,347,951 | 7,726,406 |
| ECHO | 746,040,776 | 6,065,372 |
| ALPH | 553,928,990 | 4,503,488 |
| FNCH | 430,386,267 | 3,499,075 |
| CRST | 270,781,264 | 2,201,474 |
| HLIO | 230,263,962 | 1,872,065 |

> **Teaching note:** All tickers have 123 rows, so the ranking by total and by average is the same.

### Question 9: Price range as a percentage

Using your question 7 idea, show each ticker's overall range as a percentage of its lowest close: `max_close / min_close - 1`, rounded to 4 decimals and named `pct_range`. Largest range first.

**Answer**

```sql
SELECT ticker,
       ROUND(MAX(close_price) / MIN(close_price) - 1, 4) AS pct_range
FROM prices
GROUP BY ticker
ORDER BY pct_range DESC;
```

| ticker | pct_range |
|---|---|
| DLTA | 1.2597 |
| HLIO | 0.7445 |
| GRNT | 0.4868 |
| BRVO | 0.3737 |
| CRST | 0.2355 |
| ECHO | 0.1958 |
| ALPH | 0.1802 |
| FNCH | 0.1709 |

> **Teaching note:** `MIN / MAX` is a ratio below 1, not a range. `MAX / MIN - 1` is the percent move from the low to the high.

### Question 10: Date functions

For **ALPH**, from 2025-06-01 to 2025-06-05, show `trade_date` plus its day of the week (`dow`), month (`month_no`) and year (`year_no`).

**Answer**

```sql
SELECT trade_date,
       DAYOFWEEK(trade_date) AS dow,
       MONTH(trade_date)     AS month_no,
       YEAR(trade_date)      AS year_no
FROM prices
WHERE ticker = 'ALPH'
  AND trade_date BETWEEN '2025-06-01' AND '2025-06-05'
ORDER BY trade_date;
```

| trade_date | dow | month_no | year_no |
|---|---|---|---|
| 2025-06-02 | 1 | 6 | 2025 |
| 2025-06-03 | 2 | 6 | 2025 |
| 2025-06-04 | 3 | 6 | 2025 |
| 2025-06-05 | 4 | 6 | 2025 |

> **Teaching note:** In DuckDB, `DAYOFWEEK` runs 0 (Sunday) to 6 (Saturday). June 2, 2025 was a Monday, so it shows 1. June 1 was a Sunday, so it has no row: the table holds trading days only.

### Question 11: Group by a date part

Group all rows by day of the week. Show `dow`, the number of rows (`n_rows`) and the average volume rounded to a whole number (`avg_volume`). Sort by `dow`.

**Answer**

```sql
SELECT DAYOFWEEK(trade_date) AS dow,
       COUNT(*)              AS n_rows,
       ROUND(AVG(volume))    AS avg_volume
FROM prices
GROUP BY DAYOFWEEK(trade_date)
ORDER BY dow;
```

| dow | n_rows | avg_volume |
|---|---|---|
| 1 | 184 | 6,301,072 |
| 2 | 200 | 6,195,222 |
| 3 | 200 | 6,267,752 |
| 4 | 200 | 6,417,931 |
| 5 | 200 | 6,609,036 |

> **Teaching note:** No row has `dow` 0 or 6, because markets are closed on weekends. Monday has 184 rows instead of 200 because of market holidays (Jan 20, Feb 17, May 26): a quick validation of the calendar.

### Question 12: Monthly statistics for one ticker

For **ALPH**, show one row per month: `year_no`, `month_no`, `min_price`, `max_price` and `avg_price` (rounded to 2 decimals) of the close price. Sort chronologically.

**Answer**

```sql
SELECT YEAR(trade_date)           AS year_no,
       MONTH(trade_date)          AS month_no,
       MIN(close_price)           AS min_price,
       MAX(close_price)           AS max_price,
       ROUND(AVG(close_price), 2) AS avg_price
FROM prices
WHERE ticker = 'ALPH'
GROUP BY YEAR(trade_date), MONTH(trade_date)
ORDER BY year_no, month_no;
```

| year_no | month_no | min_price | max_price | avg_price |
|---|---|---|---|---|
| 2025 | 1 | 112.29 | 127 | 120.62 |
| 2025 | 2 | 115.71 | 124.99 | 121.54 |
| 2025 | 3 | 114.01 | 121.37 | 117.73 |
| 2025 | 4 | 112.68 | 124.36 | 118.9 |
| 2025 | 5 | 109.35 | 117.14 | 113.23 |
| 2025 | 6 | 107.61 | 115.05 | 111.41 |

> **Teaching note:** `GROUP BY` does not sort. Without the `ORDER BY`, the months can come back in any order.

### Question 13: Monthly range for every ticker

Extend question 12 to **all tickers**. For each ticker and month, compute `pct_change = max_close / min_close - 1` (rounded to 4 decimals). Show `ticker`, `year_no`, `month_no`, `pct_change` for the **5 largest** values.

**Answer**

```sql
SELECT ticker,
       YEAR(trade_date)  AS year_no,
       MONTH(trade_date) AS month_no,
       ROUND(MAX(close_price) / MIN(close_price) - 1, 4) AS pct_change
FROM prices
GROUP BY ticker, YEAR(trade_date), MONTH(trade_date)
ORDER BY pct_change DESC
LIMIT 5;
```

| ticker | year_no | month_no | pct_change |
|---|---|---|---|
| DLTA | 2025 | 5 | 0.3181 |
| HLIO | 2025 | 2 | 0.3089 |
| GRNT | 2025 | 3 | 0.2829 |
| GRNT | 2025 | 4 | 0.2504 |
| DLTA | 2025 | 2 | 0.2297 |

> **Teaching note:** Grouping by three columns gives one row per ticker per month: 8 x 6 = 48 groups, then `LIMIT` keeps 5.

### Question 14: WHERE vs HAVING

Count the days each ticker traded **more than 5,000,000 shares** (`n_high_days`). Keep only tickers with **at least 76** such days. Sort by `n_high_days` descending.

**Answer**

```sql
SELECT ticker, COUNT(*) AS n_high_days
FROM prices
WHERE volume > 5000000        -- row filter: which days count
GROUP BY ticker
HAVING COUNT(*) >= 76         -- group filter: which tickers qualify
ORDER BY n_high_days DESC;
```

| ticker | n_high_days |
|---|---|
| DLTA | 123 |
| BRVO | 119 |
| GRNT | 106 |
| ECHO | 76 |

> **Teaching note:** ECHO has exactly 76, so `>=` keeps it and `>` would drop it. `WHERE` cannot use `COUNT(*)`, because it runs before the groups exist.

### Question 15: WHERE and HAVING together

Look only at days with volume above 5,000,000. For each ticker, compute the average volume on those days (`avg_high_volume`, rounded to a whole number) and the number of those days (`n_high_days`). Keep tickers whose `avg_high_volume` is **above 8,000,000**. Highest average first.

**Answer**

```sql
SELECT ticker,
       ROUND(AVG(volume)) AS avg_high_volume,
       COUNT(*)           AS n_high_days
FROM prices
WHERE volume > 5000000
GROUP BY ticker
HAVING AVG(volume) > 8000000
ORDER BY avg_high_volume DESC;
```

| ticker | avg_high_volume | n_high_days |
|---|---|---|
| DLTA | 15,050,854 | 123 |
| BRVO | 10,132,762 | 119 |
| GRNT | 8,248,109 | 106 |

> **Teaching note:** Compare ECHO here (7.3M, dropped) with its all-days average of 6.1M. The `WHERE` filter changes every average, which is why the order of `WHERE` and `GROUP BY` matters.


---

## Hard (questions 16-20)

Scenarios that combine everything, including a validation habit. All of them use only Week 2 material.

### Question 16: Volatile months only

**Scenario:** A risk manager only wants to see unusually volatile months. Using the monthly `pct_change` from question 13 (`max_close / min_close - 1`), list every ticker-month where it is **above 0.20**. Show `ticker`, `month_no`, `pct_change` (rounded to 4 decimals) and the number of trading days in the group (`n_days`). Largest first.

**Answer**

```sql
SELECT ticker,
       MONTH(trade_date) AS month_no,
       ROUND(MAX(close_price) / MIN(close_price) - 1, 4) AS pct_change,
       COUNT(*)          AS n_days
FROM prices
GROUP BY ticker, MONTH(trade_date)
HAVING MAX(close_price) / MIN(close_price) - 1 > 0.20
ORDER BY pct_change DESC;
```

| ticker | month_no | pct_change | n_days |
|---|---|---|---|
| DLTA | 5 | 0.3181 | 21 |
| HLIO | 2 | 0.3089 | 19 |
| GRNT | 3 | 0.2829 | 21 |
| GRNT | 4 | 0.2504 | 21 |
| DLTA | 2 | 0.2297 | 19 |

> **Teaching note:** `HAVING` can use any aggregate expression, not only the ones in `SELECT`. All data is in 2025, so grouping by month alone is the same as year and month.

### Question 17: Watch list: the most volatile months

**Scenario:** The risk committee follows three tickers: **DLTA, HLIO and GRNT**. Find their **3 most volatile ticker-months**. For each, show `ticker`, `month_no`, `pct_change` (`max_close / min_close - 1`, rounded to 4 decimals), `avg_volume` (rounded to a whole number) and `n_days`. Most volatile first.

**Answer**

```sql
SELECT ticker,
       MONTH(trade_date)                                 AS month_no,
       ROUND(MAX(close_price) / MIN(close_price) - 1, 4) AS pct_change,
       ROUND(AVG(volume))                                AS avg_volume,
       COUNT(*)                                          AS n_days
FROM prices
WHERE ticker IN ('DLTA', 'HLIO', 'GRNT')
GROUP BY ticker, MONTH(trade_date)
ORDER BY pct_change DESC
LIMIT 3;
```

| ticker | month_no | pct_change | avg_volume | n_days |
|---|---|---|---|---|
| DLTA | 5 | 0.3181 | 15,525,226 | 21 |
| HLIO | 2 | 0.3089 | 1,750,540 | 19 |
| GRNT | 3 | 0.2829 | 7,258,333 | 21 |

> **Teaching note:** Filter rows with `WHERE`, group, sort the groups, then `LIMIT`. HLIO's February swing (0.3089) came on only about 1.75M shares a day, so large price swings do not require heavy trading.

### Question 18: Intraday range as a percent of price

**Scenario:** The desk measures intraday volatility as `(high_price - low_price) / close_price` for each day. For each ticker, report the average of that measure (`avg_daily_range`, rounded to 4 decimals). Keep only tickers where it is **above 0.03**, largest first.

**Answer**

```sql
SELECT ticker,
       ROUND(AVG((high_price - low_price) / close_price), 4) AS avg_daily_range
FROM prices
GROUP BY ticker
HAVING AVG((high_price - low_price) / close_price) > 0.03
ORDER BY avg_daily_range DESC;
```

| ticker | avg_daily_range |
|---|---|
| DLTA | 0.0452 |
| GRNT | 0.0424 |
| BRVO | 0.0361 |
| HLIO | 0.0316 |

> **Teaching note:** A calculated column inside an aggregate: the row-level math happens first, then `AVG` summarizes it. Compare with question 9: this one measures typical daily movement, while that one measures the full period range.

### Question 19: Validate the data

**Scenario:** Before trusting any result, check the table. Write two queries.

(a) List any ticker where the number of rows differs from the number of distinct trading days. Show `ticker`, `n_rows`, `n_days`. (An empty result means the check passed.)
(b) Count the rows that make no sense (`bad_rows`): a `low_price` above the `high_price`, a `close_price` outside the day's low-to-high range, or a `volume` of zero or less. (Again, 0 means the check passed.)

**Answer (a)**

```sql
SELECT ticker,
       COUNT(*)                   AS n_rows,
       COUNT(DISTINCT trade_date) AS n_days
FROM prices
GROUP BY ticker
HAVING COUNT(*) <> COUNT(DISTINCT trade_date);
```

*Result: 0 rows (an empty result).*

**Answer (b)**

```sql
SELECT COUNT(*) AS bad_rows
FROM prices
WHERE low_price > high_price
   OR close_price NOT BETWEEN low_price AND high_price
   OR volume <= 0;
```

| bad_rows |
|---|
| 0 |

> **Teaching note:** Part (a) returns **zero rows**, and that is the correct answer: no duplicates. Part (b) returns a single row with 0. A validation query that finds nothing means the data passed. This is the habit the syllabus rewards.

### Question 20: Capstone: quarterly volatility report

**Scenario:** Build a Q2 2025 report (April 1 to June 30) for the risk committee. For each ticker and month, show `ticker`, `month_no`, `avg_close` (rounded to 2 decimals), `pct_change` (`max_close / min_close - 1`, rounded to 4 decimals) and `total_volume`. Keep only ticker-months where `pct_change` is **above 0.08** **and** `total_volume` is **above 100,000,000**. Order by `pct_change` descending, then `ticker`.

**Answer**

```sql
SELECT ticker,
       MONTH(trade_date)                                  AS month_no,
       ROUND(AVG(close_price), 2)                         AS avg_close,
       ROUND(MAX(close_price) / MIN(close_price) - 1, 4)  AS pct_change,
       SUM(volume)                                        AS total_volume
FROM prices
WHERE trade_date BETWEEN '2025-04-01' AND '2025-06-30'
GROUP BY ticker, MONTH(trade_date)
HAVING MAX(close_price) / MIN(close_price) - 1 > 0.08
   AND SUM(volume) > 100000000
ORDER BY pct_change DESC, ticker;
```

| ticker | month_no | avg_close | pct_change | total_volume |
|---|---|---|---|---|
| DLTA | 5 | 12.48 | 0.3181 | 326,029,740 |
| GRNT | 4 | 55.34 | 0.2504 | 172,468,591 |
| GRNT | 5 | 59.05 | 0.1886 | 156,410,626 |
| DLTA | 4 | 14.87 | 0.1674 | 325,454,060 |
| BRVO | 4 | 53.16 | 0.1673 | 222,580,378 |
| BRVO | 5 | 55.47 | 0.1624 | 210,863,831 |
| DLTA | 6 | 9.97 | 0.1433 | 299,801,749 |
| BRVO | 6 | 50.26 | 0.1226 | 186,303,488 |
| ECHO | 4 | 83.32 | 0.1135 | 126,934,622 |
| ALPH | 4 | 118.9 | 0.1037 | 100,370,356 |
| ECHO | 6 | 84.58 | 0.0917 | 123,652,217 |
| ECHO | 5 | 83.54 | 0.0904 | 130,752,801 |

*Showing the first 12 of 13 rows.*

> **Teaching note:** Uses everything: `WHERE` for the quarter, `GROUP BY` on two keys, three aggregates, `HAVING` with two conditions, and a two-key sort. Build it one clause at a time and check the row count at each step.
