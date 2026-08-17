-- General dataset analysis.

-- Identify which tables have same columns.
with clusters as(select table_name, MD5(STRING_AGG(column_name, ', ' order by column_name)) AS file_name
	from information_schema.columns
	where table_schema = 'public'
	group by table_name
)
select array_agg(table_name order by table_name) as cluster from clusters
group by file_name;


-- Showcase month distribution of the train set. Dips in 2020, probably from Covid-19.
-- However Weakness in Oct 2020, after recoverty in Aug and Sep
select "MONTH", count(*) from train_base
group by "MONTH";


-- We see the reason for low data entry in Oct 2020 is due to only including the first 5 days of the month.
select date(date_decision), count(*) from train_base
where date_decision like '2020%' and date_decision like '%-10-%'
group by date_decision;

-- Train records are unique
select count(distinct case_id), count(case_id) from train_base;

-- The number of people with debit card --
select count(distinct case_id) from train_debitcard_1;

-- All people look real. No fake records based on age.
select min("birth_259D"), max("birth_259D") from train_person_1
where "birth_259D" is not null;

