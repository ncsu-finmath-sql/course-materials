# Week 3 In-Class Questions with Answers: JOINs

**Course:** FIM 590, Data Analytics with SQL
**Data:** three tables that share the column `ticker`

| Table | Rows | One row per | Main columns |
|---|---|---|---|
| `prices` | 984 | ticker per trading day (2025-01-02 to 2025-06-30) | `ticker`, `trade_date`, `open_price`, `high_price`, `low_price`, `close_price`, `volume` |
| `companies` | 10 | company | `ticker`, `company_name`, `sector`, `industry`, `exchange`, `hq_state`, `listing_date`, `employees` |
| `fundamentals` | 60 | company per fiscal quarter (2024 Q1 to 2025 Q2) | `ticker`, `fiscal_year`, `fiscal_quarter`, `period_end_date`, `report_date`, `revenue`, `net_income`, `eps`, `shares_outstanding`, `total_assets`, `total_debt`, `total_equity` |

Money in `fundamentals` is in **$ millions** and shares are in **millions**. IOTA and JUNO are in `companies` and `fundamentals` but listed after June 2025, so they have no rows in `prices`.

Before you run a join, write down how many rows you expect from the keys of the tables. Then check the row count of your result.

*Every result below was produced by running the query on the course data.*


---

## Easy (questions 1-3)

Warm-up: `INNER JOIN`, `LEFT JOIN` and counting joined rows.

### Question 1: Add company names to prices

For **2025-06-30**, show `ticker`, `company_name`, `sector` and `close_price` for every stock that traded that day. Put the highest close first.

**Answer**

```sql
SELECT p.ticker, c.company_name, c.sector, p.close_price
FROM prices p
JOIN companies c ON c.ticker = p.ticker
WHERE p.trade_date = '2025-06-30'
ORDER BY p.close_price DESC;
```

| ticker | company_name | sector | close_price |
|---|---|---|---|
| HLIO | Helio Semiconductor Ltd. | Information Technology | 504.21 |
| CRST | Crestmark Health Holdings | Health Care | 263.38 |
| FNCH | Finch Harbor Financial | Financials | 151.05 |
| ALPH | Alphaline Systems Inc. | Information Technology | 112.01 |
| ECHO | Echo Valley Foods Inc. | Consumer Staples | 83.77 |
| GRNT | Granite Peak Materials | Materials | 53.36 |
| BRVO | Bravo Outfitters Corp. | Consumer Discretionary | 48.16 |
| DLTA | Deltaridge Energy Co. | Energy | 9.28 |

*8 rows.*

> **Teaching note:** 8 rows, not 10: an `INNER JOIN` keeps only matches, and IOTA and JUNO have no price rows.

### Question 2: Counting joined rows

(a) How many rows in `prices` belong to companies listed on the **NYSE**? Name the column `n_rows`.
(b) How many rows in `fundamentals` belong to **Health Care** companies? Name the column `n_rows`.

**Answer (a)**

```sql
SELECT COUNT(*) AS n_rows
FROM prices p
JOIN companies c ON c.ticker = p.ticker
WHERE c.exchange = 'NYSE';
```

| n_rows |
|---|
| 615 |

**Answer (b)**

```sql
SELECT COUNT(*) AS n_rows
FROM fundamentals f
JOIN companies c ON c.ticker = f.ticker
WHERE c.sector = 'Health Care';
```

| n_rows |
|---|
| 12 |

> **Teaching note:** Check (a) with the keys: five NYSE companies have prices (JUNO has none), and 5 x 123 days = 615. For (b), two Health Care companies x 6 quarters = 12. You can filter on a column, like `exchange` or `sector`, that only exists in the other table.

### Question 3: Companies with no price data

List every company that has **no rows** in `prices`. Show `ticker`, `company_name` and `listing_date`. Sort by `ticker`.

**Answer**

```sql
SELECT c.ticker, c.company_name, c.listing_date
FROM companies c
LEFT JOIN prices p ON p.ticker = c.ticker
WHERE p.ticker IS NULL
ORDER BY c.ticker;
```

| ticker | company_name | listing_date |
|---|---|---|
| IOTA | Iota Biotherapeutics Inc. | 2025-09-17 |
| JUNO | Juno Mobility Corp. | 2025-11-05 |

