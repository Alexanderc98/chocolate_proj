/*
Chocolate Data Exploration
Skills used: Joins, CTE's, Aggregate Functions, Creating Views, CASE statement
*/


-- Which company manufacturer has the highest count of max rating (which is 4)?

SELECT company_manufacturer, count(*) as count_of_max_rating
FROM ratings_table
WHERE rating == 4
GROUP BY company_manufacturer
ORDER BY count(*) DESC
LIMIT 1;

-- Which 3 chocolates has the lowest cocoa_percent? Output cocoa_percent, company_manufacturer and company_location.

SELECT i.cocoa_percent, c.company_manufacturer, c.company_location
FROM ratings_table r
JOIN ingredients_table i
ON r.review_id = i.review_id
JOIN company_table c
ON r.company_manufacturer = c.company_manufacturer
ORDER BY cocoa_percent
LIMIT 3;

-- Output top 10 bean_origin_country by count of max rating (which is 4)?

SELECT b.country_of_bean_origin, count(*) as count_of_max_rating
FROM ratings_table r
JOIN bean_table b
ON r.specific_bean_origin_or_bar_name = b.specific_bean_origin_or_bar_name
WHERE r.rating == 4
GROUP BY b.country_of_bean_origin
ORDER BY count(*) DESC
LIMIT 10;

-- What is the average rating of all the company_manufacturer country locations? Order from highest the lowest.

SELECT c.company_location, round(avg(r.rating), 2) as average_rating
FROM ratings_table r
JOIN company_table c
ON r.company_manufacturer = c.company_manufacturer
GROUP BY c.company_location
ORDER BY avg(r.rating) DESC;

-- Create a new column that prints 1 if the rating is under 3 and 0 if rating is 3 or above.

SELECT review_id, rating,
	CASE
		WHEN rating < 3 THEN 1
		WHEN rating >= 3 THEN 0
	END as bad_chocolate
FROM ratings_table;

-- Get the average rating per year for the company_manufacturer "Soma". If they did not recieve a rating a particular year,
-- then present average_rating as NULL. Save the table as a view aswell, since we gonna use it again for the next question.

DROP VIEW IF EXISTS soma_avg_rating_table;

CREATE VIEW soma_avg_rating_table AS
WITH avg_rating_per_year_soma as (
	SELECT review_date as year, round(avg(rating), 2) as average_rating
	FROM ratings_table
	WHERE company_manufacturer == 'Soma'
	GROUP BY year
)

, all_years as (
	SELECT DISTINCT(review_date) as year
	FROM ratings_table
	ORDER BY year
)

SELECT 'Soma' as company_manufacturer, a.year, soma.average_rating
FROM all_years a
LEFT JOIN avg_rating_per_year_soma as soma
ON a.year = soma.year;

SELECT *
FROM soma_avg_rating_table;

-- Present average_rating yearly percent gain or decline for the company_manufacturer "Soma" between the years 2009 and 2018
-- Save the table as a view aswell.

CREATE VIEW soma_percentage_gain_table AS
WITH lag_rating AS(
	SELECT *, lag(average_rating) OVER(ORDER BY year) as last_years_rating
	FROM soma_avg_rating_table
	WHERE year >= 2009 AND year <= 2018
)

SELECT company_manufacturer, year, average_rating, round((((average_rating/last_years_rating)*100)-100), 2) as percentage_gain
FROM lag_rating;

SELECT *
FROM soma_percentage_gain_table;

-- What is the average percentage gain for the company "Soma" between the years 2010 and 2018?

SELECT round(avg(percentage_gain), 2) as average_percentage_gain
FROM soma_percentage_gain_table
WHERE year >= 2010
GROUP BY company_manufacturer;

-- What the XGBoost model tells me is that cocoa_percentage plays a big part for the model to figure out if the chocolate will taste bad
-- Lets make groups of cocoa_percentage, 70-80%, 80-90% etc and order by the highest avg rating.

WITH cocoa_percent_groups AS(
	SELECT r.rating, i.cocoa_percent, 
		CASE
			WHEN i.cocoa_percent >= 90 AND i.cocoa_percent <= 100 THEN '90+'
			WHEN i.cocoa_percent >= 80 AND i.cocoa_percent < 90 THEN '80->90'
			WHEN i.cocoa_percent >= 70 AND i.cocoa_percent < 80 THEN '70->80'
			WHEN i.cocoa_percent >= 60 AND i.cocoa_percent < 70 THEN '60->70'
			WHEN i.cocoa_percent >= 50 AND i.cocoa_percent < 60 THEN '50->60'
			WHEN i.cocoa_percent >= 40 AND i.cocoa_percent < 50 THEN '40->50'
		END as cocoa_percent_group
	FROM ratings_table r
	JOIN ingredients_table i
	ON r.review_id = i.review_id
	ORDER BY cocoa_percent DESC
)

SELECT cocoa_percent_group, round(avg(rating), 2) as average_rating
FROM cocoa_percent_groups
GROUP BY cocoa_percent_group
ORDER BY cocoa_percent DESC;

