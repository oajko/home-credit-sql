-- ETL pipeline to improve the data storage and features of raw dataset

alter train_base rename to base;
alter table base
	alter column date_decision type date using date_decision::date,
	alter column target smallint using target::smallint;

alter train_applprev_2 rename to applprev_2;
alter table applprev_2
	alter column num_group_1 type smallint using num_group_1::smallint,
	alter column num_group_2 smallint using num_group_2::smallint;
	
alter train_credit_bureau_b_1 rename to bureau_b_1;
alter table bureau_b_1
	alter column "contractdate_551D" type date using "contractdate_551D"::date,
	alter column "contractmaturitydate_151D" date using "contractmaturitydate_151D"::date;

alter train_credit_bureau_b_2 rename to bureau_b_2;
alter table bureau_b_2
	alter column "pmts_date_1107D" type date using "pmts_date_1107D"::date,

alter train_debitcard_1 rename to debitcard_1;
alter train_deposit_1 rename to debitcard_1;
alter train_other_1 rename to other_1;
alter train_person_1 rename to person_1;
alter train_person_2 rename to person_2;
alter train_person_static_cb_0 rename to person_static_cb;
alter train_tax_registry_a_1 rename to tax_registry_a;
alter train_tax_registry_b_1 rename to tax_registry_b;
alter train_tax_registry_c_1 rename to tax_registry_c;



-- Aggregate chunked tables tables using view to store no data at the cost of rerunning
-- union all. For large files, permanent create + drop may be beneficial on disk.

create view table static_0 as (
	select * from train_static_0_0
	union all select * from train_static_0_1
)


create view table applprev_1 as(
	select * from train_applprev_1_0
	union all select * from train_applprev_1_1
)

create view table credit_bureau_a_1 as (
	select * from train_credit_bureau_a_1_0
	union all select * from train_credit_bureau_a_1_1
	union all select * from train_credit_bureau_a_1_2
	union all select * from train_credit_bureau_a_1_3
)

create view table credit_bureau_a_2 as (
	select * from train_credit_bureau_a_2_0
	union all select * from train_credit_bureau_a_2_1
	union all select * from train_credit_bureau_a_2_2
	union all select * from train_credit_bureau_a_2_3
	union all select * from train_credit_bureau_a_2_4
	union all select * from train_credit_bureau_a_2_5
	union all select * from train_credit_bureau_a_2_6
	union all select * from train_credit_bureau_a_2_7
	union all select * from train_credit_bureau_a_2_8
	union all select * from train_credit_bureau_a_2_9
	union all select * from train_credit_bureau_a_2_10
)


select * from train_credit_bureau_b_2
limit 20;
