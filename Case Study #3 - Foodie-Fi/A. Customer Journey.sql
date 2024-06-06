--Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
--Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

--To check the subscription information of customers, I join the subscriptions (sample) table with the plans table (looking at the information through plan_name will be easier to understand than plan_id).

--Sort the query results by each customer_id and in ascending order of start_date:

select 
    customer_id, 
    P.plan_id, 
    plan_name, 
    start_date
from foodie_fi.plans as P
join foodie_fi.subscriptions_samples as SS 
    on P.plan_id = SS.plan_id
order by 
    customer_id, 
    start_date;

--Below is a description based on the sequence of events recorded in the subscriptions table combined with the plans table, highlighting each customer's journey from the trial period to their subscription plan choices and any churn activity:

--Customer 1: Started with a trial on August 1, 2020, then subscribed to the basic monthly plan on August 8, 2020.
--Customer 2: Began with a trial on September 20, 2020, then upgraded to the pro annual plan on September 27, 2020.
--Customer 11: Initiated a trial on November 19, 2020, but churned on November 26, 2020, without subscribing to any paid plan.
--Customer 13: Started with a trial on December 15, 2020, subscribed to the basic monthly plan on December 22, 2020, and later upgraded to the pro monthly plan on March 29, 2021.
--Customer 15: Started with a trial on March 17, 2020, upgraded to the pro monthly plan on March 24, 2020, and then churned on April 29, 2020.
--Customer 16: Initiated a trial on May 31, 2020, subscribed to the basic monthly plan on June 7, 2020, and later upgraded to the pro annual plan on October 21, 2020.
--Customer 18: Started with a trial on July 6, 2020, upgraded to the pro monthly plan on July 13, 2020.
--Customer 19: Signed up for a trial on June 22, 2020, subscribed to the pro monthly plan on June 29, 2020, and then upgraded to the pro annual plan on August 29, 2020.
