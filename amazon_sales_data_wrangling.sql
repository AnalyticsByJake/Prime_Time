-- DATASET USED: https://www.kaggle.com/datasets/arpit2712/amazonsalesreport
-- ------------
-- Import OG data tables before running code below
-- Cleaned data tables can be used with analysis queries directly

-- ======================== AMAZON SALES DATABASE CREATION AND CLEANING ========================
-- _____________________________________________________________________________________________



-- SECTIONS:
-- A.) Check for Duplicate Rows 
-- B.) Create / Drop Fields 
-- C.) Data Wrangling 
-- D.) Create Indexes


-- TABLES:
-- 1.) amazon_sales


-- ALIASES
-- ams = amazon_sales



-- ========================================= SECTION A ========================================
-- ================================= CHECK FOR DUPLICATE ROWS =================================
-- ____________________________________________________________________________________________
-- The following code check for duplicates and, if necessary, drop the duplicates.
-- Comments for first query can be applied to all following.


-- CHECK_FOR_DUPLICATES
-- ____________________

-- checks for duplicate rows

SELECT *
FROM amazon_sales
WHERE `index` IN (
	SELECT `index`
    FROM amazon_sales
    GROUP BY `index`
    HAVING COUNT(*) > 1
);


-- if row was found, run this code (adjust to proper criteria - I found no duplicate rows)

DELETE
FROM amazon_sales
WHERE `index` IS NULL
	OR `index` = '';





-- ========================================= SECTION B =========================================
-- =================================== CREATE / DROP FIELDS ====================================
-- _____________________________________________________________________________________________
-- Corrects data types for each table (the original data type largely categorizes them as TEXT)
-- To improve efficiency, all "MODIFY" statements can be combined at the end of each table.
-- The repetitive form was chosen for visibility only


-- CREATE ORDER_MONTH COLUMN
-- _________________________
-- this will help with calculations involving months

ALTER TABLE amazon_sales
ADD COLUMN order_month INT;

UPDATE amazon_sales
SET order_month = MONTH(order_date);


-- CREATE ORDER_DAY COLUMN
-- _______________________
-- this will help with calculations involving days or day ranges

ALTER TABLE amazon_sales
ADD COLUMN order_day INT;

UPDATE amazon_sales
SET order_day = DAY(order_date);


-- DROP `NEW` COLUMN
-- _________________
-- this row is completely null of data, so nothing is lost and space is saved

ALTER TABLE amazon_sales
DROP COLUMN `new`;


-- DROP PENDINGS COLUMN
-- _________________
-- this row is completely null of data, so nothing is lost and space is saved

ALTER TABLE amazon_sales
DROP COLUMN pendings;




-- ========================================= SECTION C ========================================
-- ====================================== DATA WRANGLING ======================================
-- ____________________________________________________________________________________________
-- Corrects data types for each table (the original data type largely categorizes them as TEXT)
-- To improve efficiency, all "MODIFY" statements can be combined at the end of each table.
-- The repetitive form was chosen for visibility only



-- REMOVE '.in' FROM SALES_CHANNEL FIELD
-- _____________________________________
-- note that the '.in' is for Amazon India

UPDATE amazon_sales
SET sales_channel = 'Amazon'
WHERE sales_channel = 'Amazon.in';




-- STANDARDIZE(-ISH) SHIP_CITY FIELD
-- _____________________________________
-- the cities are still quite a mess, but this helps quite a bit with readability
-- it also salvages some usable data


-- query to trim leading and trailing '' and '.' (TRIM), as well as other non-numeric characters (REGEX)

SELECT
	TRIM(
		BOTH '.' FROM
        REGEXP_REPLACE(LOWER(TRIM(ship_city)), '[^a-z0-9\s,/-]+', '')
	) AS cleaned_city
FROM amazon_sales
WHERE ship_city IS NOT NULL
	AND ship_city RLIKE '[a-zA-Z]'
ORDER BY 1;


-- this applies the reformatting to column

UPDATE amazon_sales
SET ship_city = TRIM(
					BOTH ',' FROM
						TRIM(
							BOTH '.' FROM
							REGEXP_REPLACE(LOWER(TRIM(ship_city)), '[^a-z0-9\s,/-]+', '')
						)
)
WHERE ship_city IS NOT NULL
	AND ship_city RLIKE '[a-zA-Z]';




