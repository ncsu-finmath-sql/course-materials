# Review: Sessions 1–6 (Answers)

**Course:** FIM 590, Data Analytics with SQL

These are the answers to `review-sessions-1-6.md`. Try each question yourself before reading the answer.

The queries were run in DuckDB against the course dataset. Money in the fundamentals table is in $ millions and shares in millions. Accrued interest uses the simplified convention from Week 5 (`coupon_rate × days / 365`), not 30/360. Your results may be formatted differently but should match these values.

## Topic 1: Pulling and sanity-checking market data

**Q1.** The risk team thinks the price file may be incomplete. Count the trading days for each ticker. Are all eight tickers the same length?

- **Answer:** Yes. Each ticker has 123 trading days.
- **Reference SQL:**
```sql
select
    ticker,
    count(*) as n
from prices
group by ticker
order by ticker;
```

**Q2.** A trader wants to check ALPH's five highest-volume days for news events. List the date and volume for each, highest first.

- **Answer:** 2025-04-22 (10,331,371); 2025-06-02 (10,094,543); 2025-05-21 (9,764,000); 2025-01-29 (9,291,942); 2025-05-30 (8,985,849).
- **Reference SQL:**
```sql
select
    ticker,
    trade_date,
    volume
from prices
where ticker = 'ALPH'
order by volume desc
limit 5;
```

**Q3.** Check the date coverage of the price file. What are the first and last trade dates, and how many distinct trading days does the file contain?

- **Answer:** First day 2025-01-02, last day 2025-06-30, 123 distinct trading days. This matches the 123 rows per ticker in Q1.
- **Reference SQL:**
```sql
select
    min(trade_date) as first_day,
    max(trade_date) as last_day,
    count(distinct trade_date) as distinct_days
from prices;
```

**Q4.** Before loading the file into a risk system, confirm that each (ticker, trade_date) appears once. Report the total row count and the number of distinct pairs.

- **Answer:** 984 rows and 984 distinct pairs. The key is unique.
- **Reference SQL:**
```sql
select
    count(*) as rows_,
    count(distinct (ticker, trade_date)) as distinct_pairs
from prices;
```

## Topic 2: Summarizing returns, volume and liquidity

**Q5.** Rank the tickers by average daily volume, highest first. Round to whole shares.

- **Answer:** DLTA 15,050,854; BRVO 9,954,318; GRNT 7,726,406; ECHO 6,065,372; ALPH 4,503,488; FNCH 3,499,075; CRST 2,201,474; HLIO 1,872,065.
- **Reference SQL:**
```sql
select
    ticker,
    round(avg(volume), 0) as avg_volume
from prices
group by ticker
order by avg_volume desc;
```

**Q6.** Which tickers average more than 3 million shares a day?

- **Answer:** DLTA, BRVO, GRNT, ECHO, ALPH, FNCH (six tickers). Tests `HAVING` against `WHERE`: this filters groups, not rows.
- **Reference SQL:**
```sql
select
    ticker,
    round(avg(volume), 0) as avg_volume
from prices
group by ticker
having avg(volume) > 3000000
order by avg_volume desc;
```

**Q7.** For each ticker, count the days the stock closed above its open. Sort the results from most up days to fewest. Which ticker has the most up days, and how many does it have?

- **Answer:** HLIO, with 74. Full order: HLIO 74, CRST 67, FNCH 66, BRVO 65, ECHO 62, ALPH 61, GRNT 60, DLTA 58.
- **Reference SQL:**
```sql
select
    ticker,
    count(*) as up_days
from prices
where close_price > open_price
group by ticker
order by up_days desc, ticker;
```

**Q8.** For each ticker, find the highest `high_price` and the lowest `low_price` over the period, using `MAX()` and `MIN()`. Which ticker has the highest price in the whole file, and what is it?

- **Answer:** HLIO has the highest price in the file, at 525.67. The full results: HLIO 525.67 high / 293.60 low; CRST 274.08 / 215.26; FNCH 173.63 / 145.36; ALPH 128.01 / 106.77; ECHO 95.28 / 77.50; GRNT 75.52 / 49.39; BRVO 59.87 / 42.60; DLTA 21.55 / 9.00.
- **Reference SQL:**
```sql
select
    ticker,
    max(high_price) as highest_high,
    min(low_price) as lowest_low
from prices
group by ticker
order by highest_high desc;

-- Whole-file maximum (the single answer to "highest price in the file"):
select max(high_price) as highest_price_all
from prices;
```

## Topic 3: Joining prices to fundamentals and reference data

**Q9.** Run the query below, which compares an inner join and a left join of `companies` to `prices`. Explain the two output rows. Why does the left join return more rows, and which rows are they? Why do both queries count the same 984 priced rows?

```sql
select
    'inner' as j,
    count(*) as rows_,
    count(distinct c.ticker) as tickers,
    count(p.ticker) as priced_rows
from companies c
inner join prices p
    on p.ticker = c.ticker
union all
select
    'left',
    count(*),
    count(distinct c.ticker),
    count(p.ticker)
from companies c
left join prices p
    on p.ticker = c.ticker;
```

