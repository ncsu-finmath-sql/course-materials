-- ============================================================
-- FIM 590 | Week 4 | CTEs, CASE and the FX data
-- BLANK VERSION: write each exercise live; answers are in 'Week 4 presentation notes.sql'
--
-- Three ideas today:
--   1. A CTE (WITH ...) gives a step of a query a NAME.
--   2. CASE lets a query make a DECISION for each row.
--   3. FX rates are quoted in different directions, and CASE fixes that.
--
-- New tables (synthetic data, fictional companies, real currency pairs):
--   fx_rates    (pair, rate_date, rate, day_high, day_low)      738 rows
--   fx_pairs    (pair, base_ccy, quote_ccy, base_name, region)    6 rows
--   fx_exposure (ticker, ccy, pct_revenue)                       19 rows
-- Tables from earlier weeks: prices, companies, fundamentals.
--
-- Join spelling: always INNER JOIN. (A plain JOIN means exactly the same thing.)
-- ============================================================


-- ------------------------------------------------------------
-- 0. Meet the FX data
-- ------------------------------------------------------------
-- Before any query, ask "what is one row?"
-- fx_rates: one row per currency PAIR per trading DAY.  Key = pair + rate_date.
-- fx_pairs: one row per pair.                           Key = pair.

-- EXERCISE 1: Show every column of fx_pairs, sorted by pair.



-- 6 rows. Look at base_ccy and quote_ccy. EURUSD = EUR priced in USD. USDJPY = USD priced in JPY.

-- EXERCISE 2: Show the rate on 2025-06-30 for EURUSD and for USDJPY.



-- 2 rows. EURUSD is about 1.08, USDJPY is about 130.5.
-- 1 euro buys about 1.08 dollars. 1 dollar buys about 130 yen.
-- The two rates point in OPPOSITE directions. Remember this: CASE will fix it later.

-- EXERCISE 3: How many rows are in fx_rates, and how many different days?



-- 738 rows, 123 days. 6 pairs x 123 days = 738. Same trading days as prices.


-- ------------------------------------------------------------
-- 1. CTEs: give a step a name
-- ------------------------------------------------------------
-- The question: "On how many days was EURUSD's trading range wider than 1%?"
-- Range as a share of the rate = (day_high - day_low) / rate.
-- Two steps: (1) work out the range each day, (2) count the wide days.

-- Version 1: step 1 written as a subquery inside FROM (the Week 3 style).
-- EXERCISE 4: Count the EURUSD days where (day_high - day_low) / rate is above 0.01. Use a subquery in FROM. Name the count n_wide_days.



-- 12

-- Version 2: the same query, with step 1 as a CTE.
-- Read it top to bottom. First we build a small table called eur_ranges.
-- Then we use it like any other table.
-- EXERCISE 5: Same question, but with a CTE called eur_ranges.



-- 12 again. Same answer, easier to read.

-- Habit: run each step on its own before you add the next one.
-- EXERCISE 6: Look at the first 5 rows of the eur_ranges step on its own.



-- 5 rows, 2025-01-02 to 2025-01-08, with a range_pct between about 0.002 and 0.012.

-- Version 3: two CTEs in a chain. The second one uses the first one.
-- One WITH. A comma between CTEs. NO comma before the final SELECT.
-- EXERCISE 7: Chain two CTEs: eur_ranges, then wide_days (range above 0.01). Show how many wide days there were and their average range.



-- 1 row. 12 days, average range 0.0115.

-- Refactor a Week 3 query: the two watch lists, now with names.
-- (Last week these were subqueries inside FROM.)
-- EXERCISE 8: Rewrite the Week 3 FULL OUTER JOIN of list A (closed above $100 on 2025-06-30) and list B (Information Technology or Health Care) with two CTEs. Show ticker, close_price, sector.



-- 5 rows, the same as last week: ALPH, CRST, FNCH (no sector), HLIO, IOTA (no price).
-- A CTE is a name for a query. It is not a saved table. It only lives for this one statement.


-- ------------------------------------------------------------
-- 2. CASE: make a decision for every row
-- ------------------------------------------------------------
-- CASE is a ladder. SQL tests the WHENs from the top.
-- The FIRST one that is true wins. ELSE catches everything left over.

-- EXERCISE 9: For every pair, say how the rate is quoted: 'USD per foreign unit' when quote_ccy is USD, otherwise 'foreign units per USD'. Show pair, quote_ccy and the label as quoted_as.



