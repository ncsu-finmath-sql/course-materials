# Week 4 In-Class Answers: CTEs and CASE

Questions are in `week-04-ctes-case.md`. Each answer shows the query, the result, and the main thing to notice.
Other queries can be correct too. The result is what counts, not the exact wording.

---

## Easy

### Question 1: The widest EURUSD days

```sql
with eur_ranges as (
	select
		rate_date
		, (day_high - day_low) / rate as range_pct
	from fx_rates
	where
		pair = 'EURUSD'
)
select
	rate_date
	, round(range_pct, 4) as range_pct
from eur_ranges
order by range_pct desc, rate_date
limit 5;
```

| rate_date | range_pct |
|---|---|
| 2025-02-27 | 0.0127 |
| 2025-03-13 | 0.0123 |
| 2025-04-16 | 0.0123 |
| 2025-01-02 | 0.0117 |
| 2025-01-23 | 0.0116 |

- The CTE does the arithmetic once. The final `select` only sorts and trims.
- Ordering by `range_pct` (the rounded column) is fine. Ties are broken by `rate_date`.

### Question 2: Company size labels

```sql
select
	ticker
	, company_name
	, employees
	, case
		when employees >= 20000 then 'large'
		when employees >= 5000 then 'medium'
		else 'small'
	end as size_label
from companies
order by employees desc;
```

| ticker | employees | size_label |
|---|---|---|
| CRST | 52700 | large |
| BRVO | 41200 | large |
| HLIO | 26100 | large |
| ECHO | 22600 | large |
| ALPH | 18400 | medium |
| FNCH | 9800 | medium |
| GRNT | 7300 | medium |
| DLTA | 3900 | small |
| JUNO | 2150 | small |
| IOTA | 640 | small |

- The biggest cutoff goes first. 52700 passes `>= 20000` and stops there. It never reaches the medium test.

### Question 3: Active FX days

```sql
with ranges as (
	select
		pair
		, (day_high - day_low) / rate as range_pct
	from fx_rates
)
select
	pair
	, count(*) as n_active_days
from ranges
where
	range_pct >= 0.005
group by pair
order by pair;
```

| pair | n_active_days |
|---|---|
| AUDUSD | 87 |
| EURUSD | 66 |
| GBPUSD | 73 |
| USDCAD | 58 |
| USDCHF | 64 |
| USDJPY | 86 |

- `where` filters the rows first, then `group by` counts what is left.

---

## Medium

### Question 4: Up days and down days

```sql
select
	ticker
	, count(*) as n_days
	, sum(case when close_price > open_price then 1 else 0 end) as n_up_days
	, sum(case when close_price < open_price then 1 else 0 end) as n_down_days
from prices
group by ticker
order by ticker;
```

| ticker | n_days | n_up_days | n_down_days |
|---|---|---|---|
| ALPH | 123 | 61 | 61 |
| BRVO | 123 | 65 | 57 |
| CRST | 123 | 67 | 55 |
| DLTA | 123 | 58 | 65 |
| ECHO | 123 | 62 | 61 |
| FNCH | 123 | 66 | 57 |
| GRNT | 123 | 60 | 63 |
| HLIO | 123 | 74 | 49 |

- `sum(case when ... then 1 else 0 end)` counts the rows that meet a condition.
- Up plus down can be less than the days. A day where the close equals the open is in neither column. ALPH, BRVO and CRST each have one such day.

### Question 5: Dollars per foreign unit (Gemini practice)

```sql
select
	r.pair
	, case
		when p.base_ccy = 'USD' then p.quote_ccy
		else p.base_ccy
	end as foreign_ccy
	, r.rate
	, round(
		case when p.quote_ccy = 'USD' then r.rate else 1.0 / r.rate end
		, 4
	) as usd_per_foreign
from fx_rates as r
	inner join fx_pairs as p
		on p.pair = r.pair
where
	r.rate_date = '2025-03-31'
order by usd_per_foreign desc;
```

