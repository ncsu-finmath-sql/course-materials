-- ============================================================
-- FIM 590 | Week 3 | JOINs: INNER, LEFT, RIGHT, FULL OUTER
-- ANSWER VERSION: matches the exercise numbers in 'Week 3 presentation notes - blank.sql'
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
SELECT *
FROM companies
ORDER BY ticker;
-- 10 rows. IOTA and JUNO listed after June 2025, so they have NO rows in prices.

-- EXERCISE 2: Every column of fundamentals for ALPH, in fiscal year and quarter order.
SELECT *
FROM fundamentals
WHERE ticker = 'ALPH'
ORDER BY fiscal_year, fiscal_quarter;
-- 6 rows: one per quarter, 2024 Q1 to 2025 Q2.

-- What is the key of each table? (one row per ...?)
--   prices:       ticker + trade_date
--   companies:    ticker
--   fundamentals: ticker + fiscal_year + fiscal_quarter
-- Knowing the key tells you how many rows a join should return.

-- Which tickers are in each table?
-- EXERCISE 3: The distinct tickers in prices, sorted.
SELECT DISTINCT ticker FROM prices ORDER BY ticker;         -- 8 tickers
-- EXERCISE 4: The tickers in companies, sorted.
SELECT ticker FROM companies ORDER BY ticker;               -- 10 tickers


-- ------------------------------------------------------------
-- 1. INNER JOIN: only rows that match on both sides
-- ------------------------------------------------------------
-- Add the company name and sector to each price row (one day only).
-- EXERCISE 5: Add company_name and sector to each price row on 2025-03-31 (INNER JOIN). Show ticker, company_name, sector, trade_date, close_price; sort by ticker.
SELECT p.ticker, c.company_name, c.sector, p.trade_date, p.close_price
FROM prices AS p
INNER JOIN companies AS c
        ON c.ticker = p.ticker
WHERE p.trade_date = '2025-03-31'
ORDER BY p.ticker;
-- 8 rows. IOTA and JUNO disappear: they have no price row to match.

-- JOIN on its own means INNER JOIN. Same 8 rows:
-- EXERCISE 6: Same join written with plain JOIN: ticker, company_name, close_price on 2025-03-31.
SELECT p.ticker, c.company_name, p.close_price
FROM prices p
JOIN companies c ON c.ticker = p.ticker
WHERE p.trade_date = '2025-03-31';

-- Table order does not matter for an INNER JOIN. Same 8 rows again:
-- EXERCISE 7: Same join again, but with companies first in FROM. Does the result change?
SELECT p.ticker, c.company_name, p.close_price
FROM companies c
JOIN prices p ON p.ticker = c.ticker
WHERE p.trade_date = '2025-03-31';

-- USING (ticker) is shorthand when the column has the same name on both sides
-- EXERCISE 8: Same join using USING (ticker) instead of ON.
SELECT ticker, company_name, close_price
FROM prices
JOIN companies USING (ticker)
WHERE trade_date = '2025-03-31';

-- Example: join + GROUP BY (Week 2 skills on joined data)
-- EXERCISE 9: Join prices to companies; per exchange show n_tickers (distinct) and total_volume. Highest volume first.
SELECT c.exchange,
       COUNT(DISTINCT p.ticker)  AS n_tickers,
       SUM(p.volume)             AS total_volume
FROM prices p
JOIN companies c ON c.ticker = p.ticker
GROUP BY c.exchange
ORDER BY total_volume DESC;
-- 2 rows: NYSE, NASDAQ


-- ------------------------------------------------------------
-- 2. LEFT JOIN: keep EVERY row from the left table
-- ------------------------------------------------------------
-- All 10 companies, with their price on one day if they have one.
-- EXERCISE 10: All 10 companies with their close on 2025-03-31 (LEFT JOIN; date condition in ON). Show ticker, company_name, listing_date, close_price.
SELECT c.ticker, c.company_name, c.listing_date, p.close_price
FROM companies c
LEFT JOIN prices p
       ON p.ticker = c.ticker
      AND p.trade_date = '2025-03-31'
ORDER BY c.ticker;
-- 10 rows. IOTA and JUNO are kept, with NULL in close_price.

