# Week 6 In-Class Answers: Window Functions

Every query below was run against the course data. Different correct queries are fine.

**Post after class.** Students should write their own queries first.

---

## Easy (questions 1-3)

### Question 1: Day-to-day changes for DLTA

```sql
with d as (
	select
		trade_date
		, close_price
		, lag(close_price) over (partition by ticker order by trade_date) as prev_close
	from prices
	where
		ticker = 'DLTA'
)
select
	trade_date
	, prev_close
	, close_price
	, round(close_price - prev_close, 2) as change_usd
from d
where
	trade_date between date '2025-03-03' and date '2025-03-07'
order by trade_date;
```

**Result:** 5 rows. The biggest rise is on 2025-03-06 (+0.59); the biggest fall is on 2025-03-07 (-0.55).

### Question 2: Number the trading days

```sql
with n as (
	select
		trade_date
		, row_number() over (order by trade_date) as day_no
	from prices
	where
		ticker = 'GRNT'
)
select
	trade_date
	, day_no
from n
where
	trade_date >= date '2025-03-01'
	and trade_date < date '2025-04-01'
order by trade_date;
```

**Result:** 21 rows. March 3 is day 41 and March 31 is day 61. The numbering runs over the whole history, so 2025-01-02 is day 1.

### Question 3: Running volume

```sql
select
	trade_date
	, running_volume
from (
	select
		trade_date
		, sum(volume) over (order by trade_date rows between unbounded preceding and current row) as running_volume
	from prices
	where
		ticker = 'BRVO'
)
where
	trade_date = date '2025-01-31';
```

**Result:** 1 row, running_volume 217148650.

---

## Medium (questions 4-6)

### Question 4: A 10-day moving average

```sql
with m as (
	select
		trade_date
		, close_price
		, round(avg(close_price) over (
			order by trade_date
			rows between 9 preceding and current row
		), 2) as ma10
	from prices
	where
		ticker = 'ECHO'
)
select
	trade_date
	, close_price
	, ma10
from m
where
	trade_date between date '2025-04-14' and date '2025-04-17'
order by trade_date;
```

**Result:** 4 rows. On 2025-04-15 the 10-day average is 83.87. Filtering before the window would shrink the window on 2025-04-14 to a single row, so the filter goes last.

### Question 5: The biggest one-day rise for each ticker (Gemini practice)

```sql
with r as (
	select
		ticker
		, trade_date
		, round((close_price * 1.0 / lag(close_price) over (partition by ticker order by trade_date) - 1) * 100, 2) as ret_pct
	from prices
), k as (
	select
		ticker
		, trade_date
		, ret_pct
		, row_number() over (partition by ticker order by ret_pct desc) as rn
	from r
	where
		ret_pct is not null
)
select
	ticker
	, trade_date
	, ret_pct
from k
where
	rn = 1
order by ret_pct desc, ticker;
```

**Result:** 8 rows. GRNT first (+8.17% on 2025-03-20), ALPH last (+3.48% on 2025-03-31).

**Watch for in Gemini's answer:** `rank()` where `row_number()` is wanted. With a tie on the largest rise, `rank()` returns two rows for one ticker, and the answer then has more than 8 rows. Also check that the first day of each ticker (which has no return) is excluded.

### Question 6: Who traded the most on one day?

```sql
select
	ticker
	, volume
	, rank() over (order by volume desc) as volume_rank
from prices
where
	trade_date = date '2025-05-30'
order by volume_rank, ticker;
```

**Result:** 8 rows. DLTA first with 14,386,765 shares; CRST last with 1,000,925.

---

## Hard (questions 7-8)

### Question 7: The longest winning streak (Gemini practice)

```sql
with u as (
	select
		ticker
		, trade_date
		, case
			when close_price > lag(close_price) over (partition by ticker order by trade_date) then 1
			else 0
		end as up_day
	from prices
), g as (
	select
		ticker
		, trade_date
		, up_day
		, row_number() over (partition by ticker order by trade_date)
			- row_number() over (partition by ticker, up_day order by trade_date) as island
	from u
), s as (
	select
		ticker
		, island
		, count(*) as streak
	from g
	where
		up_day = 1
	group by ticker, island
)
select
	ticker
	, max(streak) as longest_up_streak
from s
group by ticker
order by longest_up_streak desc, ticker;
```

**Result:** 8 rows. BRVO first with 9 winning days in a row; DLTA last with 4. Checked against a plain Python loop over the CSV.

**Why it works:** within a run of winning days, both row numbers go up by one each day, so their difference stays constant. That constant names the run.

**Watch for in Gemini's answer:** counting all days instead of winning days only; a `lag` that is not partitioned by ticker (the first day of BRVO would then be compared with the last day of ALPH); and a streak that breaks on a losing day but is not reset.

### Question 8: Above or below the 20-day average?

```sql
with m as (
	select
		ticker
		, trade_date
		, close_price
		, avg(close_price) over (
			partition by ticker
			order by trade_date
			rows between 19 preceding and current row
		) as ma20
	from prices
)
select
	ticker
	, close_price
	, round(ma20, 2) as ma20
	, case
		when close_price > ma20 then 'above'
		else 'below'
	end as position
from m
where
	trade_date = date '2025-06-30'
order by ticker;
```

**Result:** 8 rows. ALPH, CRST and HLIO are above their 20-day average; the other five are below. HLIO's 20-day average is 488.63 and its close is 504.21.
