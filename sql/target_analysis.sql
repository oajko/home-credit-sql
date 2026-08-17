-- Do some analysis on the train set target.
-- Dive and investigate into logical causes to default rate. See if they are real.


-- Identifies the target distribution.
-- We see large target imbalance, which is expected for this domain.
-- Wary that we need to account for class imbalance in model creation.
select target, count(*), round(count(*) * 100.0 / (select count(*) from train_base), 2) as percentage
from train_base
group by target;


-- This shows the defult rate per month.
-- We can see it spiked in early 2020. That's where monthly of default > total average
select "MONTH", target, count(*), sum(count(*)) over (partition by "MONTH") as monthly_total,
round(count(*) * 100.0 / sum(count(*)) over (partition by "MONTH"), 2) as monthly_percentage
from train_base
group by "MONTH", target
order by "MONTH", target;


-- We can see that most defaults came from 09 2019 - 03 2020. The beginning of Covid 19.
-- Domain knowledge, around this time was where negative bond yields occurred.
-- I believe rates were rising at this time. And stimulus and 0% interest rates from April as a
-- cause to the drop in default rate.
with temp as (
	select "MONTH", target, count(*), sum(count(*)) over (partition by "MONTH") as monthly_total
	from train_base
	group by "MONTH", target
	order by "MONTH", target
)
select *, "MONTH", round(count / monthly_total * 100, 3) as percentage
from temp
where target = 1 and count / monthly_total > (
	select sum(count) / sum(monthly_total) from temp
	where target = 1
);


-- Target analysis with previous loan data.
-- train_applprev_1_0 and 1_1 are chunks of the same data, and can be combined.

with agg_prev as (
	select * from train_applprev_1_0
	UNION ALL
	select * from train_applprev_1_1
),
	count_agg as (
	select case_id, count(*) from agg_prev
	group by case_id
),
	aggre as (
	select a.case_id, COALESCE(count, 0) AS prev_count, target
	from train_base as a
	left join (select * from count_agg) as b using (case_id)
	order by case_id asc
)
select * from aggre;

-- Check target with age.
-- High default risk generally by younger people 

with temp as (
	select target, (date("date_decision") - date("birth_259D")) / 365 as age,
	count(*) as totals,
	sum(count(*)) over (partition by (date("date_decision") - date("birth_259D")) / 365) as age_count
	from train_base
	left join (
		select case_id, "birth_259D" from train_person_1
		where "birth_259D" is not null
	) as b using (case_id)
	group by age, target
	order by age, target
)
select age, round(totals / age_count * 100, 3) as percentage from temp
where target = 1;


-- Compare dpd of last 3 months to last 24 months.
-- We can see worsening dpd case_ids result to more defaults.
-- However, the lowest ratio of 3.191 is above the total average.
-- This means records with null in either field are less likely to default in this data.
with agg_data as (
	select * from train_static_0_0
	union all
	select * from train_static_0_1
),
dpd_compare as (
	select case_id, target, coalesce("avgdbddpdlast3m_4187120P", 0) as avg3m,
	coalesce("avgdbddpdlast24m_3658932P", 0) as avg24m
	from train_base a
	left join agg_data b using (case_id)
	where "avgdbddpdlast3m_4187120P" is not null and "avgdbddpdlast24m_3658932P" is not null
),
diff_table as (
	select case_id, target,
	case when avg3m - avg24m < -3 then 'improving'
		when avg3m - avg24m > 3 then 'worsening'
		else 'stable' end as trend
	from dpd_compare
)
select target, trend, count(*), 
round(count(*) / sum(count(*)) over (partition by trend) * 100, 3) as ratio from diff_table
group by trend, target
order by trend, target;

-- Check target with credit utilization
-- People with higher utilization rate defaults more than with less, which is expected.

with combined_static as (
	select * from train_static_0_0
	union all
	select * from train_static_0_1
),
bureau as (
	select case_id, sum("totalamount_503A") as total_active,
	sum("residualamount_127A") as residual, sum("credlmt_1052A") as cred_limit
	from train_credit_bureau_b_1
	group by case_id
),
comb as (
	select case_id, target, "currdebt_22A" / nullif("credamount_770A", 0) as cred_util,
	coalesce(total_active, 0) / nullif("maininc_215A", 0) as income_exposure
	from train_base a
	left join combined_static b using (case_id)
	left join bureau c using (case_id)
	where "credamount_770A" > 0
),
agg as (
	select case_id, target, case when cred_util < 0.5 then 'low'
			when cred_util < 0.75 then 'mid'
			when cred_util < 1.0 then 'high'
			else 'very high' end as util,
		income_exposure
	from comb
)
select target, util, round(count(*) / sum(count(*)) over (partition by util) * 100, 3) from agg
group by util, target
order by util, target;