-- Anti-join: "which rows on the left have NO match?"
-- LEFT JOIN, then keep only rows where the right side is NULL.
-- EXERCISE 11: Anti-join: companies with NO rows in prices. Show ticker, company_name, listing_date.
SELECT c.ticker, c.company_name, c.listing_date
FROM companies c
LEFT JOIN prices p ON p.ticker = c.ticker
WHERE p.ticker IS NULL;
-- 2 rows: IOTA, JUNO

-- Row-count check: INNER vs LEFT on the full tables
-- EXERCISE 12: Count the rows of companies INNER JOIN prices.
SELECT COUNT(*) AS n_rows FROM companies c JOIN      prices p ON p.ticker = c.ticker;   -- 984
-- EXERCISE 13: Count the rows of companies LEFT JOIN prices.
SELECT COUNT(*) AS n_rows FROM companies c LEFT JOIN prices p ON p.ticker = c.ticker;   -- 986 (984 + 2 unmatched)

-- PITFALL: a filter on the RIGHT table belongs in ON, not WHERE.
-- Putting it in WHERE throws away the NULL rows and turns the LEFT JOIN back into an INNER JOIN.
-- EXERCISE 14: The mistake: LEFT JOIN companies to prices, but put the date filter in WHERE. Show ticker, close_price. How many rows?
SELECT c.ticker, p.close_price
FROM companies c
LEFT JOIN prices p ON p.ticker = c.ticker
WHERE p.trade_date = '2025-03-31'      -- NULL = '2025-03-31' is not true, so IOTA/JUNO are dropped
ORDER BY c.ticker;
-- 8 rows, not 10!

-- A filter on the LEFT table is fine in WHERE:
-- EXERCISE 15: LEFT JOIN with the date in ON, then keep only Health Care companies with WHERE. Show ticker, sector, close_price.
SELECT c.ticker, c.sector, p.close_price
FROM companies c
LEFT JOIN prices p ON p.ticker = c.ticker AND p.trade_date = '2025-03-31'
WHERE c.sector = 'Health Care'
ORDER BY c.ticker;
-- 2 rows: CRST (with a price), IOTA (NULL)

-- COALESCE replaces a NULL with a value of your choice
-- EXERCISE 16: Show 'not trading yet' instead of NULL for the 3/31 close (COALESCE).
SELECT c.ticker,
       COALESCE(CAST(p.close_price AS VARCHAR), 'not trading yet') AS close_on_mar_31
FROM companies c
LEFT JOIN prices p ON p.ticker = c.ticker AND p.trade_date = '2025-03-31'
ORDER BY c.ticker;


-- ------------------------------------------------------------
-- 3. RIGHT JOIN: keep EVERY row from the right table
-- ------------------------------------------------------------
-- A RIGHT JOIN is a LEFT JOIN written the other way round.
-- These two queries return the same 10 rows:
-- EXERCISE 17: RIGHT JOIN: prices RIGHT JOIN companies, keeping all 10 companies (date in ON).
SELECT c.ticker, c.company_name, p.close_price
FROM prices p
RIGHT JOIN companies c
        ON c.ticker = p.ticker
       AND p.trade_date = '2025-03-31'
ORDER BY c.ticker;

-- EXERCISE 18: The same result written as a LEFT JOIN.
SELECT c.ticker, c.company_name, p.close_price
FROM companies c
LEFT JOIN prices p
       ON p.ticker = c.ticker
      AND p.trade_date = '2025-03-31'
ORDER BY c.ticker;

-- Swap the direction and the result changes: every price row is kept,
-- but every price row has a company, so nothing new appears (8 rows).
-- EXERCISE 19: Swap the direction: companies RIGHT JOIN prices on 2025-03-31. What changes?
SELECT p.ticker, c.company_name, p.close_price
FROM companies c
RIGHT JOIN prices p ON p.ticker = c.ticker
WHERE p.trade_date = '2025-03-31'
ORDER BY p.ticker;
-- Most people write LEFT JOINs only and put the "keep everything" table first.


-- ------------------------------------------------------------
-- 4. FULL OUTER JOIN: keep every row from BOTH sides
-- ------------------------------------------------------------
-- To see it work we need rows that are unmatched on each side.
-- Two watch lists, written as subqueries in FROM:
--   List A "high-priced":  tickers that closed above $100 on 2025-06-30
--   List B "tech + health": companies in Information Technology or Health Care