- **Answer:** Inner: 984 rows, 8 tickers, 984 priced rows. Left: 986 rows, 10 tickers, 984 priced rows. An inner join keeps only companies with matching price rows. A left join keeps every company, so IOTA and JUNO appear once each with NULL price columns. The 984 priced rows are the same in both, because the extra 2 rows have no price data (`COUNT(p.ticker)` skips NULLs).
- **Reference SQL:** (the query above is the reference)

**Q10.** Which companies in the reference table have no price history? What are their listing dates?

- **Answer:** IOTA (listed 2025-09-17) and JUNO (listed 2025-11-05).
- **Reference SQL:**
```sql
select
    c.ticker,
    c.listing_date
from companies c
left join prices p
    on p.ticker = c.ticker
where p.ticker is null
order by c.ticker;
```

**Q11.** Compute each company's market cap in $ millions at the fiscal 2025 Q2 period end: the 2025-06-30 close times shares outstanding. Sort from largest to smallest. Which company is largest, and what is its market cap?

- **Answer:** HLIO, at 304,745. Full order: HLIO 304,745; CRST 109,829; ALPH 93,618; ECHO 46,358; FNCH 40,693; GRNT 20,522; BRVO 14,751; DLTA 10,565. IOTA and JUNO drop out because they have no prices.
- **Reference SQL:**
```sql
select
    f.ticker,
    round(p.close_price * f.shares_outstanding, 0) as mktcap_mm
from fundamentals f
join prices p
    on p.ticker = f.ticker
   and p.trade_date = f.period_end_date
where f.fiscal_year = 2025
  and f.fiscal_quarter = 2
order by mktcap_mm desc;
```

**Q12.** Which companies reported a net loss in fiscal 2025 Q1? Show net income and revenue.

- **Answer:** IOTA (net income −96.2, revenue 35.7) and JUNO (net income −61.6, revenue 303.6). Both are the companies that have no price history.
- **Reference SQL:**
```sql
select
    f.ticker,
    f.net_income,
    f.revenue
from fundamentals f
where f.fiscal_year = 2025
  and f.fiscal_quarter = 1
  and f.net_income < 0
order by f.ticker;
```

## Topic 4: Rule-based logic with CTEs and CASE

**Q13.** Normalize the FX rates so every pair reads as USD per unit of foreign currency. Average each pair over the period, to four decimal places.

- **Answer:** AUDUSD 0.5907; EURUSD 1.0877; GBPUSD 1.2120; USDCAD 0.6785; USDCHF 1.1000; USDJPY 0.0071.
- **Reference SQL:**
```sql
with n as (
    select
        r.pair,
        case
            when p.quote_ccy = 'USD' then r.rate
            else 1.0 / r.rate
        end as usd_per_foreign
    from fx_rates r
    join fx_pairs p using (pair)
)
select
    pair,
    round(avg(usd_per_foreign), 4) as avg_usd_per_foreign
from n
group by pair
order by pair;
```

**Q14.** Classify each pair-day by its daily range relative to the rate: calm (under 0.5%), normal (0.5% to under 1%), or volatile (1% or more). Count the days in each class for each pair.

- **Answer:**

| Pair | Calm | Normal | Volatile |
|---|---|---|---|
| AUDUSD | 36 | 59 | 28 |
| EURUSD | 57 | 54 | 12 |
| GBPUSD | 50 | 52 | 21 |
| USDCAD | 65 | 53 | 5 |
| USDCHF | 59 | 54 | 10 |
| USDJPY | 37 | 63 | 23 |

- **Reference SQL:**
```sql
with r as (
    select
        pair,
        (day_high - day_low) / rate as rng
    from fx_rates
)
select
    pair,
    sum(case when rng < 0.005 then 1 else 0 end) as calm,
    sum(case when rng >= 0.005 and rng < 0.01 then 1 else 0 end) as normal,
    sum(case when rng >= 0.01 then 1 else 0 end) as volatile
from r
group by pair
order by pair;
```

**Q15.** On how many days in each month was the 10-year yield below the 2-year yield (inverted curve)?

- **Answer:** January 3, May 5, June 9 (17 days in total).
- **Reference SQL:**
```sql
with y as (
    select
        rate_date,
        max(case when tenor = '10Y' then yield_pct end)
          - max(case when tenor = '2Y' then yield_pct end) as spread
    from treasury_yields
    group by rate_date
)
select
    strftime(rate_date, '%Y-%m') as month,
    count(*) as inverted_days
from y
where spread < 0
group by month
order by month;
```

**Q16.** Add up each company's foreign revenue share across currencies. Band the companies as high (25% or more), moderate (10% to under 25%), or low (under 10%). Count companies per band and give the range of each band.

