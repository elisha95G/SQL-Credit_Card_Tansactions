Select Top 2 * from CC_Trans;

Select * from CC_Trans where city = 'Bangalore' and amount > 100000;

Select * from CC_Trans where city = 'Hyderabad' and gender = 'F' and exp_type = 'Bills' and Card_Type = 'Gold'
	

-- Question 1 -- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with A as (select city, sum(amount) as Amount_Spent 
from CC_Trans
group by city)
, B as(
select *,
sum(amount_spent) over() as total_amount_spent	
from A)

select top 5 City,amount_spent, round((amount_spent/total_amount_spent)*100,2) as percentage_con from B
order by Amount_Spent desc;


-- Question 2: Write a Query to Print highest spent month. Print the Card_Wise Amount Spent in that Month?

With CTE1 as (
select  DATEPART(year,transaction_date) as Year_TD, DATEPART(Month, transaction_date) as Month_TD , 
		Sum(amount) as Month_Amt
from CC_Trans
group by DATEPART(year,transaction_date), DATEPART(Month,transaction_date))
,CTE2 as(
Select *,
RANK() Over(order by Month_Amt desc) as Rank_TD
from CTE1)
Select Card_type, 
	Sum(amount) as Amount 
from CC_Trans
where DATEPART(year,transaction_date) =(Select Year_TD from CTE2 where Rank_TD=1) and
	DATEPART(Month, transaction_date) = (Select Month_TD from CTE2 where Rank_TD=1)
group by card_type

-- Question (3)- Write a query to print highest spend month and amount spent in that month for each card type
	
with CTE as (select card_type, sum(amount) as amount_spent, 
datepart(month,transaction_date) as month,
datepart(year, transaction_date) as year
from CC_Trans
group by card_type, datepart(month,transaction_Date), datepart(year,transaction_date))
, B as(
select *,
rank() over(partition by card_type order by amount_spent desc) as rnk
from CTE)

select * from B
where rnk=1;

--Question.4:write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
	
with CTE1 as (select *,
sum(amount) over(partition by card_type order by transaction_Date, transaction_id) as Cumulativeamount
from CC_Trans)

,CTE2 as(select *,
rank() over(partition by card_type order by cumulativeamount) as rnk
from CTE1
where cumulativeamount>=1000000)

select * from CTE2 where rnk=1

--Question 5
--write a query to find city which had lowest percentage spend for gold card type

with CTE1 as (select city, sum(amount) as total_spent, 
sum(case when card_type='Gold' then amount else 0 end) as gold_spent
from CC_Trans
group by city)
select top 1 city, (sum(gold_spent)/sum(total_spent))*100 as gold_per
from cte1
group by city 
having (sum(gold_spent)/sum(total_spent))*100>0
order by gold_per asc;



-- alternatively we can get the results using the below query:
With A as (Select City,card_type, Sum(amount) as card_amount
from CC_Trans
group by card_type, city)
, B as (
Select *,
Sum(card_amount) Over(Partition by city) as city_amt
from A)
Select Top 1 City, (Card_amount/city_amt) as gold_con
from B
where card_type = 'Gold'
Order by gold_con;

-- Question 6
--write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte1 as (select city, exp_type, sum(amount) as exptype_amt
from CC_Trans
group by city,exp_type)

, CTE2 as(select *,
max(exptype_amt) over(partition by city) as max_amt,
min(exptype_amt) over(partition by city) as min_amt
from cte1)

select city, max(case when exptype_amt=max_amt then exp_type end) as highest, min(case when exptype_amt=min_amt then exp_type end) as lowest
from cte2
group by city;
--  to group the cities we need an aggregation function on a string we can use only min or max aggreegation functions

-- alternatively
with cte1 as (select city, exp_type, sum(amount) as exptype_amt
from CC_Trans
group by city,exp_type)

, cte2 as (select *,
rank() over(partition by city order by exptype_amt desc) as rn_desc,
rank() over(partition by city order by exptype_amt asc) as rn_asc
from cte1)

select city, max(case when rn_asc=1 then exp_type end ) as lowest_expense,
min(case when rn_desc=1 then exp_type end) as highest_expense
from cte2
group by city

-- Question 7
-- write a query to find percentage contribution of spends by females for each expense type

select exp_type,(Fem_exp_amount/total_amount) as Fem_Con from
(select exp_type,sum(amount) as total_amount, sum(case when gender='F' then amount end) as Fem_exp_amount from
CC_Trans
group by exp_type) A
order by Fem_Con desc

-- Alternatively:
With A as (Select  Exp_type, sum(amount) as exp_amount
from CC_Trans
where gender = 'F'
group by exp_type)
, B as (
Select  Exp_type, sum(amount) as totalexp_amount
from CC_Trans
group by exp_type)
Select A.EXP_Type, A.exp_amount/B.totalexp_amount
from A
inner join B
on A.exp_type = B.exp_type

	
-- Question 8
--which card and expense type combination saw highest month over month growth in Jan-2014

with A as(
select card_type, exp_type, sum(amount) as totalamount, datepart(month,transaction_date) as mth , datepart(year,transaction_date) as year
from CC_Trans
group by card_type, exp_type,  datepart(month,transaction_date), datepart(year,transaction_date))
, B as(
select *,
lag(totalamount,1) over(partition by card_type,exp_type order by year,mth) as lag_1
from A)


select top 1 *, totalamount-lag_1 as mom_growth
from B
where lag_1 is not null and year=2014 and mth=1
order by mom_growth desc;


--Question 9 -during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city, sum(amount)/count(1) as transaction_ratio
from CC_Trans
where datename(DW,transaction_Date) in('Saturday','Sunday')
group by city
order by transaction_ratio desc
-- we can do problem 8 using datepart it gives faster because it is easy to make a filter on it


-- Question 10-which city took least number of days to reach its 500th transaction after the first transaction in that city
	
With CTE as (
select *,
ROW_NUMBER() over(partition by city order by transaction_date, transaction_id) as rn
from CC_Trans)
select city, datediff(day,min(transaction_date), max(transaction_date)) as diff_days
from CTE
where rn=1 or rn=500
group by city
having count(1)=2
order by diff_days