-- EXERCISE 20: List A: tickers that closed above $100 on 2025-06-30 (ticker, close_price).
SELECT ticker, close_price
FROM prices
WHERE trade_date = '2025-06-30' AND close_price > 100;
-- List A: ALPH, CRST, FNCH, HLIO

-- EXERCISE 21: List B: companies in Information Technology or Health Care (ticker, sector).
SELECT ticker, sector
FROM companies
WHERE sector IN ('Information Technology', 'Health Care');
-- List B: ALPH, CRST, HLIO, IOTA

-- INNER: on both lists
-- EXERCISE 22: INNER JOIN list A to list B (each list as a query in FROM). Show ticker, close_price, sector.
SELECT a.ticker, a.close_price, b.sector
FROM (SELECT ticker, close_price FROM prices
      WHERE trade_date = '2025-06-30' AND close_price > 100) AS a
INNER JOIN
     (SELECT ticker, sector FROM companies
      WHERE sector IN ('Information Technology', 'Health Care')) AS b
  ON b.ticker = a.ticker
ORDER BY a.ticker;
-- 3 rows: ALPH, CRST, HLIO

-- LEFT: everything on list A
-- EXERCISE 23: LEFT JOIN list A to list B.
SELECT a.ticker, a.close_price, b.sector
FROM (SELECT ticker, close_price FROM prices
      WHERE trade_date = '2025-06-30' AND close_price > 100) AS a
LEFT JOIN
     (SELECT ticker, sector FROM companies
      WHERE sector IN ('Information Technology', 'Health Care')) AS b
  ON b.ticker = a.ticker
ORDER BY a.ticker;
-- 4 rows: adds FNCH with sector NULL

-- RIGHT: everything on list B
-- EXERCISE 24: RIGHT JOIN list A to list B.
SELECT b.ticker, a.close_price, b.sector
FROM (SELECT ticker, close_price FROM prices
      WHERE trade_date = '2025-06-30' AND close_price > 100) AS a
RIGHT JOIN
     (SELECT ticker, sector FROM companies
      WHERE sector IN ('Information Technology', 'Health Care')) AS b
  ON b.ticker = a.ticker
ORDER BY b.ticker;
-- 4 rows: adds IOTA with close_price NULL

-- FULL OUTER: everything on either list
-- EXERCISE 25: FULL OUTER JOIN list A to list B. Use COALESCE for the ticker.
SELECT COALESCE(a.ticker, b.ticker) AS ticker,
       a.close_price,
       b.sector
FROM (SELECT ticker, close_price FROM prices
      WHERE trade_date = '2025-06-30' AND close_price > 100) AS a
FULL OUTER JOIN
     (SELECT ticker, sector FROM companies
      WHERE sector IN ('Information Technology', 'Health Care')) AS b
  ON b.ticker = a.ticker
ORDER BY ticker;
-- 5 rows: ALPH, CRST, FNCH (no sector), HLIO, IOTA (no price)
-- Why COALESCE? In a FULL OUTER JOIN either side's ticker can be NULL.

-- Summary of the four joins on these lists (A = 4 tickers, B = 4 tickers, 3 in common):
--   INNER       3   in both
--   LEFT        4   all of A
--   RIGHT       4   all of B
--   FULL OUTER  5   all of A plus all of B, overlap counted once

-- Finance use: reconciliation. "Which tickers are in one feed but not the other?"
-- EXERCISE 26: Reconciliation: only the tickers on exactly one list, with flags in_list_a and in_list_b.
SELECT COALESCE(a.ticker, b.ticker) AS ticker,
       a.ticker IS NOT NULL         AS in_list_a,
       b.ticker IS NOT NULL         AS in_list_b
FROM (SELECT ticker FROM prices
      WHERE trade_date = '2025-06-30' AND close_price > 100) AS a
FULL OUTER JOIN
     (SELECT ticker FROM companies
      WHERE sector IN ('Information Technology', 'Health Care')) AS b
  ON b.ticker = a.ticker
WHERE a.ticker IS NULL OR b.ticker IS NULL;
-- 2 rows: FNCH (A only), IOTA (B only)


