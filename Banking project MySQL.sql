/* =========================================================
   PROJECT: BANKING CUSTOMER ANALYTICS
   =========================================================

   Domain: Banking & Financial Analytics

   Objective:
   Analyze customer data to uncover insights related to:
   - Customer segmentation
   - Risk exposure
   - Regional performance
   - Branch-level contribution

   Tools Used:
   - SQL (MySQL)
   - Data Cleaning & Transformation
   - Aggregations & Window Functions

   Dataset:
   Contains customer demographics, income, loans,
   deposits, credit score, and risk classification.

   Outcome:
   Identified high-value customers, risk distribution,
   and key regions contributing to bank performance.

========================================================= */


/* =========================================================
   DATABASE SETUP
   ========================================================= */

CREATE DATABASE banking;
USE banking;


/* =========================================================
   DATA CLEANING & TRANSFORMATION
   ========================================================= */

-- Fix encoding issue
ALTER TABLE customer
CHANGE COLUMN `ï»¿Customer_ID` Customer_ID VARCHAR(50);

-- Standardize column names
ALTER TABLE customer 
RENAME COLUMN `Branch type` TO Branch_type;

ALTER TABLE customer
CHANGE COLUMN `Debt to Income (DTI)` DTI DECIMAL(10,2);

ALTER TABLE customer 
CHANGE COLUMN Customer_name Customer_Name VARCHAR(100);

ALTER TABLE customer 
CHANGE COLUMN Net_Worth Net_Worth DECIMAL(15,2);

-- Handle missing values
UPDATE customer
SET Annual_Income = 0
WHERE Annual_Income IS NULL;

-- Create Age Group column
ALTER TABLE customer ADD Age_Group VARCHAR(20);

UPDATE customer
SET Age_Group = 
CASE 
  WHEN Age < 30 THEN 'Young'
  WHEN Age BETWEEN 30 AND 50 THEN 'Middle Age'
  ELSE 'Senior'
END;

-- Data Validation: Check duplicates
SELECT Customer_ID, COUNT(*) AS duplicate_count
FROM customer
GROUP BY Customer_ID
HAVING COUNT(*) > 1;


/* =========================================================
   PERFORMANCE OPTIMIZATION (INDEXING)
   ========================================================= */

CREATE INDEX idx_region ON customer(Region);
CREATE INDEX idx_risk ON customer(Risk_Category);
CREATE INDEX idx_income ON customer(Annual_Income);


/* =========================================================
   CUSTOMER INSIGHTS
   ========================================================= */

-- Insight 1: Top 5 customers by net worth
SELECT 
Customer_Name, 
Net_Worth
FROM customer
ORDER BY Net_Worth DESC
LIMIT 5;

-- Insight:
-- A small group of customers contributes significantly 
-- to total wealth, indicating high-value segments.


-- Insight 2: Customer distribution by age group
SELECT 
Age_Group,
COUNT(*) AS total_customers
FROM customer
GROUP BY Age_Group;

-- Insight:
-- Helps understand which age segment dominates the customer base.


-- Insight 3: Customers earning above average income
SELECT 
Customer_Name, 
Annual_Income
FROM customer
WHERE Annual_Income > (
    SELECT AVG(Annual_Income) FROM customer
);

-- Insight:
-- These customers can be targeted for premium banking services.


/* =========================================================
   ADVANCED ANALYSIS (ADDED FOR PORTFOLIO STRENGTH)
   ========================================================= */

-- Insight 4: Customer Segmentation based on Net Worth
SELECT 
Customer_Name,
Annual_Income,
Net_Worth,
CASE 
  WHEN Net_Worth > 1000000 THEN 'High Value'
  WHEN Net_Worth BETWEEN 500000 AND 1000000 THEN 'Mid Value'
  ELSE 'Low Value'
END AS customer_segment
FROM customer;

-- Insight:
-- Helps in targeted marketing and wealth management strategies.


-- Insight 5: Rank customers by income
SELECT 
Customer_Name,
Annual_Income,
RANK() OVER (ORDER BY Annual_Income DESC) AS income_rank
FROM customer;

-- Insight:
-- Identifies top earning customers for cross-selling opportunities.


-- Insight 6: Running total of loans by region
SELECT 
Customer_Name,
Region,
Loan_amount,
SUM(Loan_amount) OVER (PARTITION BY Region ORDER BY Loan_amount DESC) AS running_total
FROM customer;

-- Insight:
-- Shows cumulative loan distribution across regions.


/* =========================================================
   RISK ANALYSIS
   ========================================================= */

-- Insight 7: Risk category distribution
SELECT 
Risk_Category,
COUNT(*) AS total_customers,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM customer
GROUP BY Risk_Category;

-- Insight:
-- Helps assess overall risk exposure in the customer base.


-- Insight 8: Total exposure to high-risk customers
SELECT 
SUM(CASE 
    WHEN Risk_Category = 'High Risk' THEN Net_Worth 
    ELSE 0 
END) AS high_risk_exposure
FROM customer;

-- Insight:
-- High exposure may indicate potential financial instability.


-- Insight 9: Risk classification based on credit score & DTI
SELECT 
Customer_Name,
Credit_Score,
DTI,
CASE 
  WHEN Credit_Score < 600 AND DTI > 0.4 THEN 'High Risk'
  WHEN Credit_Score < 700 THEN 'Medium Risk'
  ELSE 'Low Risk'
END AS risk_level
FROM customer;

-- Insight:
-- Combines financial indicators to better evaluate risk.


/* =========================================================
   BANK PERFORMANCE
   ========================================================= */

-- Insight 10: Loan-to-Deposit Ratio (LDR)
SELECT 
Region,
SUM(Loan_amount) AS total_loans,
SUM(Bank_Deposits) AS total_deposits,
ROUND(SUM(Loan_amount) / NULLIF(SUM(Bank_Deposits),0) * 100, 2) AS LDR
FROM customer
GROUP BY Region
ORDER BY LDR DESC;

-- Insight:
-- Higher LDR indicates aggressive lending strategy.


-- Insight 11: Regions with highest loan contribution
SELECT 
Region,
SUM(Loan_amount) AS total_loans
FROM customer
GROUP BY Region
ORDER BY total_loans DESC;

-- Insight:
-- Identifies top-performing regions in lending.


-- Insight 12: Overall financial health
SELECT 
SUM(Bank_Deposits) AS total_deposits,
SUM(Loan_amount) AS total_loans,
SUM(Net_Worth) AS total_net_worth,
AVG(Annual_Income) AS avg_income
FROM customer;

-- Insight:
-- Provides a snapshot of bank’s financial position.


/* =========================================================
   BRANCH ANALYSIS
   ========================================================= */

-- Insight 13: Branch with highest lending
SELECT 
Branch_name,
SUM(Business_Lending) AS total_lending
FROM customer
GROUP BY Branch_name
ORDER BY total_lending DESC;

-- Insight:
-- Helps identify top-performing branches.


-- Insight 14: Top branch in each region
WITH ranked_branch AS (
    SELECT 
        Region,
        Branch_name,
        SUM(Business_Lending) AS total_lending,
        ROW_NUMBER() OVER (
            PARTITION BY Region 
            ORDER BY SUM(Business_Lending) DESC
        ) AS rn
    FROM customer
    GROUP BY Region, Branch_name
)
SELECT *
FROM ranked_branch
WHERE rn = 1;

-- Insight:
-- Highlights best-performing branch per region.