-- 6 rows. EURUSD, GBPUSD, AUDUSD: 'USD per foreign unit'. USDJPY, USDCAD, USDCHF: 'foreign units per USD'.

-- Buckets: sort numbers into groups.
-- calm = range under 0.005, normal = 0.005 up to 0.01, volatile = 0.01 or more
-- EXERCISE 10: For EURUSD in June 2025, show rate_date, range_pct (rounded to 4 decimals) and a bucket: calm, normal or volatile. Sort by date.



-- 20 rows (June has 20 trading days, 2025-06-19 is a holiday). Mostly calm and normal.

-- PITFALL 1: the order of the WHENs matters. Widest test FIRST.
-- If we test ">= 0.005" first, a volatile day is caught by it and called 'normal'.
-- EXERCISE 11: The mistake: put the 0.005 test BEFORE the 0.01 test. Count the EURUSD days in each bucket for the whole period.



-- only 2 rows: calm 57, normal 66. The 'volatile' bucket is missing, because it can never be reached.
-- Check your answer. If a bucket has zero rows, the order is probably wrong.

-- PITFALL 2: no ELSE means NULL.
-- EXERCISE 12: The mistake: leave out the ELSE. Show how many EURUSD days get a NULL bucket.



-- 3 rows: normal 54, volatile 12 and a NULL bucket with 57. The NULL row holds the calm days. Add ELSE 'calm' to fix it.

-- The big one: put every pair on the SAME footing.
-- usd_per_foreign = how many dollars one unit of the foreign currency buys.
--   USD-quoted pairs (EURUSD): the rate already is usd_per_foreign.
--   Everything else (USDJPY): flip it, 1.0 / rate.
-- EXERCISE 13: For 2025-06-30, show pair, rate and usd_per_foreign (rounded to 4 decimals) for all six pairs. Highest usd_per_foreign first.



-- 6 rows: GBPUSD 1.2382, EURUSD 1.0816, USDCHF 1.0722, USDCAD 0.6966, AUDUSD 0.5733, USDJPY 0.0077.
-- USDCHF, USDCAD and USDJPY were flipped (1 / rate).
-- Now all six numbers mean the same thing and you can compare them.


-- ------------------------------------------------------------
-- 3. CASE inside an aggregate, and CTE + CASE together
-- ------------------------------------------------------------
-- SUM(CASE WHEN condition THEN 1 ELSE 0 END) counts the rows that meet the condition.

-- EXERCISE 14: For each pair, show n_days and n_volatile (days with a range of 0.01 or more), in one query. Sort by pair.



-- 6 rows, 123 days each. n_volatile: AUDUSD 28, EURUSD 12, GBPUSD 21, USDCAD 5, USDCHF 10, USDJPY 23.

-- Now use both tools: CTEs hold the steps, CASE holds the decisions.
-- Step 1 (ranges): the range for every pair and day.
-- Step 2 (buckets): turn each range into calm / normal / volatile.
-- Final SELECT: one row per pair with a column per bucket.
-- EXERCISE 15: Build ranges, then buckets, then show for each pair n_calm, n_normal and n_volatile. Sort by pair.



-- 6 rows, each adding up to 123. n_calm / n_normal / n_volatile: AUDUSD 36/59/28, EURUSD 57/54/12,
-- GBPUSD 50/52/21, USDCAD 65/53/5, USDCHF 59/54/10, USDJPY 37/63/23. The n_volatile column matches exercise 14.


-- ------------------------------------------------------------
-- 4. How to troubleshoot a query
-- ------------------------------------------------------------
-- 1. What does one row of the result mean?
-- 2. How many rows SHOULD come back?
-- 3. Run COUNT(*) and compare.
-- 4. Run each CTE on its own.
-- 5. Change one thing at a time.

-- A broken query: the join is missing its key. Predict the row count first.
-- We want one row per pair per day, so we expect 738 rows.
-- EXERCISE 16: Join fx_rates to fx_pairs with a bad ON clause (p.quote_ccy = 'USD'). Count the rows. What did you expect?



-- 2214 rows, not 738. Each rate row matched all 3 USD-quoted pairs: 738 x 3 = 2214.

-- Fix: join on the key that both tables share.
-- EXERCISE 17: Fix the join (ON p.pair = r.pair) and count again.



-- 738. This now matches what we predicted.
