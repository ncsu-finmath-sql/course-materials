# Week 6 In-Class Questions: Window Functions

**Course:** FIM 590, Data Analytics with SQL

## How to use this sheet

1. Work in order. Questions 1-3 are warm-ups. Question 7 is the big one.
2. Every question ends with a **Check** line. Compare it with what your query gives you. If they don't match, fix your query before moving on.
3. Questions 5 and 7 are **Gemini practice** (optional). Write your own query first, then ask Gemini and critique what it gives you. Everything else: write the SQL yourself.
4. For Gemini practice, paste the whole of `gemini-database-primer.txt` (in the `course-materials` repo), then your question. It describes the tables and nothing else.

## The ideas

| Tool | What it does | Looks like |
|---|---|---|
| **LAG** | Reads a value from an earlier row of the same group | `lag(close_price) over (partition by ticker order by trade_date)` |
| **ROW_NUMBER** | Numbers the rows inside each group | `row_number() over (partition by ticker order by trade_date)` |
| **Running total** | Adds up everything so far | `sum(volume) over (order by trade_date rows between unbounded preceding and current row)` |
| **Rolling frame** | Looks at a fixed number of rows, ending today | `avg(close_price) over (... rows between 9 preceding and current row)` |
| **RANK** | Position among the rows of the same window | `rank() over (order by volume desc)` |

Three reminders:

- A window function **keeps every row**. Only a `WHERE` clause removes rows, and it runs **before** the window. If you need the earlier rows for a window, compute the window first (in a CTE) and filter afterwards.
- A window function **cannot appear in `WHERE`**. DuckDB reports an error. Put it in a CTE, then filter in the outer query.
- Always add `partition by ticker` when the query covers several tickers, or the windows will mix companies.

## The data

One table for today, with 984 rows.

| Table | Rows | One row per | Columns |
|---|---|---|---|
| `prices` | 984 | ticker per trading day (2025-01-02 to 2025-06-30) | `ticker`, `trade_date`, `open_price`, `high_price`, `low_price`, `close_price`, `volume` |

- **8 tickers**, each with **123 trading days**. The grid is complete: every ticker has every day.
- A trading day with no row (for example, Good Friday, 2025-04-18) is not in the data at all.

---

## Easy (questions 1-3)

### Question 1: Day-to-day changes for DLTA

**Task:** For DLTA, show each trading day from 2025-03-03 to 2025-03-07 with the previous day's close and the change in dollars from the previous close, rounded to 2 decimals.

**Show:** `trade_date`, `prev_close`, `close_price`, `change_usd`
**Sort:** by `trade_date`
**Check:** 5 rows. The biggest rise is on 2025-03-06 (+0.59); the biggest fall is on 2025-03-07 (-0.55). The first row's previous close is 16.20.

### Question 2: Number the trading days

**Task:** For GRNT, number every trading day in the data from 1 (1 is 2025-01-02). Then show only the days in March 2025.

**Show:** `trade_date`, `day_no`
**Sort:** by `trade_date`
**Check:** 21 rows. March 3 is day 41 and March 31 is day 61.

### Question 3: Running volume

**Task:** For BRVO, show the total shares traded from 2025-01-02 up to and including 2025-01-31, as a single number.

**Show:** `trade_date`, `running_volume`, for the row on 2025-01-31 only
**Check:** 1 row, with running_volume 217148650. Use a running total with `rows between unbounded preceding and current row`, then filter the result.

---

## Medium (questions 4-6)

### Question 4: A 10-day moving average

**Task:** For ECHO, the 10-day moving average of the close on each day is the average of that day's close and the nine trading days before it. Show the moving average, rounded to 2 decimals, for each day from 2025-04-14 to 2025-04-17.

**Show:** `trade_date`, `close_price`, `ma10`
**Sort:** by `trade_date`
**Check:** 4 rows. The 10-day average on 2025-04-15 is 83.87. Compute the window over the whole ECHO history and filter the dates afterwards: filtering first would shrink the window on 2025-04-14.

### Question 5: The biggest one-day rise for each ticker (Gemini practice)

**Task:** For each ticker, find the trading day with the largest one-day percentage rise in the close. Round the percentage to 2 decimals.

**Show:** `ticker`, `trade_date`, `ret_pct`
**Sort:** biggest rise first, then `ticker`
**Check:** 8 rows. GRNT is first, with +8.17% on 2025-03-20. ALPH is last, with +3.48% on 2025-03-31.

> **Gemini practice**
> 1. Write your own query first.
> 2. Ask Gemini to write the same query. Paste in the primer, then the task above.
> 3. Run Gemini's query and compare it with yours.
> 4. Write one sentence in a comment: what did Gemini get right, and what did you have to fix?

### Question 6: Who traded the most on one day?

**Task:** On 2025-05-30, rank the eight tickers by volume, where rank 1 is the most shares traded.

**Show:** `ticker`, `volume`, `volume_rank`
**Sort:** by `volume_rank`, then `ticker`
**Check:** 8 rows. DLTA is first with 14,386,765 shares. CRST is last with 1,000,925 shares.

---

## Hard (questions 7-8)

### Question 7: The longest winning streak (Gemini practice)

**Task:** A **winning day** is a trading day when the close is higher than the close the trading day before. For each ticker, find the longest run of consecutive winning days.

Hint: a run of winning days is an "island". Two numbers that both go up by one each day, one counted over all days and one counted over winning days only, differ by a constant inside each run. Subtract them and group by that difference.

**Show:** `ticker`, `longest_up_streak`
**Sort:** longest first, then `ticker`
**Check:** 8 rows. BRVO is first with 9 winning days in a row. DLTA is last with 4.

> **Gemini practice**
> 1. Write your own query first, using the hint.
> 2. Ask Gemini for the longest run of winning days per ticker. Paste in the primer first.
> 3. Run Gemini's query and compare it with yours on BRVO. Does it give 9?
> 4. Write one sentence in a comment: what did Gemini get right, and what did you have to fix?

### Question 8: Above or below the 20-day average?

**Task:** On 2025-06-30, compare each ticker's close with its 20-day moving average (the average of that day and the 19 trading days before it, rounded to 2 decimals). Label each ticker `above` if its close is higher, `below` otherwise.

**Show:** `ticker`, `close_price`, `ma20`, `position`
**Sort:** by `ticker`
**Check:** 8 rows. Three tickers are above their 20-day average: ALPH, CRST and HLIO. The other five are below. HLIO's 20-day average is 488.63 and its close is 504.21.