-- STANDARDIZE(-ISH) SHIP_CITY FIELD
-- _________________________________
-- the states are far more manageable. 
-- uses TRIM() and LOWER(), then corrects city variation duplicates


UPDATE amazon_sales
SET ship_state = TRIM(LOWER(ship_state))
WHERE ship_state IS NOT NULL;

SELECT
	DISTINCT ship_state
FROM amazon_sales
ORDER BY 1;


-- changes 'delhi' to 'new delhi'

UPDATE amazon_sales
SET ship_state = 'new delhi'
WHERE ship_state = 'delhi';


-- changes 'orissa' to 'odisha'

UPDATE amazon_sales
SET ship_state = 'odisha'
WHERE ship_state = 'orissa';


-- changes 'rajshthan', 'rj' and 'rajasthan' to 'rajsthan'

UPDATE amazon_sales
SET ship_state = 'rajsthan'
WHERE ship_state = 'rajshthan'
	OR ship_state = 'rajasthan'
    OR ship_state = 'rj';


-- changes 'puducherry' to 'pondicherry'

UPDATE amazon_sales
SET ship_state = 'pondicherry'
WHERE ship_state = 'puducherry';


-- changes 'punja', 'pb' and 'punjab/mohali/zirakpur' to 'punjab'

UPDATE amazon_sales
SET ship_state = 'punjab'
WHERE ship_state = 'punja'
	OR ship_state = 'punjab/mohali/zirakpur'
	OR ship_state = 'pb';


-- changes 'nl' to 'nagaland'

UPDATE amazon_sales
SET ship_state = 'nagaland'
WHERE ship_state = 'nl';


-- changes 'apo' to 'andaman & nicobar'

UPDATE amazon_sales
SET ship_state = 'andaman & nicobar'
WHERE ship_state = 'apo';


-- changes 'ar' to 'andhra pradesh'

UPDATE amazon_sales
SET ship_state = 'andhra pradesh'
WHERE ship_state = 'ar';


-- changes remaining blank values to NULL 

UPDATE amazon_sales
SET ship_state = NULL
WHERE ship_state = '';



-- NOTE ON SHIP_COUNTRY FIELD
-- __________________________
-- there are 33 null values here. I opted to leave them as is since
-- there is only one country for the rest of the values (and thus not
-- necessary since we won't use this field). One can assume they are
-- likely 'IN' as well.




-- CHANGE IS_FULFILLED TO BOOLEAN
-- ______________________________
-- the only option for fulfilling orders is "Easy Ship"
-- I thus changed the name of this column and converted
-- the data type to a BOOLEAN


-- renames 'fulfilled_by' to 'easy_ship'

ALTER TABLE amazon_sales
RENAME COLUMN fulfilled_by TO easy_ship;


-- converts values in easy_ship to 1 or 0

UPDATE amazon_sales
SET easy_ship = 0
WHERE easy_ship IS NULL
	OR easy_ship = '';

UPDATE amazon_sales
SET easy_ship = 1
WHERE easy_ship = 'Easy Ship';


-- converts easy_ship to BOOLEAN

ALTER TABLE amazon_sales
MODIFY easy_ship TINYINT(1);





-- ========================================= SECTION D ========================================
-- ====================================== CREATE INDEXES ======================================
-- ____________________________________________________________________________________________
-- these indexes are meant to help with the performance of the DA queries


-- To check existing indexes

SHOW INDEX
FROM amazon_sales;



-- indexes for time analysis

CREATE INDEX idx_order_day
	ON amazon_sales(order_day);

CREATE INDEX idx_order_month
	ON amazon_sales(order_month);

CREATE INDEX idx_order_date
	ON amazon_sales(order_date);



-- indexes for sum

CREATE INDEX idx_category_amount
	ON amazon_sales(category, amount);

CREATE INDEX idx_size_category
	ON amazon_sales(size, category);

CREATE INDEX idx_easy_ship
	ON amazon_sales(easy_ship);



-- indexes for location

CREATE INDEX idx_state_amount
	ON amazon_sales(ship_state, amount);

CREATE INDEX idx_city_state
	ON amazon_sales(ship_city, ship_state);
    
