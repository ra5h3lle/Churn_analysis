--- View the first 100 rows of the customers table
SELECT * 
FROM public."customers"
	limit(100);
--- View the first 100 rows of the subscription table
SELECT *
FROM public."subscriptions"
	limit(100);
--- From our discovery, we would like the columns; SeniorCitizen, Partner and Dependents from the customers table to be boolean.
ALTER TABLE public."customers"
	ALTER COLUMN "SeniorCitizen" TYPE BOOLEAN USING ("SeniorCitizen" = 1),
	ALTER COLUMN "Partner" TYPE BOOLEAN USING ("Partner" = 'Yes'),
	ALTER COLUMN "Dependents" TYPE BOOLEAN USING ("Dependents" = 'Yes');
--- Checking the first 10 rows of the customers table for the new data type.
SELECT *
FROM public."customers"
LIMIT(10);
---Count the rows on the customers table.
SELECT COUNT(*)
FROM public."customers";
---Count the rows on the subscriptions table.
SELECT COUNT(*)
FROM public."subscriptions";
---Verify Foreign key integrity.
SELECT "customerID" 
FROM "subscriptions" 
WHERE "customerID" NOT IN (SELECT "ID" FROM "customers");
--- Check for NULLS IN ids in customers table
SELECT *
FROM public.customers
WHERE "ID" IS NULL;
--- Check for NULLS in ids in subscriptions table
SELECT *
FROM subscriptions
WHERE "ID" IS NULL;
--- Calculate the distribution of customers by Gender
SELECT "gender", COUNT(*) AS count
FROM "customers"
GROUP BY "gender";
--- Calculate the distribution of customers by SeniorCitizen
SELECT "SeniorCitizen", COUNT(*) AS count
FROM "customers"
GROUP BY "SeniorCitizen";
--- Analyzing partner status
SELECT "Partner", COUNT (*) AS Count
FROM customers
GROUP BY "Partner";
--- Analyzing dependent status
SELECT "Dependents", COUNT (*) AS Count
FROM customers
GROUP BY "Dependents";
--Calculate the distribution of customers by their contract type.
SELECT "Contract", COUNT (*) AS Count
FROM subscriptions
GROUP BY "Contract";
--Analyzing Churn by Contract Type. Calculating the number of churned customers by contract type.
SELECT "Contract", "Churn", COUNT(*) AS count
FROM subscriptions
GROUP BY "Contract", "Churn"
ORDER BY count DESC;
-- Calculating the churn rate for each contract type.
SELECT "Contract", 
COUNT(*) FILTER (WHERE "Churn" = 'Yes') * 100/ COUNT(*) AS Churnrate
FROM subscriptions
GROUP BY "Contract"
ORDER BY Churnrate DESC;
--Analyzing Churn by Internet Service Type. Calculating the churn rate for each internet service type. 
SELECT "InternetService", 
COUNT(*) FILTER(WHERE "Churn" = 'Yes')* 100/COUNT(*) AS Churnrate_by_internetservice
FROM subscriptions
GROUP BY "InternetService"
ORDER BY Churnrate_by_internetservice DESC;
-- Calculatimg the average monthly charges for customers who churned
SELECT 
    "Churn",
    AVG("MonthlyCharges") AS avg_monthly_charges
FROM 
    subscriptions
GROUP BY 
    "Churn";
-- calculating the average customer lifetime (in months) for both churned and active customers
WITH customer_lifetime AS (
    SELECT 
        "customerID",
        "Churn",
        "tenure" AS lifetime_months
    FROM 
        subscriptions
)
SELECT 
    "Churn",
    AVG(lifetime_months) AS avg_lifetime
FROM 
    customer_lifetime
GROUP BY 
    "Churn";
-- To understand retention over time, let’s categorize customers into tenure buckets (e.g., 1-12 months, 13-24 months, etc.) and calculate the retention rate within each bucket.
WITH tenure_buckets AS (
    SELECT 
        "customerID",
        "Churn",
        CASE 
            WHEN "tenure" BETWEEN 1 AND 12 THEN '1-12 months'
            WHEN "tenure" BETWEEN 13 AND 24 THEN '13-24 months'
            WHEN "tenure" BETWEEN 25 AND 36 THEN '25-36 months'
            WHEN "tenure" BETWEEN 37 AND 48 THEN '37-48 months'
            WHEN "tenure" BETWEEN 49 AND 60 THEN '49-60 months'
            ELSE '60+ months'
        END AS tenure_bucket
    FROM 
        subscriptions
)
SELECT 
    tenure_bucket,
    COUNT(*) FILTER (WHERE "Churn" = 'No') * 100.0 / COUNT(*) AS retention_rate
FROM 
    tenure_buckets
GROUP BY 
    tenure_bucket
ORDER BY 
    tenure_bucket;
-- examine if senior citizens have different retention patterns than non-senior customers by joining customers with subscriptions.
WITH tenure_buckets AS (
    SELECT 
        s."customerID",
        s."Churn",
        c."SeniorCitizen",
        CASE 
            WHEN s."tenure" BETWEEN 1 AND 12 THEN '1-12 months'
            WHEN s."tenure" BETWEEN 13 AND 24 THEN '13-24 months'
            WHEN s."tenure" BETWEEN 25 AND 36 THEN '25-36 months'
            WHEN s."tenure" BETWEEN 37 AND 48 THEN '37-48 months'
            WHEN s."tenure" BETWEEN 49 AND 60 THEN '49-60 months'
            ELSE '60+ months'
        END AS tenure_bucket
    FROM 
        subscriptions AS s
    JOIN 
        customers AS c
    ON 
        s."customerID" = c."ID"
)
SELECT 
    "SeniorCitizen",
    tenure_bucket,
    COUNT(*) FILTER (WHERE "Churn" = 'No') * 100.0 / COUNT(*) AS retention_rate
FROM 
    tenure_buckets
GROUP BY 
    "SeniorCitizen", tenure_bucket
ORDER BY 
    retention_rate DESC;