- **Answer:** High: 6 companies, 27%–43%. Moderate: 2 companies, 20%–22%. Low: 2 companies, 7%–8%.
- **Reference SQL:**
```sql
with e as (
    select
        ticker,
        sum(pct_revenue) as foreign_pct
    from fx_exposure
    group by ticker
),
b as (
    select
        ticker,
        foreign_pct,
        case
            when foreign_pct >= 25 then 'high'
            when foreign_pct >= 10 then 'moderate'
            else 'low'
        end as band
    from e
)
select
    band,
    count(*) as companies,
    min(foreign_pct) as min_pct,
    max(foreign_pct) as max_pct
from b
group by band
order by band;
```

## Topic 5: Dates, bonds and window functions

**Q17.** For each bond, find the last coupon on or before 2025-06-30, the days accrued since that coupon, and the accrued interest per 100 of face value (`coupon_rate × days / 365`). Sort from most to least accrued interest. Which bond has the most accrued interest, and how many bonds have a coupon on or before the cutoff?

- **Answer:** GRNT-32 has the most: last coupon 2025-02-15, 135 days, 1.9880 per 100. Twelve bonds have a coupon on or before the cutoff. The other two were issued in 2025 and have none, so their accrual would run from issue date. Full order: GRNT-32 1.9880; FNCH-33 1.9476; DLTA-31 1.8801; DLTA-26 1.7260; HLIO-28 1.5918; ECHO-29 1.4795; ALPH-34 1.4291; ALPH-27 0.9527; ECHO-45 0.6932; CRST-28 0.5671; BRVO-30 0.4866; FNCH-26 0.1952.
- **Reference SQL:**
```sql
with c as (
    select
        b.bond_id,
        b.coupon_rate,
        max(cc.coupon_date) as last_coupon
    from bonds b
    join bond_coupons cc
        on cc.bond_id = b.bond_id
    where cc.coupon_date <= date '2025-06-30'
    group by b.bond_id, b.coupon_rate
)
select
    bond_id,
    last_coupon,
    date_diff('day', last_coupon, date '2025-06-30') as days_accrued,
    round(coupon_rate * date_diff('day', last_coupon, date '2025-06-30') / 365, 4) as accrued_per_100
from c
order by accrued_per_100 desc;

-- Count check (expect 12):
select count(*) as bonds_with_prior_coupon
from (
    select bond_id
    from bond_coupons
    where coupon_date <= date '2025-06-30'
    group by bond_id
);
```

**Q18.** Compute ALPH's 20-day rolling volatility of daily returns, annualized with √252, as of 2025-06-30. How many daily returns does ALPH have, and why not 123?

- **Answer:** 24.33%. ALPH has 122 daily returns because the first trading day has no prior close to compare against.
- **Reference SQL:**
```sql
with r as (
    select
        ticker,
        trade_date,
        close_price / lag(close_price) over (
            partition by ticker
            order by trade_date
        ) - 1 as ret
    from prices
),
v as (
    select
        ticker,
        trade_date,
        stddev_samp(ret) over (
            partition by ticker
            order by trade_date
            rows between 19 preceding and current row
        ) * sqrt(252) as vol20
    from r
    where ret is not null
)
select
    trade_date,
    round(vol20 * 100, 2) as vol20_pct
from v
where ticker = 'ALPH'
order by trade_date desc
limit 1;
```

**Q19.** For each ticker, compute the maximum drawdown: the lowest ratio of close to the running peak close, minus 1. Sort from worst to best. Which ticker has the largest drawdown, and how big is it?

- **Answer:** DLTA, at −55.75%. Full order: DLTA −55.75%; GRNT −32.74%; BRVO −20.86%; ECHO −16.38%; ALPH −15.27%; FNCH −14.60%; CRST −9.26%; HLIO −8.49%.
- **Reference SQL:**
```sql
with d as (
    select
        ticker,
        trade_date,
        close_price / max(close_price) over (
            partition by ticker
            order by trade_date
            rows unbounded preceding
        ) - 1 as dd
    from prices
)
select
    ticker,
    round(min(dd) * 100, 2) as max_drawdown_pct
from d
group by ticker
order by max_drawdown_pct;
```

**Q20.** Rank the tickers by total return from the first close (2025-01-02) to the last close (2025-06-30). Which ticker ranks first, and which ranks last?

- **Answer:** HLIO first at +66.09%. DLTA last at −52.39%. Full order: HLIO 66.09%, CRST 14.63%, ALPH −0.25%, BRVO −1.33%, FNCH −4.87%, ECHO −6.76%, GRNT −21.04%, DLTA −52.39%.
- **Reference SQL:**
```sql
with f as (
    select distinct
        ticker,
        first_value(close_price) over w as first_close,
        last_value(close_price) over w as last_close
    from prices
    window w as (
        partition by ticker
        order by trade_date
        rows between unbounded preceding and unbounded following
    )
)
select
    ticker,
    round((last_close / first_close - 1) * 100, 2) as total_return_pct,
    row_number() over (order by last_close / first_close desc) as rnk
from f
order by rnk;
```
