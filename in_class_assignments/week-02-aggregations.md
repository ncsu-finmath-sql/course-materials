# Week 2 In-Class Questions: Aggregations and GROUP BY

**Course:** FIM 590, Data Analytics with SQL
**Data:** the `prices` table (8 fictional tickers, 123 trading days each, 984 rows)

| Column | Meaning |
|---|---|
| `ticker` | Fictional stock symbol (ALPH, BRVO, CRST, DLTA, ECHO, FNCH, GRNT, HLIO) |
| `trade_date` | Trading day, 2025-01-02 to 2025-06-30 |
| `open_price`, `high_price`, `low_price`, `close_price` | Daily prices |
| `volume` | Shares traded |

The questions build on each other: later ones reuse earlier ones, so keep your queries. Work in order, run each query, and check the row count before moving on.


---

## Easy (questions 1-5)

Warm-up: `SELECT`, `WHERE`, `ORDER BY`, `LIMIT` and the basic aggregates.

### Question 1: First rows for one ticker

Show every column for the first 10 trading days of **ALPH** (earliest dates first).

### Question 2: Two tickers, two sort keys

Show `ticker`, `trade_date` and `close_price` for **ALPH and HLIO** only. Sort by `trade_date` (earliest first), then by `ticker`. Keep only the first 6 rows.

### Question 3: Counting rows

(a) How many rows are in `prices`? Name the column `n_rows`.
(b) How many rows belong to tickers **other than** ALPH and HLIO? Name the column `n_rows`.

### Question 4: Counting distinct values

In one query, report the number of different tickers (`n_tickers`) and the number of different trading days (`n_days`).

### Question 5: Summary of the whole table

In one query, show the first date (`first_day`), the last date (`last_day`), the smallest volume (`min_volume`), the largest volume (`max_volume`) and the average volume rounded to a whole number (`avg_volume`).


---

## Medium (questions 6-15)

`GROUP BY`, date functions, monthly statistics, `HAVING` vs `WHERE`.

### Question 6: Filter first, then summarize

For **ALPH** in **June 2025**, report the number of trading days (`n_days`), the lowest close (`lowest_close`) and the highest close (`highest_close`).

### Question 7: Your first GROUP BY

For **every** ticker, show `ticker`, `min_close` and `max_close` across all days. Sort by `ticker`.

### Question 8: Total and average volume

For every ticker, show `ticker`, `total_volume` (sum of volume) and `avg_volume` (average volume, rounded to a whole number). Put the ticker with the most total volume first.

### Question 9: Price range as a percentage

Using your question 7 idea, show each ticker's overall range as a percentage of its lowest close: `max_close / min_close - 1`, rounded to 4 decimals and named `pct_range`. Largest range first.

### Question 10: Date functions

For **ALPH**, from 2025-06-01 to 2025-06-05, show `trade_date` plus its day of the week (`dow`), month (`month_no`) and year (`year_no`).

### Question 11: Group by a date part

Group all rows by day of the week. Show `dow`, the number of rows (`n_rows`) and the average volume rounded to a whole number (`avg_volume`). Sort by `dow`.

### Question 12: Monthly statistics for one ticker

For **ALPH**, show one row per month: `year_no`, `month_no`, `min_price`, `max_price` and `avg_price` (rounded to 2 decimals) of the close price. Sort chronologically.

### Question 13: Monthly range for every ticker

Extend question 12 to **all tickers**. For each ticker and month, compute `pct_change = max_close / min_close - 1` (rounded to 4 decimals). Show `ticker`, `year_no`, `month_no`, `pct_change` for the **5 largest** values.

### Question 14: WHERE vs HAVING

Count the days each ticker traded **more than 5,000,000 shares** (`n_high_days`). Keep only tickers with **at least 76** such days. Sort by `n_high_days` descending.

### Question 15: WHERE and HAVING together

Look only at days with volume above 5,000,000. For each ticker, compute the average volume on those days (`avg_high_volume`, rounded to a whole number) and the number of those days (`n_high_days`). Keep tickers whose `avg_high_volume` is **above 8,000,000**. Highest average first.


---

## Hard (questions 16-20)

Scenarios that combine everything, including a validation habit. All of them use only Week 2 material.

### Question 16: Volatile months only

**Scenario:** A risk manager only wants to see unusually volatile months. Using the monthly `pct_change` from question 13 (`max_close / min_close - 1`), list every ticker-month where it is **above 0.20**. Show `ticker`, `month_no`, `pct_change` (rounded to 4 decimals) and the number of trading days in the group (`n_days`). Largest first.

### Question 17: Watch list: the most volatile months

**Scenario:** The risk committee follows three tickers: **DLTA, HLIO and GRNT**. Find their **3 most volatile ticker-months**. For each, show `ticker`, `month_no`, `pct_change` (`max_close / min_close - 1`, rounded to 4 decimals), `avg_volume` (rounded to a whole number) and `n_days`. Most volatile first.

### Question 18: Intraday range as a percent of price

**Scenario:** The desk measures intraday volatility as `(high_price - low_price) / close_price` for each day. For each ticker, report the average of that measure (`avg_daily_range`, rounded to 4 decimals). Keep only tickers where it is **above 0.03**, largest first.

### Question 19: Validate the data

**Scenario:** Before trusting any result, check the table. Write two queries.

(a) List any ticker where the number of rows differs from the number of distinct trading days. Show `ticker`, `n_rows`, `n_days`. (An empty result means the check passed.)
(b) Count the rows that make no sense (`bad_rows`): a `low_price` above the `high_price`, a `close_price` outside the day's low-to-high range, or a `volume` of zero or less. (Again, 0 means the check passed.)

### Question 20: Capstone: quarterly volatility report

**Scenario:** Build a Q2 2025 report (April 1 to June 30) for the risk committee. For each ticker and month, show `ticker`, `month_no`, `avg_close` (rounded to 2 decimals), `pct_change` (`max_close / min_close - 1`, rounded to 4 decimals) and `total_volume`. Keep only ticker-months where `pct_change` is **above 0.08** **and** `total_volume` is **above 100,000,000**. Order by `pct_change` descending, then `ticker`.
