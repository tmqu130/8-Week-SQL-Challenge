--D. Outside The Box Questions

--1. How would you calculate the rate of growth for Foodie-Fi?

--To calculate the growth rate, I'll sum the amount from the payment table, grouped by each month.
--Then, I'll perform the calculation (revenue this month - revenue last month)/revenue last month using the window function LAG.

--2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

-- Monthly revenue growth
-- Customer count growth
-- Conversion rate (number of customers using different plans after free trial/total number of customers)
-- Revenue growth/customer count
-- Churn rate

--3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?

-- Analyze customer upgrades from monthly plan to yearly plan (segment cases based on the number of months from subscribing monthly to upgrading to yearly: 1-3-6)
-- Analyze customer subscription cancellations after free trial
-- Analyze customer plan downgrades
-- Analyze customer churn from Foodie-Fi

--4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

--a) Reason for Cancellation:
    --What is the primary reason for canceling your Foodie-Fi subscription?
    --Please select all factors that contributed to your decision to cancel:
        -- +) Found alternative service/content provider
        -- +) Cost-related concerns
        -- +) Content quality
        -- +) Technical issues
        -- +) Not using the service enough
        -- +) Other (please specify)

--b) Satisfaction and Feedback:
    --How satisfied were you with Foodie-Fi overall? (Likert scale: Very Satisfied - Very Unsatisfied)
    --What did you like most about Foodie-Fi? 
    --What aspects of Foodie-Fi could be improved?
    --Would you recommend our company to a colleague, friend or family member? (Likert scale: Very Satisfied - Very Unsatisfied)

--c) Content Preferences:
    --Which types of content did you enjoy the most on Foodie-Fi? (e.g., cooking shows, recipe tutorials, documentaries) (Likert scale: Very Satisfied - Very Unsatisfied)
    --Was there any specific content you wished Foodie-Fi offered but didn't?

--d) User Experience:
    --How would you rate the usability and navigation of the Foodie-Fi platform? (Likert scale: Very Satisfied - Very Unsatisfied)
    --Were there any features or functionalities you found lacking or difficult to use? 
    --Do you feel that Foodie-Fi offered good value for the subscription price? (Likert scale: Very Satisfied - Very Unsatisfied)
    --Would you consider remaining using Foodie-Fi in the future? (Likert scale: Very Satisfied - Very Unsatisfied)

--Additional Comments:
    --Can you provide some demographic information to help us better understand our customer base? (e.g., age, gender, location, occupation)
    --Is there anything else you would like to share with us about your experience with Foodie-Fi?

--5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

--Figure out the primary reason for Cancellation from the exit survey, then:

--a) Found alternative service/content provider reason:
    --Strategy: Do competitors analysis:
        --Conduct an in-depth analysis of competitors in the cooking streaming service market, 
        --Identify competitors' strengths and weaknesses, as well as the unique value propositions they offer,
        --Use insights gained to refine Foodie-Fi's offerings and differentiate them from competitors.
    --Validation: 
        --Comparative Metrics: 
            --Measure changes in key metrics such as customer acquisition, retention, and engagement before and after implementing insights from competitor analysis.
        --Customer Feedback: 
            --Gather feedback from customers regarding perceived improvements or differentiators in Foodie-Fi's offerings compared to competitors.
        --Subscription Trends: 
            --Analyze subscription trends to see if there's an increase in customer retention or acquisition following adjustments made based on competitor analysis.

--b) Cost-related concerns reason:
    --Strategy: Offer Incentives and Discounts:
        --Provide promotional offers, discounts, or loyalty rewards to incentivize customers to stay subscribed and remain engaged with the platform.
    --Validation: 
        --Monitor changes in churn rate and customer retention metrics during promotional periods compared to baseline periods.
        --Analyze the redemption rates and effectiveness of promotional offers by tracking customer behavior and uptake of incentives.

--c) Content quality reason:
    --Strategy:
        --Continuously update and diversify the content library with high-quality, engaging, and relevant food-related content.
        --Implement personalized recommendations based on user preferences, viewing history, and behavior to surface relevant content and enhance engagement.
    --Validation: 
        --Monitor changes in viewer engagement metrics such as watch time, completion rates, and feedback on newly added content.
        --Conduct surveys or gather feedback from customers to assess satisfaction with the content offerings and preferences.

--d) Technical issues reason:
    --Strategy: Debug Foodie-Fi platform and Improve User Experience (UX):
        --Optimize the platform's user interface, navigation, and overall user experience to make it intuitive, seamless, and enjoyable to browse and consume content.
    --Validation: 
        --Track metrics related to user engagement and retention, such as session duration, frequency of visits, and bounce rates.
        --Use usability testing and gather feedback from users to identify pain points and areas for improvement in the user experience.

--e) Not using the service enough reason:
    --Strategy: Implement Targeted Re-Engagement Campaigns:
        --Identify at-risk customers based on behavioral indicators (e.g., decreased activity, missed payments).
        --Proactively reach out with targeted re-engagement campaigns to rekindle interest and encourage continued subscription.
    --Validation: 
        --Monitor changes in customer behavior and engagement levels following re-engagement campaigns.
        --Analyze the impact of targeted communication strategies on churn rate and customer retention over time.
    
--In general, to validate the effectiveness of these strategies, Foodie-Fi can: 
    --Conduct controlled experiments, A/B tests, and ongoing performance tracking to measure changes in key metrics:
        --churn rate, customer retention, engagement, and customer satisfaction. 
