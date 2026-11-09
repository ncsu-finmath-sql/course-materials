-- Annual operating cash flow less capital expenditures, fiscal 2021-2026.
-- Checked live on November 8, 2026: only MSFT has fiscal 2026 so far (its year
-- ends in June). The other four stop at fiscal 2025, so their last row is older.
-- Compustat names ORCL's year ending May 2026 as fiscal 2025.
select
	conm as company
	, fyear as fiscal_year
	, datadate as fiscal_year_end
	, oancf as operating_cash_flow
	, capx as capital_expenditures
	, oancf - capx as free_cash_flow
from comp.funda
where
	tic in ('MSFT', 'GOOGL', 'AMZN', 'META', 'ORCL')
	and fyear between 2021 and 2026
	and indfmt = 'INDL'
	and datafmt = 'STD'
	and popsrc = 'D'
	and consol = 'C'
	and curcd = 'USD'
order by company, fiscal_year;