*2 rows.*

> **Teaching note:** This is an *anti-join*: a `LEFT JOIN`, then keep only the rows where the right side found nothing (`IS NULL`). The listing dates explain why these two have no prices.

---

## Medium (questions 4-7)

Joins combined with `WHERE`, `GROUP BY`, calculated columns and multi-column keys.

### Question 4: Sector summary for June

For **June 2025**, show one row per sector: `sector`, the number of different tickers (`n_tickers`), the average close rounded to 2 decimals (`avg_close`) and the total volume (`total_volume`). Highest total volume first.

**Answer**

```sql
SELECT c.sector,
       COUNT(DISTINCT p.ticker)    AS n_tickers,
       ROUND(AVG(p.close_price), 2) AS avg_close,
       SUM(p.volume)               AS total_volume
FROM prices p
JOIN companies c ON c.ticker = p.ticker
WHERE p.trade_date BETWEEN '2025-06-01' AND '2025-06-30'
GROUP BY c.sector
ORDER BY total_volume DESC;
```

| sector | n_tickers | avg_close | total_volume |
|---|---|---|---|
| Energy | 1 | 9.97 | 299,801,749 |
| Consumer Discretionary | 1 | 50.26 | 186,303,488 |
| Materials | 1 | 55.7 | 153,680,415 |
| Consumer Staples | 1 | 84.58 | 123,652,217 |
| Information Technology | 2 | 300.02 | 122,886,916 |
| Financials | 1 | 155.02 | 65,710,789 |
| Health Care | 1 | 258.6 | 42,568,320 |

*7 rows.*

> **Teaching note:** Join first, then `WHERE`, then `GROUP BY`: the Week 2 steps work the same way on a joined table. Information Technology has two tickers (ALPH and HLIO), so its average mixes two very different price levels.

### Question 5: Profit margins with company names

For fiscal **2025 Q1**, show `company_name`, `sector`, `revenue`, `net_income` and the net margin `net_income / revenue` rounded to 4 decimals (`net_margin`). Highest margin first.

**Answer**

```sql
SELECT c.company_name, c.sector, f.revenue, f.net_income,
       ROUND(f.net_income / f.revenue, 4) AS net_margin
FROM fundamentals f
JOIN companies c ON c.ticker = f.ticker
WHERE f.fiscal_year = 2025
  AND f.fiscal_quarter = 1
ORDER BY net_margin DESC;
```

| company_name | sector | revenue | net_income | net_margin |
|---|---|---|---|---|
| Finch Harbor Financial | Financials | 1665.8 | 515.2 | 0.3093 |
| Helio Semiconductor Ltd. | Information Technology | 12389.5 | 3330.2 | 0.2688 |
| Alphaline Systems Inc. | Information Technology | 7347.7 | 1837.1 | 0.25 |
| Granite Peak Materials | Materials | 2007.1 | 229.9 | 0.1145 |
| Echo Valley Foods Inc. | Consumer Staples | 5294.2 | 484.9 | 0.0916 |
| Deltaridge Energy Co. | Energy | 2017.8 | 133.9 | 0.0664 |
| Bravo Outfitters Corp. | Consumer Discretionary | 4083.4 | 184.0 | 0.0451 |
| Crestmark Health Holdings | Health Care | 23069.3 | 1013.9 | 0.044 |
| Juno Mobility Corp. | Industrials | 303.6 | -61.6 | -0.2029 |
| Iota Biotherapeutics Inc. | Health Care | 35.7 | -96.2 | -2.6947 |

*10 rows.*

> **Teaching note:** All 10 companies appear, because every company has fundamentals. IOTA and JUNO are losing money, so their margins are negative.

### Question 6: The stock price on earnings day

For every quarterly report published while `prices` has data, show `ticker`, `fiscal_year`, `fiscal_quarter`, `report_date`, `eps`, `close_price` and the move from open to close that day, `close_price / open_price - 1`, rounded to 4 decimals (`day_move`). Sort by `report_date`, then `ticker`.

**Answer**

```sql
SELECT f.ticker, f.fiscal_year, f.fiscal_quarter, f.report_date, f.eps,
       p.close_price,
       ROUND(p.close_price / p.open_price - 1, 4) AS day_move
FROM fundamentals f
JOIN prices p
  ON p.ticker = f.ticker
 AND p.trade_date = f.report_date
ORDER BY f.report_date, f.ticker;
```

