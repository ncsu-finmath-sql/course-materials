-- ============================================================
-- FIM 590 | Week 3 | JOINs: INNER, LEFT, RIGHT, FULL OUTER
-- BLANK VERSION: write each exercise live; answers are in 'Week 3 presentation notes.sql'
-- Tables:
--   prices       (ticker, trade_date, open_price, high_price, low_price,
--                 close_price, volume)                      984 rows
--   companies    (ticker, company_name, sector, industry, exchange,
--                 hq_state, listing_date, employees)         10 rows
--   fundamentals (ticker, fiscal_year, fiscal_quarter, period_end_date,
--                 report_date, revenue, net_income, eps,
--                 shares_outstanding, total_assets, total_debt,
--                 total_equity)                              60 rows
-- Money in fundamentals is in $ millions; shares in millions.
-- ============================================================


-- ------------------------------------------------------------
-- 0. Meet the new tables
-- ------------------------------------------------------------
-- EXERCISE 1: Every column of companies, sorted by ticker.



-- 10 rows. IOTA and JUNO listed after June 2025, so they have NO rows in prices.

-- EXERCISE 2: Every column of fundamentals for ALPH, in fiscal year and quarter order.



-- 6 rows: one per quarter, 2024 Q1 to 2025 Q2.

-- What is the key of each table? (one row per ...?)
--   prices:       ticker + trade_date
--   companies:    ticker
--   fundamentals: ticker + fiscal_year + fiscal_quarter
-- Knowing the key tells you how many rows a join should return.

-- Which tickers are in each table?
-- EXERCISE 3: The distinct tickers in prices, sorted.
-- Expected: 8 tickers



-- EXERCISE 4: The tickers in companies, sorted.
-- Expected: 10 tickers





-- ------------------------------------------------------------
-- 1. INNER JOIN: only rows that match on both sides
-- ------------------------------------------------------------
-- Add the company name and sector to each price row (one day only).
-- EXERCISE 5: Add company_name and sector to each price row on 2025-03-31 (INNER JOIN). Show ticker, company_name, sector, trade_date, close_price; sort by ticker.



-- 8 rows. IOTA and JUNO disappear: they have no price row to match.

-- JOIN on its own means INNER JOIN. Same 8 rows:
-- EXERCISE 6: Same join written with plain JOIN: ticker, company_name, close_price on 2025-03-31.




-- Table order does not matter for an INNER JOIN. Same 8 rows again:
-- EXERCISE 7: Same join again, but with companies first in FROM. Does the result change?




-- USING (ticker) is shorthand when the column has the same name on both sides
-- EXERCISE 8: Same join using USING (ticker) instead of ON.




-- Example: join + GROUP BY (Week 2 skills on joined data)
-- EXERCISE 9: Join prices to companies; per exchange show n_tickers (distinct) and total_volume. Highest volume first.



-- 2 rows: NYSE, NASDAQ


-- ------------------------------------------------------------
-- 2. LEFT JOIN: keep EVERY row from the left table
-- ------------------------------------------------------------
-- All 10 companies, with their price on one day if they have one.
-- EXERCISE 10: All 10 companies with their close on 2025-03-31 (LEFT JOIN; date condition in ON). Show ticker, company_name, listing_date, close_price.



-- 10 rows. IOTA and JUNO are kept, with NULL in close_price.

-- Anti-join: "which rows on the left have NO match?"
-- LEFT JOIN, then keep only rows where the right side is NULL.
-- EXERCISE 11: Anti-join: companies with NO rows in prices. Show ticker, company_name, listing_date.



-- 2 rows: IOTA, JUNO

-- Row-count check: INNER vs LEFT on the full tables
-- EXERCISE 12: Count the rows of companies INNER JOIN prices.
-- Expected: 984



-- EXERCISE 13: Count the rows of companies LEFT JOIN prices.
-- Expected: 986 (984 + 2 unmatched)




-- PITFALL: a filter on the RIGHT table belongs in ON, not WHERE.
-- Putting it in WHERE throws away the NULL rows and turns the LEFT JOIN back into an INNER JOIN.
-- EXERCISE 14: The mistake: LEFT JOIN companies to prices, but put the date filter in WHERE. Show ticker, close_price. How many rows?



-- 8 rows, not 10!

-- A filter on the LEFT table is fine in WHERE:
-- EXERCISE 15: LEFT JOIN with the date in ON, then keep only Health Care companies with WHERE. Show ticker, sector, close_price.



-- 2 rows: CRST (with a price), IOTA (NULL)

-- COALESCE replaces a NULL with a value of your choice
-- EXERCISE 16: Show 'not trading yet' instead of NULL for the 3/31 close (COALESCE).





-- ------------------------------------------------------------
-- 3. RIGHT JOIN: keep EVERY row from the right table
-- ------------------------------------------------------------
-- A RIGHT JOIN is a LEFT JOIN written the other way round.
-- These two queries return the same 10 rows:
-- EXERCISE 17: RIGHT JOIN: prices RIGHT JOIN companies, keeping all 10 companies (date in ON).




