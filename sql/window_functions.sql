---- Showing default rate in percentiles of debt.
-- People with more debt are more likely to default.
-- However, it's not perfectly monotonic.

with static AS (
    select * from train_static_0_0
    union all
    select * from train_static_0_1
),
buckets as (select case_id, target, ntile(100) over (order by "totaldebt_9A") as percentile
    from static s
    left join train_base b using (case_id)
    where "totaldebt_9A" is not null
)
select percentile,
round(count(*) filter (where target = 1) * 100.0 / count(*), 3) as def_rate
from buckets
group by percentile
order by percentile;


--- Shows debt concentration of top 1% vs other 99%
-- The same as the above query, however, 1% v 99% rather than per 1 percentile
-- Top 1% of debt holders are ~1.74x more likely to default than other 99%

with static as (
    select * from train_static_0_0
    union all
    select * from train_static_0_1
),
ranked as (
    select case_id, target, "totaldebt_9A",
        cume_dist() over (order by "totaldebt_9A") as pop_share,
        percent_rank() over (order by "totaldebt_9A") as debt_rank
    from static s
    left join train_base b using (case_id)
    where "totaldebt_9A" is not null
),
classified as (
	select *, case when pop_share > 0.99 then 'top 1%' else 'bottom 99%' end as segment
    from ranked
)
select segment, count(*) as customers,
	round((sum("totaldebt_9A") * 100.0 / sum(sum("totaldebt_9A"))
		over ())::numeric, 2) as pct_of_total_debt,
    round(count(*) filter (where target = 1) * 100.0 / count(*), 3) as def_rate
from classified
group by segment
order by segment desc;


-- Showing size of first loan vs latest loan.
-- positive growth would mean they've probably been good borrows.
-- And also is explicitly correlated with age, which, which we found as a signal.
with prev as (
    select * from train_applprev_1_0
    union all
    select * from train_applprev_1_1
),
span as (
    select case_id, num_group1, "credamount_590A",
        first_value("credamount_590A") over (partition by case_id order by num_group1
            rows between unbounded preceding and unbounded following
        ) as first_loan,
        last_value("credamount_590A") over (partition by case_id order by num_group1
            rows between unbounded preceding and unbounded following
        ) as latest_loan
    from prev
    where "credamount_590A" is not null
)
select case_id, first_loan, latest_loan,
round(((latest_loan - first_loan) * 100.0 / nullif(first_loan, 0))::numeric, 1) as growth
from span
where num_group1 = 0 and first_loan > 0 and latest_loan > first_loan * 2
order by growth desc;


-- This measures the speed at which people re-apply for credit.
-- It seems people who apply >90 days after are less likely to default.
-- However, no difference for <30 days and < 90 days, which is odd.
with prev as (
    select * from train_applprev_1_0
    union all
    select * from train_applprev_1_1
),
gaps as (
    select case_id, num_group1, "creationdate_885D",
    lag("creationdate_885D") over (partition by case_id order by num_group1 desc) as prev_date,
    lead("creationdate_885D") over (partition by case_id order by num_group1 desc) as next_date
    from prev
    where "creationdate_885D" is not null
),
gap_calc as (
    select case_id, target, "creationdate_885D"::date - prev_date::date as gap_days,
    next_date::date - "creationdate_885D"::date as next_gap_days
    from gaps g
    left join train_base b using (case_id)
    where prev_date is not null
),
bucketed as (
    select case_id, target,
		case when gap_days < 30 then '<30d'
	       	when gap_days < 90 then '30-90d'
			else '>90d' end as speed
    from gap_calc
)
select speed, count(*) as applications,
    round(count(*) filter (where target = 1) * 100.0 / count(*), 3) as def_rate
from bucketed
group by speed
order by def_rate desc;


-- This shows cumulative default rate vs 3m rolling default rate.
-- Shows which period had highest default rate by month + year.
with monthly as (
    select "MONTH", count(*) as counts,
        count(*) filter (where target = 1) as defaults
    from train_base
    group by "MONTH"
)
select "MONTH", counts, defaults,
round(sum(defaults) over (order by "MONTH") * 100.0
	  / nullif(sum(counts) over (order by "MONTH"), 0), 3) as cumulative,
round(sum(defaults) over (order by "MONTH"
	  rows between 2 preceding and current row) * 100.0
	  / nullif(sum(counts) over (order by "MONTH"
	  rows between 2 preceding and current row), 0), 3) as rolling_3m
from monthly
order by "MONTH";



-- This looks at utilization rate to debt capacity.
-- It looks at the default rate of top 10% of highest utilization rate vs other 90%
-- We found case_id who are over-leveraged are more likely to default
with static as (
    select * from train_static_0_0
    union all
    select * from train_static_0_1
),
data as (
    select case_id, target, "currdebt_22A" / nullif("credamount_770A", 0) as utilization,
        ntile(10) over (order by "totaldebt_9A") as debt_decile
    from static s
    left join train_base b using (case_id)
    where "totaldebt_9A" is not null and "credamount_770A" > 0
),
ranked as (
    select case_id, target, utilization, debt_decile,
    row_number() over (partition by debt_decile order by utilization, case_id)
		* 1.0 / count(*) over (partition by debt_decile) as util_rank
    from data
)
select case when util_rank > 0.9 then 'over-leveraged' else 'typical' end as flag,
    count(*) as counts,
    round(count(*) filter (where target = 1) * 100.0 / count(*), 3) as def_rate
from ranked
group by case when util_rank > 0.9 then 'over-leveraged' else 'typical' end
order by def_rate desc;
