-- ARK public funds: short WRDS / PostgreSQL classroom queries.
-- Highlight ONE query in VS Code, then run it with F5.
-- Field names and queries checked against live WRDS on November 8, 2026.
-- Historical illustration prompted by the FT interval-fund article:
-- https://www.ft.com/content/dce2b9da-a4c6-4016-af78-7c41ac41a6b0
-- These queries study existing public ETFs, not the proposed interval fund.
-- Holdings examples use 2026-09-30, the latest month-end with snapshots for
-- all five funds (checked live on November 8, 2026). Monthly returns and
-- assets also run through 2026-09-30.
-- Holdings weights are percentage points; mret is a decimal return.
-- TNA and estimated flows are in USD millions for these US funds.
-- Expense ratios are decimal fractions: 0.0075 = 0.75%.
-- fund_hdr supplies current fund-to-portfolio mappings. Check query 1 first;
-- if a mapping changed, use dated crsp.portnomap records for that period.


-- 1. Find five ARK ETFs and their two different identifiers.
-- crsp_fundno joins to fund returns, fees, and assets.
-- crsp_portno joins to portfolio holdings.
select
	ticker
	, fund_name
	, crsp_fundno
	, crsp_portno
from crsp.fund_hdr
where
	ticker in ('ARKK', 'ARKW', 'ARKG', 'ARKQ', 'ARKF')
order by ticker;


-- 2. Which holdings snapshots are available for ARKK?
-- If necessary, replace the report date in queries 3-6 with an available date.
-- For overlap, BOTH funds must have that same report date.
select distinct
	h.report_dt
from crsp.fund_hdr as f
	inner join crsp.holdings as h
		on f.crsp_portno = h.crsp_portno
where
	f.ticker = 'ARKK'
order by h.report_dt desc
limit 12;


-- 3. What are ARKK's ten largest reported holdings?
select
	h.report_dt
	, h.security_name
	, h.ticker
	, h.percent_tna as portfolio_weight_pct
from crsp.fund_hdr as f
	inner join crsp.holdings as h
		on f.crsp_portno = h.crsp_portno
where
	f.ticker = 'ARKK'
	and h.report_dt = date '2026-09-30'
order by h.percent_tna desc nulls last
limit 10;


-- 4. How concentrated are the five portfolios?
-- Top-ten weight = sum of the ten largest reported position weights.
-- CRSP already supplies security_rank, so no window function is needed.
-- Only funds with holdings on the chosen date will appear.
select
	f.ticker
	, sum(h.percent_tna) as top_ten_weight_pct
from crsp.fund_hdr as f
	inner join crsp.holdings as h
		on f.crsp_portno = h.crsp_portno
where
	f.ticker in ('ARKK', 'ARKW', 'ARKG', 'ARKQ', 'ARKF')
	and h.report_dt = date '2026-09-30'
	and h.security_rank <= 10
group by f.ticker
order by top_ten_weight_pct desc;


-- 5. Which securities do ARKK and ARKW hold in common?
-- Compare securities by CUSIP, rather than by potentially ambiguous ticker.
-- Each CTE selects one portfolio snapshot before the two snapshots are joined.
with arkk as (
	select
		h.cusip
		, h.security_name
		, h.percent_tna
	from crsp.fund_hdr as f
		inner join crsp.holdings as h
			on f.crsp_portno = h.crsp_portno
	where
		f.ticker = 'ARKK'
		and h.report_dt = date '2026-09-30'
)
, arkw as (
	select
		h.cusip
		, h.percent_tna
	from crsp.fund_hdr as f
		inner join crsp.holdings as h
			on f.crsp_portno = h.crsp_portno
	where
		f.ticker = 'ARKW'
		and h.report_dt = date '2026-09-30'
)
select
	a.security_name
	, a.percent_tna as arkk_weight_pct
	, b.percent_tna as arkw_weight_pct
	, least(a.percent_tna, b.percent_tna) as shared_weight_pct