| ticker | fiscal_year | fiscal_quarter | report_date | eps | close_price | day_move |
|---|---|---|---|---|---|---|
| ECHO | 2024 | 4 | 2025-03-05 | 1.01 | 84.58 | 0.0126 |
| GRNT | 2024 | 4 | 2025-03-05 | 0.63 | 61.7 | -0.0346 |
| FNCH | 2024 | 4 | 2025-03-10 | 1.77 | 162.32 | -0.0242 |
| HLIO | 2024 | 4 | 2025-03-10 | 5.11 | 423.87 | 0.0039 |
| CRST | 2024 | 4 | 2025-03-12 | 2.72 | 253.14 | 0.0141 |
| ALPH | 2024 | 4 | 2025-03-13 | 2.01 | 118.02 | 0.002 |
| BRVO | 2024 | 4 | 2025-03-17 | 0.63 | 47.32 | 0.0098 |
| DLTA | 2024 | 4 | 2025-03-17 | 0.12 | 15.21 | 0.0194 |
| FNCH | 2025 | 1 | 2025-04-29 | 1.9 | 156.17 | -0.0069 |
| HLIO | 2025 | 1 | 2025-04-29 | 5.48 | 473.87 | 0.0125 |
| ECHO | 2025 | 1 | 2025-04-30 | 0.87 | 80.8 | 0.0155 |
| ALPH | 2025 | 1 | 2025-05-05 | 2.19 | 115.01 | -0.0044 |

*Showing the first 12 of 16 rows.*

> **Teaching note:** The join needs **two** conditions: same ticker **and** same date. You don't need a date filter: the `INNER JOIN` keeps only the reports that have a price row on that day (2024 Q4 and 2025 Q1 for the 8 priced tickers = 16 rows).

### Question 7: LEFT JOIN: filter in ON vs WHERE

(a) List **all 10** companies with their `close_price` on **2025-06-30** (NULL if they have none). Show `ticker`, `company_name` and `close_price`, sorted by `ticker`.
(b) Move the date condition from `ON` to `WHERE`. How many rows do you get now (`n_rows`), and why?

**Answer (a)**

```sql
SELECT c.ticker, c.company_name, p.close_price
FROM companies c
LEFT JOIN prices p
       ON p.ticker = c.ticker
      AND p.trade_date = '2025-06-30'
ORDER BY c.ticker;
```

| ticker | company_name | close_price |
|---|---|---|
| ALPH | Alphaline Systems Inc. | 112.01 |
| BRVO | Bravo Outfitters Corp. | 48.16 |
| CRST | Crestmark Health Holdings | 263.38 |
| DLTA | Deltaridge Energy Co. | 9.28 |
| ECHO | Echo Valley Foods Inc. | 83.77 |
| FNCH | Finch Harbor Financial | 151.05 |
| GRNT | Granite Peak Materials | 53.36 |
| HLIO | Helio Semiconductor Ltd. | 504.21 |
| IOTA | Iota Biotherapeutics Inc. | NULL |
| JUNO | Juno Mobility Corp. | NULL |

*10 rows.*

**Answer (b)**

```sql
SELECT COUNT(*) AS n_rows
FROM companies c
LEFT JOIN prices p ON p.ticker = c.ticker
WHERE p.trade_date = '2025-06-30';
```

| n_rows |
|---|
| 8 |

> **Teaching note:** In (b), IOTA and JUNO get a NULL `trade_date` from the `LEFT JOIN`, and `NULL = '2025-06-30'` is not true, so `WHERE` removes them. A filter on the right-hand table of a `LEFT JOIN` belongs in `ON`.

---

## Hard (questions 8-10)

Three-table joins, `FULL OUTER JOIN` and a validation habit. All of them use only Week 3 material.

### Question 8: Valuation snapshot (three tables)

**Scenario:** A portfolio manager wants a valuation snapshot as of **2025-06-30**, using the latest quarter reported by then (fiscal **2025 Q1**). For each company show `ticker`, `company_name`, `close_price`, market cap in $ millions `close_price * shares_outstanding` rounded to a whole number (`market_cap_musd`), and an annualized P/E `close_price / (eps * 4)` rounded to 1 decimal (`pe`). Keep only companies with a market cap **above 20,000** ($20 billion). Largest market cap first.