| pair | foreign_ccy | rate | usd_per_foreign |
|---|---|---|---|
| GBPUSD | GBP | 1.18214 | 1.1821 |
| EURUSD | EUR | 1.10783 | 1.1078 |
| USDCHF | CHF | 0.91207 | 1.0964 |
| USDCAD | CAD | 1.47306 | 0.6789 |
| AUDUSD | AUD | 0.58676 | 0.5868 |
| USDJPY | JPY | 137.98500 | 0.0072 |

- Two `case` expressions, two jobs: one finds the foreign currency, one flips the rate.
- **Typical Gemini slips:** it leaves out the flip (USDJPY would show 137.985), it invents a column such as `currency`, or it joins on the wrong key and returns too many rows.

### Question 6: Who gained and who lost against the dollar?

```sql
with usd_rates as (
	select
		r.pair
		, r.rate_date
		, case
			when p.quote_ccy = 'USD' then r.rate
			else 1.0 / r.rate
		end as usd_per_foreign
	from fx_rates as r
		inner join fx_pairs as p
			on p.pair = r.pair
)
, start_day as (
	select
		pair
		, usd_per_foreign as start_usd
	from usd_rates
	where
		rate_date = '2025-01-02'
)
, end_day as (
	select
		pair
		, usd_per_foreign as end_usd
	from usd_rates
	where
		rate_date = '2025-06-30'
)
select
	s.pair
	, round(s.start_usd, 4) as start_usd
	, round(e.end_usd, 4) as end_usd
	, round(e.end_usd / s.start_usd - 1, 4) as pct_change
from start_day as s
	inner join end_day as e
		on e.pair = s.pair
order by pct_change desc;
```

| pair | start_usd | end_usd | pct_change |
|---|---|---|---|
| USDJPY | 0.0064 | 0.0077 | 0.1988 |
| EURUSD | 1.0451 | 1.0816 | 0.0349 |
| USDCAD | 0.6944 | 0.6966 | 0.0033 |
| GBPUSD | 1.2559 | 1.2382 | -0.0141 |
| USDCHF | 1.1027 | 1.0722 | -0.0277 |
| AUDUSD | 0.6171 | 0.5733 | -0.0711 |

- Three steps, three names. `usd_rates` converts, `start_day` and `end_day` each pick one date, and the final `select` joins them on `pair`.
- Convert **before** comparing. Comparing the raw `USDJPY` rates would give the opposite sign.

### Question 7: Foreign exposure levels (Gemini practice)

```sql
with totals as (
	select
		ticker
		, count(*) as n_currencies
		, sum(pct_revenue) as total_foreign_pct
	from fx_exposure
	group by ticker
)
select
	t.ticker
	, c.company_name
	, t.n_currencies
	, t.total_foreign_pct
	, case
		when t.total_foreign_pct >= 25 then 'high'
		when t.total_foreign_pct >= 10 then 'medium'
		else 'low'
	end as exposure_level
from totals as t
	inner join companies as c
		on c.ticker = t.ticker
order by t.total_foreign_pct desc, t.ticker;
```

| ticker | n_currencies | total_foreign_pct | exposure_level |
|---|---|---|---|
| IOTA | 2 | 43.00 | high |
| HLIO | 2 | 41.00 | high |
| GRNT | 2 | 33.00 | high |
| ALPH | 2 | 31.00 | high |
| DLTA | 2 | 29.00 | high |
| JUNO | 2 | 27.00 | high |
| ECHO | 2 | 22.00 | medium |
| BRVO | 2 | 20.00 | medium |
| FNCH | 1 | 8.00 | low |
| CRST | 2 | 7.00 | low |

- The CTE collapses 19 rows to 10 (one per company). `case` then labels each total.
- **Typical Gemini slips:** a `case` in the wrong order (`>= 10` first would label everything at least medium), or a `case` inside `sum` that no longer produces a total.

---

## Hard

### Question 8: Foreign revenue in dollars