from arkk as a
	inner join arkw as b
		on a.cusip = b.cusip
order by shared_weight_pct desc;

-- Summing shared_weight_pct gives a security-level weighted-overlap measure.
-- Inspect coverage and duplicate CUSIPs before interpreting that sum. This
-- matches securities, not different share classes issued by the same company.


-- 6. Show the reported weight covered by each snapshot.
-- This helps distinguish a concentrated fund from an incomplete snapshot.
select
	f.ticker
	, count(*) as reported_positions
	, sum(h.percent_tna) as reported_total_weight_pct
from crsp.fund_hdr as f
	inner join crsp.holdings as h
		on f.crsp_portno = h.crsp_portno
where
	f.ticker in ('ARKK', 'ARKW', 'ARKG', 'ARKQ', 'ARKF')
	and h.report_dt = date '2026-09-30'
group by f.ticker
order by f.ticker;


-- 7. What expense ratios are recorded for ARKK?
-- Keep the raw CRSP value and show its percentage conversion: 0.0075 = 0.75%.
-- Do not sum these historical fee records.
select
	f.ticker
	, e.fiscal_yearend
	, e.begdt
	, e.enddt
	, e.exp_ratio
	, 100 * e.exp_ratio as expense_ratio_pct
from crsp.fund_hdr as f
	inner join crsp.fund_fees as e
		on f.crsp_fundno = e.crsp_fundno
where
	f.ticker = 'ARKK'
order by e.fiscal_yearend desc nulls last, e.begdt desc
limit 10;


-- 8. Compare monthly returns and month-end fund assets, Oct 2025 - Sep 2026.
-- The combined CRSP table avoids a separate returns-to-assets join.
-- Missing/negative sentinel values are excluded rather than treated as zero.
select
	f.ticker
	, m.caldt
	, 100 * m.mret as monthly_return_pct
	, m.mtna as assets_millions
from crsp.fund_hdr as f
	inner join crsp.monthly_tna_ret_nav as m
		on f.crsp_fundno = m.crsp_fundno
where
	f.ticker in ('ARKK', 'ARKW', 'ARKG', 'ARKQ', 'ARKF')
	and m.caldt between date '2025-10-01' and date '2026-09-30'
	and m.mret >= -1
	and m.mtna >= 0
order by f.ticker, m.caldt;


-- 9. Estimate monthly investor flows into/out of ARKK, Oct 2025 - Sep 2026.
-- Estimated flow = ending assets - beginning assets * (1 + monthly return).
-- A decline in assets can reflect investment losses as well as withdrawals.
-- Include September 2025 so October 2025 has a beginning-assets observation.
-- This is the only query that needs LAG and a CTE.
with monthly as (
	select
		m.caldt
		, m.mtna
		, m.mret
		, lag(m.mtna) over (order by m.caldt) as previous_tna
		, lag(m.caldt) over (order by m.caldt) as previous_date
	from crsp.fund_hdr as f
		inner join crsp.monthly_tna_ret_nav as m
			on f.crsp_fundno = m.crsp_fundno
	where
		f.ticker = 'ARKK'
		and m.caldt between date '2025-09-01' and date '2026-09-30'
)
select
	caldt
	, mtna as assets_millions
	, 100 * mret as monthly_return_pct
	, mtna - previous_tna * (1 + mret) as estimated_flow_millions
from monthly
where
	caldt >= date '2025-10-01'
	and mtna >= 0
	and previous_tna > 0
	and mret >= -1
	and date_trunc('month', caldt)
		= date_trunc('month', previous_date) + interval '1 month'
order by caldt;

-- Flow assumes end-of-month flows. Mergers and other non-flow asset changes
-- can affect the estimate. It is an estimate, not observed subscriptions.
-- The holdings exercise describes reported snapshots; information was only
-- available from eff_dt, so do not treat report_dt as a backtest release date.