**Answer**

```sql
SELECT c.ticker, c.company_name, p.close_price,
       ROUND(p.close_price * f.shares_outstanding)  AS market_cap_musd,
       ROUND(p.close_price / (f.eps * 4), 1)         AS pe
FROM companies c
JOIN prices p
  ON p.ticker = c.ticker
 AND p.trade_date = '2025-06-30'
JOIN fundamentals f
  ON f.ticker = c.ticker
 AND f.fiscal_year = 2025
 AND f.fiscal_quarter = 1
WHERE p.close_price * f.shares_outstanding > 20000
ORDER BY market_cap_musd DESC;
```

| ticker | company_name | close_price | market_cap_musd | pe |
|---|---|---|---|---|
| HLIO | Helio Semiconductor Ltd. | 504.21 | 306,156 | 23.0 |
| CRST | Crestmark Health Holdings | 263.38 | 109,856 | 27.1 |
| ALPH | Alphaline Systems Inc. | 112.01 | 93,965 | 12.8 |
| ECHO | Echo Valley Foods Inc. | 83.77 | 46,434 | 24.1 |
| FNCH | Finch Harbor Financial | 151.05 | 40,995 | 19.9 |
| GRNT | Granite Peak Materials | 53.36 | 20,586 | 22.2 |

*6 rows.*

> **Teaching note:** Why 2025 Q1 and not Q2? The Q2 reports came out from late July, after June 30, so on June 30 an investor could only know Q1. Picking data that was available on the date is called avoiding *look-ahead bias*. Without the filter there are 8 rows; BRVO and DLTA fall below $20 billion.

### Question 9: Two watch lists (FULL OUTER JOIN)

**Scenario:** The trading desk keeps a *liquidity list*: tickers with at least one day of volume **above 15,000,000**. The research team keeps a *quality list*: companies whose fiscal **2025 Q1** net margin (`net_income / revenue`) is **above 0.10**.

(a) Combine the two lists so that every ticker on **either** list appears once. Show `ticker`, `on_liquidity_list` and `on_quality_list` (true/false). Sort by `ticker`.
(b) Keep only the tickers that are on **exactly one** list.

**Answer (a)**

```sql
SELECT COALESCE(l.ticker, q.ticker) AS ticker,
       l.ticker IS NOT NULL         AS on_liquidity_list,
       q.ticker IS NOT NULL         AS on_quality_list
FROM (SELECT DISTINCT ticker
      FROM prices
      WHERE volume > 15000000) AS l
FULL OUTER JOIN
     (SELECT ticker
      FROM fundamentals
      WHERE fiscal_year = 2025 AND fiscal_quarter = 1
        AND net_income / revenue > 0.10) AS q
  ON q.ticker = l.ticker
ORDER BY ticker;
```

| ticker | on_liquidity_list | on_quality_list |
|---|---|---|
| ALPH | false | true |
| BRVO | true | false |
| DLTA | true | false |
| ECHO | true | false |
| FNCH | false | true |
| GRNT | true | true |
| HLIO | false | true |

*7 rows.*

**Answer (b)**

```sql
SELECT COALESCE(l.ticker, q.ticker) AS ticker,
       l.ticker IS NOT NULL         AS on_liquidity_list,
       q.ticker IS NOT NULL         AS on_quality_list
FROM (SELECT DISTINCT ticker
      FROM prices
      WHERE volume > 15000000) AS l
FULL OUTER JOIN
     (SELECT ticker
      FROM fundamentals
      WHERE fiscal_year = 2025 AND fiscal_quarter = 1
        AND net_income / revenue > 0.10) AS q
  ON q.ticker = l.ticker
WHERE l.ticker IS NULL OR q.ticker IS NULL
ORDER BY ticker;
```

| ticker | on_liquidity_list | on_quality_list |
|---|---|---|
| ALPH | false | true |
| BRVO | true | false |
| DLTA | true | false |
| ECHO | true | false |
| FNCH | false | true |
| HLIO | false | true |

*6 rows.*