-- EXERCISE 18: The same result written as a LEFT JOIN.




-- Swap the direction and the result changes: every price row is kept,
-- but every price row has a company, so nothing new appears (8 rows).
-- EXERCISE 19: Swap the direction: companies RIGHT JOIN prices on 2025-03-31. What changes?



-- Most people write LEFT JOINs only and put the "keep everything" table first.


-- ------------------------------------------------------------
-- 4. FULL OUTER JOIN: keep every row from BOTH sides
-- ------------------------------------------------------------
-- To see it work we need rows that are unmatched on each side.
-- Two watch lists, written as subqueries in FROM:
--   List A "high-priced":  tickers that closed above $100 on 2025-06-30
--   List B "tech + health": companies in Information Technology or Health Care

-- EXERCISE 20: List A: tickers that closed above $100 on 2025-06-30 (ticker, close_price).



-- List A: ALPH, CRST, FNCH, HLIO

-- EXERCISE 21: List B: companies in Information Technology or Health Care (ticker, sector).



-- List B: ALPH, CRST, HLIO, IOTA

-- INNER: on both lists
-- EXERCISE 22: INNER JOIN list A to list B (each list as a query in FROM). Show ticker, close_price, sector.



-- 3 rows: ALPH, CRST, HLIO

-- LEFT: everything on list A
-- EXERCISE 23: LEFT JOIN list A to list B.



-- 4 rows: adds FNCH with sector NULL

-- RIGHT: everything on list B
-- EXERCISE 24: RIGHT JOIN list A to list B.



-- 4 rows: adds IOTA with close_price NULL

-- FULL OUTER: everything on either list
-- EXERCISE 25: FULL OUTER JOIN list A to list B. Use COALESCE for the ticker.



-- 5 rows: ALPH, CRST, FNCH (no sector), HLIO, IOTA (no price)
-- Why COALESCE? In a FULL OUTER JOIN either side's ticker can be NULL.

-- Summary of the four joins on these lists (A = 4 tickers, B = 4 tickers, 3 in common):
--   INNER       3   in both
--   LEFT        4   all of A
--   RIGHT       4   all of B
--   FULL OUTER  5   all of A plus all of B, overlap counted once

-- Finance use: reconciliation. "Which tickers are in one feed but not the other?"
-- EXERCISE 26: Reconciliation: only the tickers on exactly one list, with flags in_list_a and in_list_b.



-- 2 rows: FNCH (A only), IOTA (B only)


-- ------------------------------------------------------------
-- 5. Joining on more than one column
-- ------------------------------------------------------------
-- The price of each stock on the day it reported earnings:
-- match the ticker AND the date.
-- EXERCISE 27: Price on earnings day for ALPH and DLTA: join on ticker AND trade_date = report_date. Show ticker, fiscal_year, fiscal_quarter, report_date, eps, close_price, volume.



-- 4 rows: only the reports published between Jan and Jun 2025 have a price row.

-- Same thing as a LEFT JOIN: every report, price where available
-- EXERCISE 28: Same idea as a LEFT JOIN for ALPH: every report, with the price where there is one.



-- 6 rows: 4 of them have close_price NULL (reported before or after the price window)


-- ------------------------------------------------------------
-- 6. Three tables
-- ------------------------------------------------------------
-- Market cap ($ millions) on 2025-03-31 = close price x shares outstanding at quarter end
-- EXERCISE 29: Three tables: market cap ($ millions) on 2025-03-31 = close_price * shares_outstanding, using fiscal 2025 Q1. Show ticker, company_name, sector, close_price, shares_outstanding, market_cap_musd; largest first.



-- 8 rows. Each join has its own ON clause; read them top to bottom.


-- ------------------------------------------------------------
-- 7. PITFALL: incomplete join keys multiply rows (fan-out)
-- ------------------------------------------------------------
-- prices has one row per ticker-DAY, fundamentals one per ticker-QUARTER.
-- Joining on ticker alone pairs every day with every quarter:
-- EXERCISE 30: Count the rows of prices JOIN fundamentals on ticker ONLY. Predict the number first.



-- 5904 = 984 price rows x 6 quarters each. Almost certainly not what you wanted.

-- One ticker, one day: 1 price row turns into 6 rows
-- EXERCISE 31: Show the problem for one row: ALPH on 2025-03-31 joined to fundamentals on ticker only.




-- Habit: before and after every join, count rows and ask
-- "how many rows SHOULD this return, given the keys?"
-- EXERCISE 32: The fix: add the fiscal year and quarter to the join and count the rows for 2025-03-31.





-- ------------------------------------------------------------
-- 8. CROSS JOIN (every combination) -- know it exists
-- ------------------------------------------------------------
-- EXERCISE 33: CROSS JOIN companies with the distinct fiscal quarters. How many rows?



-- 40 rows = 10 companies x 4 quarters. The fan-out in section 7 is an accidental cross join.
