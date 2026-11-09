# Week 4 In-Class Questions: CTEs and CASE

**Course:** FIM 590, Data Analytics with SQL

## How to use this sheet

1. Work in order. Questions 1-3 are warm-ups. Question 10 is the big one.
2. Every question ends with a **Check** line. Compare it with what your query gives you. If they don't match, fix your query before moving on.
3. Questions 5 and 7 are **Gemini practice**. Do them as described in the box. Everything else: write the SQL yourself.
4. For Gemini practice, attach the database primer first: paste the whole of `gemini-database-primer.txt` (in the `course-materials` repo), then your question. It only describes the tables.

## The two ideas

| Tool | What it does | Looks like |
|---|---|---|
| **CTE** | Gives one step of a query a name, so you can use it like a table | `with step_1 as (select ...) select ... from step_1` |
| **CASE** | Picks a value for each row. The first `when` that is true wins | `case when x > 10 then 'big' else 'small' end` |

Two reminders:

- Put a comma between CTEs, but **not** before the final `select`.
- Always add an `else`. Without one, rows that match nothing get `null`.

## The data

Three new tables, plus the ones you already know (`prices`, `companies`, `fundamentals`).

| Table | Rows | One row per | Columns |
|---|---|---|---|
| `fx_rates` | 738 | currency pair per trading day | `pair`, `rate_date`, `rate`, `day_high`, `day_low` |
| `fx_pairs` | 6 | currency pair | `pair`, `base_ccy`, `quote_ccy`, `base_name`, `region` |
| `fx_exposure` | 19 | company per foreign currency | `ticker`, `ccy`, `pct_revenue` |

- **The pairs:** EURUSD, GBPUSD, AUDUSD, USDJPY, USDCAD, USDCHF. The dates are the same 123 trading days as `prices`.
- **Watch the direction.** `EURUSD` is dollars per euro (about 1.08). `USDJPY` is yen per dollar (about 130). To compare pairs, convert them all to **dollars per foreign unit**:

```sql
case
	when quote_ccy = 'USD' then rate
	else 1.0 / rate
end as usd_per_foreign
```

- **Daily range** means `(day_high - day_low) / rate`. It shows how much the rate moved around during the day.
- `pct_revenue` is the share of a company's sales earned in that currency, as a percent (22.00 means 22%). The rest is US dollars.

---

## Easy (questions 1-3)

### Question 1: The widest EURUSD days

**Task:** Make a CTE called `eur_ranges` with the date and the daily range of EURUSD. Then show the 5 days with the widest range.

**Show:** `rate_date`, `range_pct` (the daily range, rounded to 4 decimals)
**Sort:** widest range first, then by date
**Check:** 5 rows. The first one is 2025-02-27.

### Question 2: Company size labels

**Task:** Label every company by its number of employees: `large` for 20000 or more, `medium` for 5000 or more, `small` for the rest.

**Show:** `ticker`, `company_name`, `employees`, `size_label`
**Sort:** most employees first
**Check:** 10 rows. 4 are large, 3 are medium, 3 are small.

### Question 3: Active FX days

**Task:** A day is **active** when the daily range is 0.005 or more. Use a CTE to count the active days for each pair.

**Show:** `pair`, `n_active_days`
**Sort:** by `pair`
**Check:** 6 rows. EURUSD has 66.

---

## Medium (questions 4-7)

### Question 4: Up days and down days

**Task:** For each stock, count the trading days. Also count the days it closed **higher** than it opened (`n_up_days`) and the days it closed **lower** (`n_down_days`). Use `sum(case ...)`.

**Show:** `ticker`, `n_days`, `n_up_days`, `n_down_days`
**Sort:** by `ticker`
**Check:** 8 rows, with 123 days each. HLIO has 74 up days.

### Question 5: Dollars per foreign unit (Gemini practice)