> **Teaching note:** Each list is a small query in `FROM`, joined like a table. `DISTINCT` matters on the liquidity list: without it a ticker with many high-volume days would appear many times. Only GRNT is on both lists. `COALESCE` picks whichever ticker isn't NULL, because in a `FULL OUTER JOIN` either side can be missing. An `INNER JOIN` would give 1 row, a `LEFT JOIN` 4 and a `RIGHT JOIN` 4.

### Question 10: Capstone: earnings-day report with a check

**Scenario:** Build the earnings-day report for the fiscal **2024 Q4** results (published in March 2025).

(a) For each report, show `ticker`, `company_name`, `sector`, `report_date`, `eps`, `close_price`, `volume` and `day_move` (`close_price / open_price - 1`, rounded to 4 decimals). Biggest `day_move` first.
(b) **Validate:** how many fiscal 2024 Q4 reports exist (`n_reports`), and how many of them have a price row on their report date (`n_with_price`)? Then list the reports with no price (`ticker`, `report_date`) and explain them.

**Answer (a)**

```sql
SELECT c.ticker, c.company_name, c.sector, f.report_date, f.eps,
       p.close_price, p.volume,
       ROUND(p.close_price / p.open_price - 1, 4) AS day_move
FROM fundamentals f
JOIN companies c
  ON c.ticker = f.ticker
JOIN prices p
  ON p.ticker = f.ticker
 AND p.trade_date = f.report_date
WHERE f.fiscal_year = 2024
  AND f.fiscal_quarter = 4
ORDER BY day_move DESC;
```

| ticker | company_name | sector | report_date | eps | close_price | volume | day_move |
|---|---|---|---|---|---|---|---|
| DLTA | Deltaridge Energy Co. | Energy | 2025-03-17 | 0.12 | 15.21 | 10,965,971 | 0.0194 |
| CRST | Crestmark Health Holdings | Health Care | 2025-03-12 | 2.72 | 253.14 | 2,840,926 | 0.0141 |
| ECHO | Echo Valley Foods Inc. | Consumer Staples | 2025-03-05 | 1.01 | 84.58 | 4,824,008 | 0.0126 |
| BRVO | Bravo Outfitters Corp. | Consumer Discretionary | 2025-03-17 | 0.63 | 47.32 | 8,732,481 | 0.0098 |
| HLIO | Helio Semiconductor Ltd. | Information Technology | 2025-03-10 | 5.11 | 423.87 | 1,289,974 | 0.0039 |
| ALPH | Alphaline Systems Inc. | Information Technology | 2025-03-13 | 2.01 | 118.02 | 5,165,228 | 0.002 |
| FNCH | Finch Harbor Financial | Financials | 2025-03-10 | 1.77 | 162.32 | 4,980,216 | -0.0242 |
| GRNT | Granite Peak Materials | Materials | 2025-03-05 | 0.63 | 61.7 | 11,569,953 | -0.0346 |

*8 rows.*

**Answer (b)**

```sql
SELECT COUNT(*)        AS n_reports,
       COUNT(p.ticker) AS n_with_price
FROM fundamentals f
LEFT JOIN prices p
       ON p.ticker = f.ticker
      AND p.trade_date = f.report_date
WHERE f.fiscal_year = 2024
  AND f.fiscal_quarter = 4;
```

| n_reports | n_with_price |
|---|---|
| 10 | 8 |

**Answer (b, part 2)**

```sql
SELECT f.ticker, f.report_date
FROM fundamentals f
LEFT JOIN prices p
       ON p.ticker = f.ticker
      AND p.trade_date = f.report_date
WHERE f.fiscal_year = 2024
  AND f.fiscal_quarter = 4
  AND p.ticker IS NULL
ORDER BY f.ticker;
```

| ticker | report_date |
|---|---|
| IOTA | 2025-03-11 |
| JUNO | 2025-03-13 |

*2 rows.*

> **Teaching note:** `COUNT(*)` counts every row of the `LEFT JOIN`; `COUNT(p.ticker)` skips NULLs, so it counts only the matches. The 2 missing reports are IOTA and JUNO, which weren't trading yet. That's expected, so the 8-row report in (a) is complete. If an unexpected ticker showed up here, you'd fix the data before trusting the report.