```sql
with foreign_revenue as (
	select
		e.ticker
		, e.ccy
		, round(f.revenue * e.pct_revenue / 100) as foreign_revenue_musd
	from fx_exposure as e
		inner join fundamentals as f
			on f.ticker = e.ticker
			and f.fiscal_year = 2025
			and f.fiscal_quarter = 1
)
select
	fr.ticker
	, c.company_name
	, fr.ccy
	, fr.foreign_revenue_musd
from foreign_revenue as fr
	inner join companies as c
		on c.ticker = fr.ticker
where
	fr.foreign_revenue_musd > 500
order by fr.foreign_revenue_musd desc;
```

| ticker | ccy | foreign_revenue_musd |
|---|---|---|
| HLIO | JPY | 3221 |
| HLIO | EUR | 1858 |
| ALPH | EUR | 1616 |
| CRST | EUR | 923 |
| ECHO | EUR | 900 |
| CRST | GBP | 692 |
| ALPH | JPY | 661 |
| BRVO | CAD | 572 |

- `fx_exposure` and `fundamentals` share `ticker`, and the fiscal year and quarter pin down one row of `fundamentals`. That keeps one row per company and currency.
- The `where ... > 500` is on the CTE's output column, so it goes in the final `select`.

### Question 9: The dollar scorecard

**(a)**

```sql
with usd_rates as (
	select
		r.pair
		, r.rate_date
		, case
			when p.quote_ccy = 'USD' then r.rate
			else 1.0 / r.rate
		end as usd_per_foreign
	from fx_rates as r
		inner join fx_pairs as p
			on p.pair = r.pair
)
, changes as (
	select
		s.pair
		, e.usd_per_foreign / s.usd_per_foreign - 1 as pct_change
	from usd_rates as s
		inner join usd_rates as e
			on e.pair = s.pair
	where
		s.rate_date = '2025-01-02'
		and e.rate_date = '2025-06-30'
)
select
	pair
	, round(pct_change, 4) as pct_change
	, case
		when pct_change < -0.01 then 'USD stronger'
		when pct_change > 0.01 then 'USD weaker'
		else 'steady'
	end as usd_trend
from changes
order by pair;
```

| pair | pct_change | usd_trend |
|---|---|---|
| AUDUSD | -0.0711 | USD stronger |
| EURUSD | 0.0349 | USD weaker |
| GBPUSD | -0.0141 | USD stronger |
| USDCAD | 0.0033 | steady |
| USDCHF | -0.0277 | USD stronger |
| USDJPY | 0.1988 | USD weaker |

**(b)**

```sql
with usd_rates as (
	select
		r.pair
		, r.rate_date
		, case
			when p.quote_ccy = 'USD' then r.rate
			else 1.0 / r.rate
		end as usd_per_foreign
	from fx_rates as r
		inner join fx_pairs as p
			on p.pair = r.pair
)
, changes as (
	select
		s.pair
		, e.usd_per_foreign / s.usd_per_foreign - 1 as pct_change
	from usd_rates as s
		inner join usd_rates as e
			on e.pair = s.pair
	where
		s.rate_date = '2025-01-02'
		and e.rate_date = '2025-06-30'
)
, trends as (
	select
		pair
		, case
			when pct_change < -0.01 then 'USD stronger'
			when pct_change > 0.01 then 'USD weaker'
			else 'steady'
		end as usd_trend
	from changes
)
select
	sum(case when usd_trend = 'USD stronger' then 1 else 0 end) as n_stronger
	, sum(case when usd_trend = 'USD weaker' then 1 else 0 end) as n_weaker
	, sum(case when usd_trend = 'steady' then 1 else 0 end) as n_steady
from trends;
```

| n_stronger | n_weaker | n_steady |
|---|---|---|
| 3 | 2 | 1 |

- Part (a) joins `usd_rates` to itself: once for the first day, once for the last. Part (b) adds one more CTE and counts with `sum(case ...)`.
- A currency that **loses** value means the **dollar** is stronger. Say it out loud once, it is easy to flip.

### Question 10: Capstone: currency headwinds and tailwinds, with a check

**(a)**

