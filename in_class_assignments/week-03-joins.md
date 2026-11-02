# Week 3 In-Class Questions: JOINs

**Course:** FIM 590, Data Analytics with SQL
**Data:** three tables that share the column `ticker`

| Table | Rows | One row per | Main columns |
|---|---|---|---|
| `prices` | 984 | ticker per trading day (2025-01-02 to 2025-06-30) | `ticker`, `trade_date`, `open_price`, `high_price`, `low_price`, `close_price`, `volume` |
| `companies` | 10 | company | `ticker`, `company_name`, `sector`, `industry`, `exchange`, `hq_state`, `listing_date`, `employees` |
| `fundamentals` | 60 | company per fiscal quarter (2024 Q1 to 2025 Q2) | `ticker`, `fiscal_year`, `fiscal_quarter`, `period_end_date`, `report_date`, `revenue`, `net_income`, `eps`, `shares_outstanding`, `total_assets`, `total_debt`, `total_equity` |

Money in `fundamentals` is in **$ millions** and shares are in **millions**. IOTA and JUNO are in `companies` and `fundamentals` but listed after June 2025, so they have no rows in `prices`.

Before you run a join, write down how many rows you expect from the keys of the tables. Then check the row count of your result.


---

## Easy (questions 1-3)

Warm-up: `INNER JOIN`, `LEFT JOIN` and counting joined rows.

### Question 1: Add company names to prices

For **2025-06-30**, show `ticker`, `company_name`, `sector` and `close_price` for every stock that traded that day. Put the highest close first.

### Question 2: Counting joined rows

(a) How many rows in `prices` belong to companies listed on the **NYSE**? Name the column `n_rows`.
(b) How many rows in `fundamentals` belong to **Health Care** companies? Name the column `n_rows`.

### Question 3: Companies with no price data

List every company that has **no rows** in `prices`. Show `ticker`, `company_name` and `listing_date`. Sort by `ticker`.

---

## Medium (questions 4-7)

Joins combined with `WHERE`, `GROUP BY`, calculated columns and multi-column keys.

### Question 4: Sector summary for June

For **June 2025**, show one row per sector: `sector`, the number of different tickers (`n_tickers`), the average close rounded to 2 decimals (`avg_close`) and the total volume (`total_volume`). Highest total volume first.

### Question 5: Profit margins with company names

For fiscal **2025 Q1**, show `company_name`, `sector`, `revenue`, `net_income` and the net margin `net_income / revenue` rounded to 4 decimals (`net_margin`). Highest margin first.

### Question 6: The stock price on earnings day

For every quarterly report published while `prices` has data, show `ticker`, `fiscal_year`, `fiscal_quarter`, `report_date`, `eps`, `close_price` and the move from open to close that day, `close_price / open_price - 1`, rounded to 4 decimals (`day_move`). Sort by `report_date`, then `ticker`.

### Question 7: LEFT JOIN: filter in ON vs WHERE

(a) List **all 10** companies with their `close_price` on **2025-06-30** (NULL if they have none). Show `ticker`, `company_name` and `close_price`, sorted by `ticker`.
(b) Move the date condition from `ON` to `WHERE`. How many rows do you get now (`n_rows`), and why?

---

## Hard (questions 8-10)

Three-table joins, `FULL OUTER JOIN` and a validation habit. All of them use only Week 3 material.

### Question 8: Valuation snapshot (three tables)

**Scenario:** A portfolio manager wants a valuation snapshot as of **2025-06-30**, using the latest quarter reported by then (fiscal **2025 Q1**). For each company show `ticker`, `company_name`, `close_price`, market cap in $ millions `close_price * shares_outstanding` rounded to a whole number (`market_cap_musd`), and an annualized P/E `close_price / (eps * 4)` rounded to 1 decimal (`pe`). Keep only companies with a market cap **above 20,000** ($20 billion). Largest market cap first.

### Question 9: Two watch lists (FULL OUTER JOIN)

**Scenario:** The trading desk keeps a *liquidity list*: tickers with at least one day of volume **above 15,000,000**. The research team keeps a *quality list*: companies whose fiscal **2025 Q1** net margin (`net_income / revenue`) is **above 0.10**.

(a) Combine the two lists so that every ticker on **either** list appears once. Show `ticker`, `on_liquidity_list` and `on_quality_list` (true/false). Sort by `ticker`.
(b) Keep only the tickers that are on **exactly one** list.

### Question 10: Capstone: earnings-day report with a check

**Scenario:** Build the earnings-day report for the fiscal **2024 Q4** results (published in March 2025).

(a) For each report, show `ticker`, `company_name`, `sector`, `report_date`, `eps`, `close_price`, `volume` and `day_move` (`close_price / open_price - 1`, rounded to 4 decimals). Biggest `day_move` first.
(b) **Validate:** how many fiscal 2024 Q4 reports exist (`n_reports`), and how many of them have a price row on their report date (`n_with_price`)? Then list the reports with no price (`ticker`, `report_date`) and explain them.
