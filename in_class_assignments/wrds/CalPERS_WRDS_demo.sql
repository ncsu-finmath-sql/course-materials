-- CalPERS institutional holdings: short WRDS / PostgreSQL queries.
-- Highlight ONE query at a time in VS Code, then press F5.
-- Queries checked against live WRDS on November 8, 2026.
-- The discovery query confirmed CalPERS manager ID 12000.
-- The latest five quarters (2025-03-31 to 2026-03-31) had no duplicate
-- manager/date/CUSIP keys.
-- FT discussion prompt:
-- https://www.ft.com/content/e842173f-6f9f-4115-9e5f-a0f06f0df18d
-- These historical examples do not reproduce the article's 2026 episode.
-- Start by confirming the manager identity and available dates below.
-- Query 1 retains the original name search; subsequent queries use the
-- verified numeric manager ID, avoiding repeated broad name scans.
-- Do not combine unrelated managers or CalSTRS (the teachers' system).


-- 1. Find CalPERS's recorded name and manager ID.
select distinct
	mgrno
	, mgrname
from tr_13f.s34
where
	mgrname ilike '%CALIF%PUBLIC%EMP%'
	or mgrname ilike '%CALPERS%'
order by mgrno, mgrname;

-- If no result, try a broader discovery search:
-- select distinct
-- 	mgrno
-- 	, mgrname
-- from tr_13f.s34
-- where
-- 	mgrname ilike '%CALIF%'
-- order by mgrname;


-- 2. Which report dates are available?
-- Dates below count source rows, not deduplicated securities.
-- Pick TWO adjacent calendar quarters that both have complete coverage.
select
	mgrno
	, rdate
	, count(*) as source_rows
from tr_13f.s34
where
	mgrno = 12000
group by mgrno, rdate
order by rdate desc, mgrno
limit 20;


-- 3. Inspect holdings for one quarter before doing any calculations.
-- Change this date and the dates in queries 4-5 if needed after query 2.
-- fdate is retained as the vendor's vintage date. Check its exact definition
-- in the current S34 dictionary; do not assume it is SEC receipt time.
-- shares and prc are shown raw. Confirm units and the price reference date
-- before using shares * prc as a quarter-end market value.
select
	mgrno
	, mgrname
	, rdate
	, fdate
	, stkname
	, ticker
	, cusip
	, shares
	, prc
from tr_13f.s34
where
	mgrno = 12000
	and rdate = date '2026-03-31'
order by stkname, cusip, fdate;


-- 4. Are there multiple rows for the same manager/security/report date?
-- No rows means no duplicate keys in this two-quarter sample.
-- Inspect any duplicates before using the latest-vintage policy in query 5.
select
	mgrno
	, rdate
	, cusip
	, count(*) as source_rows
	, count(distinct fdate) as distinct_vintages
from tr_13f.s34
where
	mgrno = 12000
	and rdate in (date '2025-12-31', date '2026-03-31')
group by mgrno, rdate, cusip
having count(*) > 1
order by mgrno, rdate, cusip;


-- 5. Did reported shares rise or fall between the two quarters?
-- DISTINCT ON is PostgreSQL syntax: choose the latest fdate for each key.
-- Policy: latest available vendor vintage, not a point-in-time backtest.
-- If query 4 finds conflicting rows with identical fdate, resolve those
-- first; ordering only by fdate cannot distinguish tied versions.
-- CUSIP joins avoid the four-character limit on the S34 ticker field.
with holdings as (
	select distinct on (mgrno, rdate, cusip)
		mgrno
		, rdate
		, fdate
		, cusip
		, stkname
		, ticker
		, shares
	from tr_13f.s34
	where
		mgrno = 12000
		and rdate in (date '2025-12-31', date '2026-03-31')
		and cusip is not null
	order by mgrno, rdate, cusip, fdate desc nulls last
)
, previous_quarter as (
	select *
	from holdings
	where
		rdate = date '2025-12-31'
)
, current_quarter as (
	select *
	from holdings
	where
		rdate = date '2026-03-31'
)
select
	coalesce(c.mgrno, p.mgrno) as manager_id
	, coalesce(c.stkname, p.stkname) as company
	, coalesce(c.cusip, p.cusip) as cusip
	, p.shares as previous_shares
	, c.shares as current_shares
	, case
		when p.cusip is null then 'Appeared in report'
		when c.cusip is null then 'Absent from report'
		when c.shares > p.shares then 'Reported shares increased'
		when c.shares < p.shares then 'Reported shares decreased'
		when c.shares = p.shares then 'Unchanged'
		else 'Missing shares'
	end as comparison
	, c.shares - p.shares as share_change
from previous_quarter as p
	full outer join current_quarter as c
		on p.mgrno = c.mgrno
		and p.cusip = c.cusip
order by company, cusip;

-- Missing positions stay NULL rather than being automatically counted as
-- purchases or sales. First establish that both reports are complete.
-- Even continuing positions need corporate-action checks: stock splits,
-- mergers, and CUSIP changes can alter reported shares without a trade.
-- This comparison describes holdings; it does not identify trade dates.


-- 6. Simplest single-company example: Microsoft's reported holdings.
-- This raw history keeps fdate visible so multiple versions are apparent.
-- MSFT fits in the four-character ticker column; longer tickers may not.
select
	rdate
	, fdate
	, shares
	, prc
from tr_13f.s34
where
	mgrno = 12000
	and ticker = 'MSFT'
	and rdate between date '2025-01-01' and date '2026-03-31'
order by rdate, fdate;

-- Teaching question: did CalPERS reduce reported shares, or did the price
-- of an unchanged holding fall? A decline in dollar value alone cannot
-- establish selling. After checking units/price dates and corporate actions,
-- a two-date value decomposition for continuing positions is:
--   share effect = (shares_new - shares_old) * price_old
--   price effect = shares_new * (price_new - price_old)
-- Their sum equals the change in shares * price under those conventions.
-- 13F coverage is only part of CalPERS's total portfolio, and disclosures
-- arrive after the report date. Do not treat quarter-end data as available
-- to investors on that same date.