-- Between 60 and 80 cocoa percent has the highest average rating. Lets dive deeper, and look in groups of 60->65, 65>70 etc.

WITH cocoa_percent_groups_60_to_80 AS(
	SELECT r.rating, i.cocoa_percent, 
		CASE
			WHEN i.cocoa_percent >= 75 AND i.cocoa_percent < 80 THEN '75->80'
			WHEN i.cocoa_percent >= 70 AND i.cocoa_percent < 75 THEN '70->75'
			WHEN i.cocoa_percent >= 65 AND i.cocoa_percent < 70 THEN '65->70'
			WHEN i.cocoa_percent >= 60 AND i.cocoa_percent < 65 THEN '60->65'
		END as cocoa_percent_group
	FROM ratings_table r
	JOIN ingredients_table i
	ON r.review_id = i.review_id
	WHERE cocoa_percent_group IS NOT NULL
	ORDER BY cocoa_percent DESC
)

SELECT cocoa_percent_group, round(avg(rating), 2) as average_rating
FROM cocoa_percent_groups_60_to_80
GROUP BY cocoa_percent_group
ORDER BY cocoa_percent DESC;

-- The chocolates with an average rating between 65 and 75 percent seems to be the ones that tastes the best!

-- The column with the 2nd most feature importance is total_ingredients, lets see how average rating differs between the available options.

SELECT total_ingredients, round(avg(rating), 2) as average_rating
FROM ratings_table
GROUP BY total_ingredients
ORDER BY total_ingredients DESC;

-- The two best options are to have a total of 2 or 3 ingredients, so definetly less is more here!

-- Another thing I saw from the feature importance table was that if an chocolate contains_vanilla there is a bigger risk it will taste bad.
-- Lets see what the average ratings is for the chocolates containing vanilla and those that do not.

SELECT i.contains_vanilla, round(avg(rating), 2) as average_rating
FROM ratings_table r
JOIN ingredients_table i
ON r.review_id = i.review_id
GROUP BY i.contains_vanilla;

-- In this sample, that thesis seems to be true! Chocolates that does not contain vanilla has a higher rating.
-- Lets see though if the difference is statistically significant!

SELECT i.contains_vanilla, count(i.contains_vanilla) as count
FROM ratings_table r
JOIN ingredients_table i
ON r.review_id = i.review_id
GROUP BY i.contains_vanilla;

-- Since count is so large for both option im gonna make an assumption that it can be approximated by a normal distribution.
-- Hence, I will do a Z-test

-- Firstly, I need the standard deviation for the two options.
-- Since SQLite does not have built in math functions, I need to calculate variance first and then use an calculator to get the standard dev.

SELECT i.contains_vanilla, avg(r.rating*r.rating) - avg(r.rating)*avg(r.rating) as variance, round(avg(rating), 2) as average_rating
FROM ratings_table r
JOIN ingredients_table i
ON r.review_id = i.review_id
GROUP BY i.contains_vanilla;

-- sqrt(0.185036716168048) = 0.43016 and sqrt(0.248714980458875) = 0.49871
-- I rounded to 5 decimals

CREATE VIEW no_vanilla_sd AS
	SELECT i.contains_vanilla, 0.43016 as standard_dev, round(avg(rating), 2) as average_rating, count(i.contains_vanilla) as count
	FROM ratings_table r
	JOIN ingredients_table i
	ON r.review_id = i.review_id
	WHERE contains_vanilla = 0
	GROUP BY i.contains_vanilla;

CREATE VIEW has_vanilla_sd AS
	SELECT i.contains_vanilla, 0.49871 as standard_dev, round(avg(rating), 2) as average_rating, count(i.contains_vanilla) as count
	FROM ratings_table r
	JOIN ingredients_table i
	ON r.review_id = i.review_id
	WHERE contains_vanilla = 1
	GROUP BY i.contains_vanilla;

SELECT * FROM no_vanilla_sd
UNION
SELECT * FROM has_vanilla_sd;

--Success! Now it's time to do a Z-test and see if there is a statistically significant difference between the two options!
-- For a significance level of 0.05, the critical value is 1.96

WITH standard_error_pow2_CTE AS(
	SELECT (standard_dev*standard_dev)/count as standard_error_pow2
	FROM no_vanilla_sd
	UNION
	SELECT (standard_dev*standard_dev)/count as standard_error_pow2
	FROM has_vanilla_sd
)

SELECT sum(standard_error_pow2)
FROM standard_error_pow2_CTE

-- sqrt(000789562233266014) = 0.028099150045259626

WITH complete_vanilla_temp_table AS(
	SELECT * FROM no_vanilla_sd
	UNION
	SELECT * FROM has_vanilla_sd
)

SELECT average_rating - lead(average_rating) over (order by contains_vanilla) AS difference
FROM complete_vanilla_temp_table
LIMIT 1;

-- The differences between the two averages are 0.19
-- Now it's time to calculate the Z score

SELECT 0.19/0.028099150045259626

-- Z score ~ 6.76177
-- 6.76177 > 1.96

-- With a 5 percent significance level. 
-- The difference in average rating between chocolate bars that contains vanilla and does not contain vanilla is statistically significant
