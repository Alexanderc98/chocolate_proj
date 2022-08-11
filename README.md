# Predicting if a chocolate bar will taste bad or not using machine learning + EDA.

* Used sklearn to create a binary classification model
* Compared logistic regression, XGBoost and randomforest classification. For instance, did 10-fold cross validation and looked which model performed the best.
* Used advanced SQL techniques to explore the data.
* Created a database in third normal form with sqlite3 package in python.
* Performed data cleaning in pandas and microsoft excel.

## Findings

If you are trying to come up with your first chocolate bar recipe, I have three tips to steer you in the right direction.

These are the three main findings I found from looking at the feature importance score ranking and my exploratory analysis in SQL:

The chocolate bars with a cacao percent between 65 and 75 has the highest average rating, so that seems to be a safe range to go for!

The chocolate bars with a total of 2 or 3 ingredients has the highest average rating, so think, definetly less is more here!

Chocolate bars that does not contain vanilla has a statistically significant (5% significance level) higher rating than chocolate bars with vanilla, so unless you know what you're doing, skip the vanilla :P

## Code and Resources Used
**Data:** https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2022/2022-01-18/chocolate.csv

**Original Data Source:** http://flavorsofcacao.com/chocolate_database.html

**Python Version:** 3.79

**SQLite Version:** 3.31.0

**Tableau Public Version:** 2022.2

**Packages:** pandas, numpy, sklearn, sqlite3

## Data Cleaning
After downloading the data, I made the following changes:

* Removed unnecessary columns needed to conduct my analysis
* Feature engineered dummy variables
* Separated the data to five different sheets and removed duplicates in microsoft excel, so that I could create a great relational database

## Result
Below are the result of my binary classification model:

![alt text](https://github.com/Alexanderc98/chocolate_proj/blob/main/tableau_dashboard.png "Result")
