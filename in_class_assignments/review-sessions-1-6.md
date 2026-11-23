# Review: Sessions 1–6 (20 Questions)

**Course:** FIM 590, Data Analytics with SQL

## How to use this sheet

1. This is a review, not a graded assignment. Work through it in order, or pick the topics you want to practice.
2. Write each answer as a query in your own `.sql` file. Where a question asks you to **explain** or **say**, write a short answer in the file as a comment.
3. Compare your results with what you expect. If something looks off (a row count, a date range, a sign), check your joins, filters and groups before moving on.
4. Use only the tables described in `datasets/README.md`. No Gemini or other AI tool is needed for this review.

## Topic 1: Pulling and sanity-checking market data

**Q1.** The risk team thinks the price file may be incomplete. Count the trading days for each ticker. Are all eight tickers the same length?

**Q2.** A trader wants to check ALPH's five highest-volume days for news events. List the date and volume for each, highest first.

**Q3.** Check the date coverage of the price file. What are the first and last trade dates, and how many distinct trading days does the file contain?

**Q4.** Before loading the file into a risk system, confirm that each (ticker, trade_date) appears once. Report the total row count and the number of distinct pairs.

## Topic 2: Summarizing returns, volume and liquidity

**Q5.** Rank the tickers by average daily volume, highest first. Round to whole shares.

**Q6.** Which tickers average more than 3 million shares a day?

**Q7.** For each ticker, count the days the stock closed above its open. Sort the results from most up days to fewest. Which ticker has the most up days, and how many does it have?

**Q8.** For each ticker, find the highest `high_price` and the lowest `low_price` over the period, using `MAX()` and `MIN()`. Which ticker has the highest price in the whole file, and what is it?

## Topic 3: Joining prices to fundamentals and reference data

**Q9.** Run the query below, which compares an inner join and a left join of `companies` to `prices`. Explain the two output rows. Why does the left join return more rows, and which rows are they? Why do both queries count the same priced rows?

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

**Q10.** Which companies in the reference table have no price history? What are their listing dates?

**Q11.** Compute each company's market cap in $ millions at the fiscal 2025 Q2 period end: the 2025-06-30 close times shares outstanding. Sort from largest to smallest. Which company is largest, and what is its market cap?

**Q12.** Which companies reported a net loss in fiscal 2025 Q1? Show net income and revenue.

## Topic 4: Rule-based logic with CTEs and CASE

**Q13.** Normalize the FX rates so every pair reads as USD per unit of foreign currency. Average each pair over the period, to four decimal places.

**Q14.** Classify each pair-day by its daily range relative to the rate: calm (under 0.5%), normal (0.5% to under 1%), or volatile (1% or more). Count the days in each class for each pair.

**Q15.** On how many days in each month was the 10-year yield below the 2-year yield (inverted curve)?

**Q16.** Add up each company's foreign revenue share across currencies. Band the companies as high (25% or more), moderate (10% to under 25%), or low (under 10%). Count companies per band and give the range of each band.

## Topic 5: Dates, bonds and window functions

**Q17.** For each bond, find the last coupon on or before 2025-06-30, the days accrued since that coupon, and the accrued interest per 100 of face value (`coupon_rate × days / 365`). Sort from most to least accrued interest. Which bond has the most accrued interest, and how many bonds have a coupon on or before the cutoff?

**Q18.** Compute ALPH's 20-day rolling volatility of daily returns, annualized with √252, as of 2025-06-30. How many daily returns does ALPH have, and why not 123?

**Q19.** For each ticker, compute the maximum drawdown: the lowest ratio of close to the running peak close, minus 1. Sort from worst to best. Which ticker has the largest drawdown, and how big is it?

**Q20.** Rank the tickers by total return from the first close (2025-01-02) to the last close (2025-06-30). Which ticker ranks first, and which ranks last?