**Task:** For **2025-03-31**, show all six pairs on the same footing. Add the foreign currency (the one that isn't USD) and the rate in dollars per foreign unit.

**Show:** `pair`, `foreign_ccy`, `rate`, `usd_per_foreign` (rounded to 4 decimals)
**Sort:** highest `usd_per_foreign` first
**Check:** 6 rows. USDJPY is last, at 0.0072.

> **Gemini practice**
> 1. Write your own query first.
> 2. Ask Gemini to write the same query. Paste in the primer, then the task above.
> 3. Run Gemini's query and compare it with yours. Look for: a made-up column, a missing flip (`1.0 / rate`), and the wrong number of rows.
> 4. Write one sentence in a comment: what did Gemini get right, and what did you have to fix?

### Question 6: Who gained and who lost against the dollar?

**Task:** Compare each currency on **2025-01-02** with **2025-06-30**, in dollars per foreign unit. Use CTEs: one for the converted rates, one for the first day, one for the last day. Then join the last two.

**Show:** `pair`, `start_usd`, `end_usd` (both rounded to 4 decimals), `pct_change` (`end_usd / start_usd - 1`, rounded to 4 decimals)
**Sort:** biggest `pct_change` first
**Check:** 6 rows. The biggest gain is USDJPY (0.1988), the biggest loss is AUDUSD (-0.0711).

### Question 7: Foreign exposure levels (Gemini practice)

**Task:** For each company, add up its foreign revenue share. Then label it `high` (25 or more), `medium` (10 or more) or `low`.

**Show:** `ticker`, `company_name`, `n_currencies`, `total_foreign_pct`, `exposure_level`
**Sort:** largest `total_foreign_pct` first, then by `ticker`
**Check:** 10 rows. 6 are high, 2 are medium, 2 are low. IOTA is first with 43.

> **Gemini practice**
> 1. Ask Gemini first this time. Paste in the primer, then the task above.
> 2. Before you run it, read it. Does every column exist? Is there a `group by`? Is the `case` in the right order?
> 3. Run it and compare with the Check line. Fix what's wrong.
> 4. Write one sentence in a comment about what you changed and how you knew.

---

## Hard (questions 8-10)

### Question 8: Foreign revenue in dollars

**Scenario:** A manager wants to know where the big foreign sales are. For fiscal **2025 Q1**, the foreign revenue in a currency is `revenue * pct_revenue / 100`, in $ millions.

**Task:** Use a CTE to work out the foreign revenue for each company and currency. Then keep only the amounts **above 500**.

**Show:** `ticker`, `company_name`, `ccy`, `foreign_revenue_musd` (rounded to a whole number)
**Sort:** largest first
**Check:** 8 rows. The largest is HLIO in JPY (3221).

### Question 9: The dollar scorecard

**Scenario:** Did the dollar get stronger or weaker against each currency between **2025-01-02** and **2025-06-30**? If a currency lost more than 1% (in dollars per foreign unit), the dollar got **stronger**. If it gained more than 1%, the dollar got **weaker**. Otherwise it is **steady**.

**(a)** Show `pair`, `pct_change` (rounded to 4 decimals) and `usd_trend` (`USD stronger`, `USD weaker` or `steady`). Sort by `pair`.
**(b)** Count how many pairs fall in each group in one row: `n_stronger`, `n_weaker`, `n_steady`.

**Check:** (a) 6 rows. (b) 3, 2 and 1.

### Question 10: Capstone: currency headwinds and tailwinds, with a check

**Scenario:** Which companies are helped or hurt by currency moves between **2025-01-02** and **2025-06-30**? Look at each company's foreign currency. It is a **headwind** if the currency lost more than 2% against the dollar **and** it is at least 15% of the company's revenue. It is a **tailwind** if the currency gained more than 2% and is at least 15% of revenue. Anything else is **minor**.

**(a)** Show `ticker`, `ccy`, `pct_revenue`, `pct_change` (rounded to 4 decimals) and `impact`. Sort by `ticker`, then `ccy`.

*Hint:* `fx_exposure` uses currency codes such as `EUR`. `fx_rates` uses pairs such as `EURUSD`. Use a `case` on `fx_pairs` to find each pair's foreign currency: `case when base_ccy = 'USD' then quote_ccy else base_ccy end`.

**(b) Validate:** How many rows does `fx_exposure` have (`n_exposure`)? How many rows does your result in (a) have (`n_result`)? If they differ, explain what happened. Write the two counts as one query with two numbers.

**Check:** (a) 19 rows, with 2 headwinds and 5 tailwinds. (b) both counts equal 19.