```sql
with usd_rates as (
	select
		r.pair
		, r.rate_date
		, case
			when p.base_ccy = 'USD' then p.quote_ccy
			else p.base_ccy
		end as foreign_ccy
		, case
			when p.quote_ccy = 'USD' then r.rate
			else 1.0 / r.rate
		end as usd_per_foreign
	from fx_rates as r
		inner join fx_pairs as p
			on p.pair = r.pair
)
, changes as (
	select
		s.foreign_ccy
		, e.usd_per_foreign / s.usd_per_foreign - 1 as pct_change
	from usd_rates as s
		inner join usd_rates as e
			on e.pair = s.pair
	where
		s.rate_date = '2025-01-02'
		and e.rate_date = '2025-06-30'
)
select
	x.ticker
	, x.ccy
	, x.pct_revenue
	, round(c.pct_change, 4) as pct_change
	, case
		when x.pct_revenue >= 15 and c.pct_change < -0.02 then 'headwind'
		when x.pct_revenue >= 15 and c.pct_change > 0.02 then 'tailwind'
		else 'minor'
	end as impact
from fx_exposure as x
	inner join changes as c
		on c.foreign_ccy = x.ccy
order by x.ticker, x.ccy;
```

| ticker | ccy | pct_revenue | pct_change | impact |
|---|---|---|---|---|
| ALPH | EUR | 22.00 | 0.0349 | tailwind |
| ALPH | JPY | 9.00 | 0.1988 | minor |
| BRVO | CAD | 14.00 | 0.0033 | minor |
| BRVO | EUR | 6.00 | 0.0349 | minor |
| CRST | EUR | 4.00 | 0.0349 | minor |
| CRST | GBP | 3.00 | -0.0141 | minor |
| DLTA | CAD | 18.00 | 0.0033 | minor |
| DLTA | GBP | 11.00 | -0.0141 | minor |
| ECHO | CHF | 5.00 | -0.0277 | minor |
| ECHO | EUR | 17.00 | 0.0349 | tailwind |
| FNCH | GBP | 8.00 | -0.0141 | minor |
| GRNT | AUD | 21.00 | -0.0711 | headwind |
| GRNT | CAD | 12.00 | 0.0033 | minor |
| HLIO | EUR | 15.00 | 0.0349 | tailwind |
| HLIO | JPY | 26.00 | 0.1988 | tailwind |
| IOTA | CHF | 31.00 | -0.0277 | headwind |
| IOTA | EUR | 12.00 | 0.0349 | minor |
| JUNO | EUR | 19.00 | 0.0349 | tailwind |
| JUNO | JPY | 8.00 | 0.1988 | minor |

2 headwinds (GRNT in AUD, IOTA in CHF) and 5 tailwinds (ALPH, ECHO, HLIO, HLIO, JUNO).
Big exposure is not enough. DLTA earns 18% in CAD, but CAD barely moved (0.0033), so it is `minor`.

**(b) Validate**

```sql
with usd_rates as (
	select
		r.pair
		, r.rate_date
		, case
			when p.base_ccy = 'USD' then p.quote_ccy
			else p.base_ccy
		end as foreign_ccy
		, case
			when p.quote_ccy = 'USD' then r.rate
			else 1.0 / r.rate
		end as usd_per_foreign
	from fx_rates as r
		inner join fx_pairs as p
			on p.pair = r.pair
)
, changes as (
	select
		s.foreign_ccy
		, e.usd_per_foreign / s.usd_per_foreign - 1 as pct_change
	from usd_rates as s
		inner join usd_rates as e
			on e.pair = s.pair
	where
		s.rate_date = '2025-01-02'
		and e.rate_date = '2025-06-30'
)
, result as (
	select
		x.ticker
		, x.ccy
	from fx_exposure as x
		inner join changes as c
			on c.foreign_ccy = x.ccy
)
select
	(select count(*) from fx_exposure) as n_exposure
	, (select count(*) from result) as n_result;
```

| n_exposure | n_result |
|---|---|
| 19 | 19 |

- Both are 19. The join did not lose rows (every currency has a pair) and did not add rows (every currency matches exactly one pair).
- If `n_result` were bigger, a currency would match two pairs. If smaller, a currency would have no pair.
- Validation work earns credit. A row count next to the result is the habit to keep.