-- ------------------------------------------------------------
-- 5. Joining on more than one column
-- ------------------------------------------------------------
-- The price of each stock on the day it reported earnings:
-- match the ticker AND the date.
-- EXERCISE 27: Price on earnings day for ALPH and DLTA: join on ticker AND trade_date = report_date. Show ticker, fiscal_year, fiscal_quarter, report_date, eps, close_price, volume.
SELECT f.ticker, f.fiscal_year, f.fiscal_quarter, f.report_date,
       f.eps, p.close_price, p.volume
FROM fundamentals f
JOIN prices p
  ON p.ticker = f.ticker
 AND p.trade_date = f.report_date
WHERE f.ticker IN ('ALPH', 'DLTA')
ORDER BY f.ticker, f.report_date;
-- 4 rows: only the reports published between Jan and Jun 2025 have a price row.

-- Same thing as a LEFT JOIN: every report, price where available
-- EXERCISE 28: Same idea as a LEFT JOIN for ALPH: every report, with the price where there is one.
SELECT f.ticker, f.fiscal_year, f.fiscal_quarter, f.report_date, p.close_price
FROM fundamentals f
LEFT JOIN prices p
       ON p.ticker = f.ticker
      AND p.trade_date = f.report_date
WHERE f.ticker = 'ALPH'
ORDER BY f.report_date;
-- 6 rows: 4 of them have close_price NULL (reported before or after the price window)


-- ------------------------------------------------------------
-- 6. Three tables
-- ------------------------------------------------------------
-- Market cap ($ millions) on 2025-03-31 = close price x shares outstanding at quarter end
-- EXERCISE 29: Three tables: market cap ($ millions) on 2025-03-31 = close_price * shares_outstanding, using fiscal 2025 Q1. Show ticker, company_name, sector, close_price, shares_outstanding, market_cap_musd; largest first.
SELECT c.ticker, c.company_name, c.sector,
       p.close_price,
       f.shares_outstanding,
       ROUND(p.close_price * f.shares_outstanding) AS market_cap_musd
FROM companies c
JOIN prices p
  ON p.ticker = c.ticker AND p.trade_date = '2025-03-31'
JOIN fundamentals f
  ON f.ticker = c.ticker AND f.fiscal_year = 2025 AND f.fiscal_quarter = 1
ORDER BY market_cap_musd DESC;
-- 8 rows. Each join has its own ON clause; read them top to bottom.


-- ------------------------------------------------------------
-- 7. PITFALL: incomplete join keys multiply rows (fan-out)
-- ------------------------------------------------------------
-- prices has one row per ticker-DAY, fundamentals one per ticker-QUARTER.
-- Joining on ticker alone pairs every day with every quarter:
-- EXERCISE 30: Count the rows of prices JOIN fundamentals on ticker ONLY. Predict the number first.
SELECT COUNT(*) AS n_rows
FROM prices p
JOIN fundamentals f ON f.ticker = p.ticker;
-- 5904 = 984 price rows x 6 quarters each. Almost certainly not what you wanted.

-- One ticker, one day: 1 price row turns into 6 rows
-- EXERCISE 31: Show the problem for one row: ALPH on 2025-03-31 joined to fundamentals on ticker only.
SELECT p.ticker, p.trade_date, p.close_price, f.fiscal_year, f.fiscal_quarter
FROM prices p
JOIN fundamentals f ON f.ticker = p.ticker
WHERE p.ticker = 'ALPH' AND p.trade_date = '2025-03-31';

-- Habit: before and after every join, count rows and ask
-- "how many rows SHOULD this return, given the keys?"
-- EXERCISE 32: The fix: add the fiscal year and quarter to the join and count the rows for 2025-03-31.
SELECT COUNT(*) AS n_rows                                     -- expect 8: one per priced ticker
FROM prices p
JOIN fundamentals f
  ON f.ticker = p.ticker AND f.fiscal_year = 2025 AND f.fiscal_quarter = 1
WHERE p.trade_date = '2025-03-31';


-- ------------------------------------------------------------
-- 8. CROSS JOIN (every combination) -- know it exists
-- ------------------------------------------------------------
-- EXERCISE 33: CROSS JOIN companies with the distinct fiscal quarters. How many rows?
SELECT c.ticker, q.fiscal_quarter
FROM companies c
CROSS JOIN (SELECT DISTINCT fiscal_quarter FROM fundamentals) AS q
ORDER BY c.ticker, q.fiscal_quarter;
-- 40 rows = 10 companies x 4 quarters. The fan-out in section 7 is an accidental cross join.
