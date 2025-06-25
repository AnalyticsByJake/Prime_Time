-- DATASET USED: https://www.kaggle.com/datasets/arpit2712/amazonsalesreport
-- ------------
-- Cleaned data tables can be used with analysis queries directly


-- ================================ AMAZON SALES DATA ANALYSIS ================================
-- ____________________________________________________________________________________________


-- SECTIONS:
	-- A.) Key Performance Indicator Analysis (General and Monthly)
	-- B.) Time Data Analysis
	-- C.) Fulfillment and Shipping Analysis
	-- D.) Category and Product Analysis
	-- E.) Location Data Analysis
	-- F.) Performance Analysis


-- TABLES:
	-- 1.) amazon_sales


-- ALIASES
	-- ams = amazon_sales


-- ========================================= SECTION A ========================================
-- =========================== KEY PERFORMANCE INDICATORS CALCULATOR ==========================
-- ____________________________________________________________________________________________
-- A KPI calculator has been made to determine metrics both at the level of the whole recorded 
-- timeline (first query) and a monthly breakdown (second query), some of which is customizable.
-- The KPIs are broken down by category consider the following fields (note that some are only 
-- available in the monthly breakdown): 
	-- (1) Average order value by category,
	-- (2) Deviation from overall monthly average order value (as a %),*
	-- (3) Total revenue by category for each month,*
	-- (4) Total (monthly) revenue (all categories),
	-- (5) Revenue percentage contributed by category,
	-- (6) Number of pending orders,
	-- (7) Number of cancelled orders,
	-- (8) Total number of shipments (excluding lost/damaged),
	-- (9) Successful shipment rate per category for each month.
			-- * indicates it is only for the monthly breakdown


-- GENERAL KEY PERFORMANCE INDCATOR CALCULATOR
-- ___________________________________________


WITH total_order_value AS (
	SELECT
		SUM(amount) AS tot_ord_val, -- calculates total sales across all categories
        AVG(amount) AS tot_avg_val -- calculates avg order value across all categories
    FROM amazon_sales
), 
order_value_category AS (
	SELECT
		category,
        SUM(amount) AS cat_ord_val, -- calculates total sales by category
        AVG(amount) AS cat_avg_val -- calculates avg order value by category
	FROM amazon_sales
    GROUP BY category
),
pending_orders AS (
	SELECT
		category,
        COUNT(`status`) AS pending_count -- calculates count of pending orders
	FROM amazon_sales
	WHERE `status` IN ('Pending', 'Pending - Waiting for Pickup')
    GROUP BY category
),
cancelled_orders AS (
	SELECT
		category,
        COUNT(`status`) AS cancelled_count -- calculates count of cancelled/returned orders
	FROM amazon_sales
    WHERE `status` IN ('Cancelled',
                        'Shipped - Rejected by Buyer',
                        'Shipped - Returned to Seller',
                        'Shipped - Returning to Seller')
    GROUP BY category
), 
total_shipments AS (
	SELECT
		category,	
        COUNT(`status`) total_ship -- calculates total successful orders
	FROM amazon_sales
    WHERE `status` NOT IN (
						'Shipped - Damaged',
                        'Shipped - Lost in Transit') -- ensures "damaged" and "lost" omitted
	GROUP BY category
)
SELECT 
	ovc.category,
    ROUND(cat_avg_val, 2) AS avg_price, -- calculates avg order value by category
    ROUND((tov.tot_avg_val - ovc.cat_avg_val) / tov.tot_avg_val * 100, 2) AS perc_from_avg, -- calculates difference from avg
    ovc.cat_ord_val AS total_cat_price, -- calculates total sales by category
    tov.tot_ord_val AS overall_price, -- calculates total sales for all categories
    ROUND((ovc.cat_ord_val / tov.tot_ord_val) * 100, 2) AS sales_perc, -- calculates percentage of overall sales by category
    po.pending_count AS pending_orders, -- calculates # of pending orders
    co.cancelled_count AS cancelled_orders, -- calculates # of cancelled/returned orders
    ts.total_ship, -- calculates # successful shipments
    ROUND((ts.total_ship - (po.pending_count + co.cancelled_count)) / ts.total_ship * 100, 2) AS success_perc -- calculates success rate of shipments
FROM order_value_category ovc
JOIN total_order_value tov
	ON 1=1
JOIN pending_orders po
	ON ovc.category = po.category
JOIN cancelled_orders co
	ON ovc.category = co.category
JOIN total_shipments ts
	ON ovc.category = ts.category
ORDER BY category;



-- MONTHLY KEY PERFORMANCE INDICATOR CALCULATOR
-- ____________________________________________


WITH total_order_value AS (
	SELECT
		order_month,
		SUM(amount) AS tot_ord_val, -- calculates total sales across all categories by month
        AVG(amount) AS tot_avg_val -- calculates avg order value across all categories by month
    FROM amazon_sales
    GROUP BY order_month
), 
order_value_category AS (
	SELECT
		category,
        order_month,
        SUM(amount) AS cat_ord_val, -- calculates total monthly sales by category
        AVG(amount) AS cat_avg_val -- calculates monthly avg order value  by category
	FROM amazon_sales
    GROUP BY category, order_month
),
pending_orders AS (
	SELECT
		category,
        order_month,
        COUNT(`status`) AS pending_count -- calculates count of pending orders by month
	FROM amazon_sales
	WHERE `status` IN ('Pending', 'Pending - Waiting for Pickup')
    GROUP BY category, order_month
),
cancelled_orders AS (
	SELECT
		category,
        order_month,
        COUNT(`status`) AS cancelled_count -- calculates count of cancelled/returned orders by month
	FROM amazon_sales
    WHERE `status` IN ('Cancelled',
                        'Shipped - Rejected by Buyer',
                        'Shipped - Returned to Seller',
                        'Shipped - Returning to Seller')
    GROUP BY category, order_month
), 
total_shipments AS (
	SELECT
		category,	
        order_month,
        COUNT(`status`) total_ship -- calculates total successful orders by month
	FROM amazon_sales
    WHERE `status` NOT IN (
						'Shipped - Damaged',
                        'Shipped - Lost in Transit') -- ensures "damaged" and "lost" omitted
	GROUP BY category, order_month
)
SELECT 
	ovc.category,
    CASE
		WHEN ovc.order_month = 3 THEN 'March'
        WHEN ovc.order_month = 4 THEN 'April'
        WHEN ovc.order_month = 5 THEN 'May'
        WHEN ovc.order_month = 6 THEN 'June'
	END AS `month`, -- calculates month names in place of index
    ROUND(cat_avg_val, 2) AS avg_price, -- calculates monthly avg order value by category
    ROUND((tov.tot_avg_val - ovc.cat_avg_val) / tov.tot_avg_val * 100, 2) AS perc_from_avg, -- calculates difference from monthly avg
    ovc.cat_ord_val AS total_cat_price, -- calculates total monthly sales for all categories
    tov.tot_ord_val AS overall_price, -- calcualtes total sales for month
    ROUND((ovc.cat_ord_val / tov.tot_ord_val) * 100, 2) AS sales_perc, -- calculates percentage of overall monthly sales by category
    CASE
		WHEN po.pending_count IS NULL THEN 0
        ELSE po.pending_count
	END AS pending_orders, -- calcualtes # of pending orders
    CASE
		WHEN co.cancelled_count IS NULL THEN 0
        ELSE co.cancelled_count
	END AS cancelled_orders, -- calcualtes # of cancelled/pending orders by month
    ts.total_ship, -- calcualtes # of successful orders by month
    ROUND((ts.total_ship - (IFNULL(po.pending_count, 0) + IFNULL(co.cancelled_count, 0))) / ts.total_ship * 100, 2) AS success_perc -- calculates shipment success rate by month
FROM order_value_category ovc
JOIN total_order_value tov
	ON ovc.order_month = tov.order_month
LEFT JOIN pending_orders po
	ON ovc.category = po.category
	AND ovc.order_month = po.order_month
LEFT JOIN cancelled_orders co
	ON ovc.category = co.category
	AND ovc.order_month = co.order_month
LEFT JOIN total_shipments ts
	ON ovc.category = ts. category
	AND ovc.order_month = ts.order_month
ORDER BY category, ts.order_month;





-- ========================================= SECTION B ========================================
-- ==================================== TIME DATA ANALYSIS ====================================
-- ____________________________________________________________________________________________
-- NOTE: the month of March is included, but only contains one day of transactions; it has 
	-- thus been removed from some queries so as not to skew results



-- -------> 1.) WHAT IS THE TOTAL MONTHLY ORDER VALUE OVER TIME?
-- _____________________________________________________________


-- selects total order value of sales by month
	-- great for initial breakdown of monthly value processing
    -- great for simple bar graph


SELECT
	CASE
		WHEN order_month = 3 THEN 'March'
        WHEN order_month = 4 THEN 'April'
        WHEN order_month = 5 THEN 'May'
        WHEN order_month = 6 THEN 'June'
    END AS `month`, -- calculates month names in place of index
    SUM(amount) AS total_order_value -- calculates overall order value
FROM amazon_sales
GROUP BY order_month -- groups by month
ORDER BY order_month;



-- -------> 2.) WHAT IS THE MONTH-OVER-MONTH GROWTH RATE?
-- _________________________________________________________


-- selects the percentage of growth for the months of May and June
	-- helpful in indicaating business trends
    -- a longer time frame would be good for time-series line graph


WITH monthly_data AS (
    SELECT
        order_month,
        SUM(amount) AS monthly_revenue -- calculates total monthly sales
    FROM amazon_sales
    GROUP BY order_month
),
monthly_growth AS (
    SELECT
        order_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER(ORDER BY order_month) AS prev_month_rev, -- calculates previous month's total sales
        ROW_NUMBER() OVER(ORDER BY order_month) AS rn
    FROM monthly_data
)
SELECT
	CASE
		WHEN order_month = 3 THEN 'March'
        WHEN order_month = 4 THEN 'April'
        WHEN order_month = 5 THEN 'May'
        WHEN order_month = 6 THEN 'June'
	END AS `month`, -- calculates month names in place of index
    monthly_revenue,
    prev_month_rev,
    CASE
        WHEN rn <= 2 THEN NULL -- ensures March and April omitted
        ELSE ROUND((monthly_revenue / prev_month_rev) * 100, 2)
    END AS growth_rate
FROM monthly_growth
ORDER BY order_month;



-- -------> 3.) WHAT IS THE DAILY RUNNING TOTAL BY MONTH?
-- _________________________________________________________


-- selects the daily sum and running total of sales by month 
	-- helps identify sales momentum and daily surges


SELECT
	order_month,
    order_day,
    SUM(amount) AS daily_sum,
    SUM(SUM(amount)) OVER(PARTITION BY order_month ORDER BY order_day 
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_amount -- calculates the daily running total by month
FROM amazon_sales
GROUP BY order_month, order_day
ORDER BY order_month, order_day;



-- -------> 4.) WHAT IS THE DAILY ROLLING AVERAGE BY DAY?
-- _________________________________________________________


-- selects the daily running avg by month 
	-- highlights short-term changes in avg order value


WITH run_avg AS (
	SELECT
		order_month,
		order_day,
		ROUND(AVG(amount), 2) avg_total, -- calculates daily avg
		AVG(ROUND(AVG(amount), 2)) OVER(PARTITION BY order_month ORDER BY order_day 
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_avg -- calculates daily rolling total by month
	FROM amazon_sales
	GROUP BY order_month, order_day
)
SELECT
	order_month,
    order_day,
    avg_total,
    ROUND(running_avg, 2) run_avg,
    ROUND(((avg_total - running_avg) / running_avg) * 100, 2) AS perc_change -- calcualtes daily % change in running avg
FROM run_avg
ORDER BY order_month, order_day;



-- -------> 5.) WHAT IS THE AVERAGE ORDER VALUE IN 5 DAY INCREMENTS?
-- _________________________________________________________________


-- selects the daily sum and running total of sales by month 
	-- highlights smaller changes for each month


WITH day_brackets AS (
	SELECT
		order_month,
        order_day,
        amount,
        qty,
		CASE
			WHEN order_day BETWEEN 1 AND 5 THEN '01-5'
			WHEN order_day BETWEEN 6 AND 10 THEN '06-10'
			WHEN order_day BETWEEN 11 AND 15 THEN '11-15'
			WHEN order_day BETWEEN 16 AND 20 THEN '16-20'
			WHEN order_day BETWEEN 21 AND 25 THEN '21-25'
			WHEN order_day BETWEEN 26 AND 31 THEN '26-31'
		END AS day_range -- calculates day ranges in increments of 5 days (6 days for 25-31)
	FROM amazon_sales
),
avg_sales AS (
	SELECT
		order_month,
        day_range,
        SUM(amount) / SUM(qty) as avg_order_value -- calcualtes avg order value by day bracket
	FROM day_brackets
    GROUP BY order_month, day_range
),
agg_avg_order AS (
	SELECT
		order_month,
		day_range,
		avg_order_value,
		LAG(avg_order_value) OVER(ORDER BY order_month, day_range) AS prev_order_avg -- calculates avg order value for previous day
	FROM avg_sales
)
SELECT
	order_month,
    day_range,
    ROUND(avg_order_value, 2) AS avg_ord_val,
    ROUND(prev_order_avg, 2) AS prev_ord_val,
    ROUND(((avg_order_value - prev_order_avg) / prev_order_avg) * 100, 2) growth_rate -- calculates growth rate for day brackets
FROM agg_avg_order
ORDER BY order_month, day_range;





-- ========================================= SECTION C ========================================
-- ============================= FULFILLMENT AND SHIPPING ANALYSIS ============================
-- ____________________________________________________________________________________________



-- -------> 6.) HOW DO AMAZON'S DELIVERIES COMPARE TO OTHER PROVIDERS?
-- ___________________________________________________________________


-- selects count of shipping service and current status by provider
	-- helpful in determining types of shipping, even reliability of shipping
    -- great candidate for a bar graph (perhaps even the notorious "pie" chart with listed percentages)
    
    
SELECT 
	fulfilment AS provider, -- determines service provider
    ship_service_level AS ship_service, -- calcualtes type of shipment
    COUNT(ship_service_level) AS ship_count, -- calculates number of shipment by previous fields
    `status` AS curr_status, -- calculates current shipment status
    COUNT(`status`) AS status_count -- calculates the # of status orders
FROM amazon_sales
GROUP BY fulfilment, ship_service_level, `status` -- groups by provider, shipping service and status
ORDER BY fulfilment, ship_service, curr_status;



-- -------> 7.) HOW DO DELIVERY SERVICES CORRESPOND TO AVERAGE ORDER VALUE?
-- ________________________________________________________________________


-- selects avg, max and min sales by shipping service (expedited or standard)
	-- there is also the option to break these down by month if uncommented
    -- great candidate for bar graph or time-series line graph


SELECT
	ship_service_level AS type_of_ship, -- calculates shipment method
	-- uncomment to add month to query
	-- order_month AS `month`,
	ROUND(SUM(amount) / SUM(qty), 2) AS avg_order_value, -- calculates average order value
	ROUND(MAX(amount / qty), 2) AS max_avg_ord_val, -- calculates max avg order value
	ROUND(MIN(amount / qty), 2) AS min_avg_ord_val -- calculates min avg order value
FROM amazon_sales
WHERE amount != 0 -- this excludes "free" items (see next query)
GROUP BY ship_service_level
	-- uncomment to add month to query
    -- , order_month
ORDER BY ship_service_level
	-- uncomment to include order month
    -- , order_month
;



-- -------> 8.) ARE FREE ITEMS NORMALLY SHIPPED STANDARD OR EXPEDITED?
-- ________________________________________________________________________
-- note that all 'free' items are only shipped by Amazon, never an external provider


-- selects num of free items by shipping service (expedited or standard)
	-- there is also the option to break these down by month if uncommented
    -- could be compared to avg monthly sales to see if corresponds
    -- great candidate for bar graph or time-series line graph


SELECT
	ship_service_level AS type_of_ship,
    -- uncomment to add month to query
    -- order_month AS `month`,
    COUNT(amount) AS num_free_items -- calculates # of free items shipped
FROM amazon_sales
	WHERE amount = 0 -- this excludes "free" items (see next query)
GROUP BY ship_service_level
	-- uncomment to include order month
    -- , order_month
ORDER BY ship_service_level
	-- uncomment to include order month
    -- , order_month
;



-- -------> 9.) WHAT IS THE MOST COMMONLY USED SHIPPING LEVEL PER STATE?
-- _____________________________________________________________________


-- selects num of shipments by state, with option to choose by state or above avg shipments
	-- useful for determining market demand for shipping by region
    -- great candidate for bar graph or time-series line graph


-- uncomment blocks of code to find states with above avg shipments
-- WITH avg_ship_count AS (
-- 	SELECT
-- 		AVG(ship_count) AS avg_count
--     FROM (
-- 		SELECT
-- 			ship_state,
-- 			ship_service_level,
-- 			COUNT(ship_service_level) AS ship_count
-- 		FROM amazon_sales
--         WHERE ship_state IS NOT NULL
--         GROUP BY ship_state, ship_service_level
-- 	) AS counts
-- )
SELECT
	ship_state AS state,
	ship_service_level AS type_of_ship, -- calculates type of shipment
    COUNT(ship_service_level) num_shipped -- calculates # of shipment types
FROM amazon_sales
WHERE ship_state IS NOT NULL
	-- uncomment to specify state(s)
	-- AND ship_state = 'bihar'
GROUP BY ship_state, ship_service_level
	-- uncomment blocks of code to find states with above avg shipments
	-- HAVING COUNT(ship_service_level) > (
-- 									SELECT
-- 										avg_count
-- 									FROM avg_ship_count
-- )									
ORDER BY ship_state, ship_service_level;



-- -------> 10.) HOW DOES PROVIDER IMPACT STATUS OF ITEMS?
-- ______________________________________________________


-- selects num of cancelled, pending and shipped compared to overall shipments 
	-- perc of overall shipments by provider has also been included
	-- 'lost' and 'damaged' items were excluded from calculation since there are only 6 items altogether
	-- note that special shipping labels are only available for non-Amazon providers (see query below)
    -- useful for determining reliability of shipment methods
    -- great candidate for side-by-side or stacked bar graphs


WITH cancelled_orders AS (
	SELECT
		fulfilment,
        -- uncomment to include state breakdown
        -- ship_state,
        CASE
			WHEN  `status` IN (
						'Cancelled',
                        'Shipped - Rejected by Buyer',
                        'Shipped - Returned to Seller',
                        'Shipped - Returning to Seller')
				THEN 'Cancelled'
        END AS curr_status, -- calculates count of cancelled/returned orders
        COUNT(`status`) AS num_orders
	FROM amazon_sales
    WHERE `status` IN (
						'Cancelled',
                        'Shipped - Rejected by Buyer',
                        'Shipped - Returned to Seller',
                        'Shipped - Returning to Seller'
		) 
		-- uncomment to include state breakdown
		-- AND ship_state IS NOT NULL    
	GROUP BY fulfilment, curr_status
		-- uncomment to include state breakdown
        -- , ship_state
),
shipped_orders AS (
	SELECT
		fulfilment,
        -- uncomment to include state breakdown
        -- ship_state,
        CASE
			WHEN  `status` IN (
						'shipped', 
                        'shipping', 
                        'Shipped - Delivered to Buyer',
                        'Shipped - Out for Delivery',
                        'Shipped - Picked Up')
				THEN 'Shipped'
        END AS curr_status, -- calculates total successful orders
        COUNT(`status`) AS num_orders
	FROM amazon_sales
    WHERE `status` IN (
						'shipped', 
                        'shipping', 
                        'Shipped - Delivered to Buyer',
                        'Shipped - Out for Delivery',
                        'Shipped - Picked Up'
		)
		-- uncomment to include state breakdown
		-- AND ship_state IS NOT NULL
    GROUP BY fulfilment, curr_status
		-- uncomment to include state breakdown
		-- , ship_state
),
pending_orders AS (
	SELECT
		fulfilment,
        -- uncomment to include state breakdown
        -- ship_state,
        CASE
			WHEN  `status` IN (
						'Pending', 
                        'Pending - Waiting for Pickup')
				THEN 'Pending'
        END AS curr_status, -- calculates count of pending orders
        COUNT(`status`) AS num_orders
	FROM amazon_sales
    WHERE `status` IN (
						'Pending', 
                        'Pending - Waiting for Pickup')
		-- uncomment to include state breakdown
		-- AND ship_state IS NOT NULL
	GROUP BY fulfilment, curr_status
		-- uncomment to include state breakdown
		-- , ship_state
),
total_orders AS (
	SELECT
        COUNT(`status`) AS total_count -- calculates total # of shipments
	FROM amazon_sales
    WHERE `status` NOT IN (
						'Shipped - Damaged',
                        'Shipped - Lost in Transit') -- ensures "damaged" and "lost" omitted
		-- uncomment to include state breakdown
		-- AND ship_state IS NOT NULL
)
SELECT 
	fulfilment AS provider,
    -- uncomment to include state breakdown
    -- ship_state,
    curr_status AS ord_status,
    num_orders,
    ROUND((num_orders / (SELECT total_count
		FROM total_orders)) * 100, 2) AS per_of_ship
FROM cancelled_orders 
UNION
SELECT 
	fulfilment AS provider,
    -- uncomment to include state breakdown
    -- ship_state,
    curr_status AS ord_status,
    num_orders,
    ROUND((num_orders / (SELECT total_count
		FROM total_orders)) * 100, 2) AS per_of_ship
FROM shipped_orders
GROUP BY fulfilment, 
		-- uncomment to include state breakdown
        -- ship_state, 
        curr_status
UNION ALL -- connects all fields into a single table (stacked/grouped)
SELECT 
	fulfilment AS provider,
    -- uncomment to include state breakdown
    -- ship_state,
    curr_status AS ord_status,
    num_orders,
    ROUND((num_orders / (SELECT total_count
		FROM total_orders)) * 100, 2) AS per_of_ship
FROM pending_orders
GROUP BY fulfilment, 
		-- uncomment to include state breakdown
        -- ship_state, 
        curr_status
ORDER BY provider, 
		-- uncomment to include state breakdown
        -- ship_state, 
        ord_status;


-- selects num of shipments by provider based on specialized shipping labels
    -- great candidate for side-by-side or stacked bar graphs


SELECT
	fulfilment AS provider,
	`status` as curr_status,
    COUNT(`status`) AS num_of_occur -- calculates # of times for shipment method
FROM amazon_sales
GROUP BY fulfilment, `status`
ORDER BY fulfilment, `status`;


-- selects all shipping labels, including specialized ones (just for reference)


SELECT
    DISTINCT `status`
FROM amazon_sales;





-- ========================================= SECTION D ========================================
-- =============================== CATEGORY AND PRODUCT ANALYSIS ==============================
-- ____________________________________________________________________________________________



-- -------> 11.) WHICH PRODUCTS GENERATE THE MOST REVENUE?
-- ______________________________________________________


-- selects the total revenue DESC by product category
	-- can be uncommented to group by state or month
    -- useful for determing high and low demand markets
    -- great for side-by-side bar graphs or even time-series line graphs


SELECT
	category,
    -- uncomment to include month or state
    -- order_state AS state,
    -- order_month AS `month`,
    SUM(amount) AS tot_ord_val -- calculates total sales by category
FROM amazon_sales
GROUP BY category
	-- uncomment to include month or state
    -- , order_state 
    -- , order_month 
ORDER BY 
	-- uncomment to include month or state
    -- order_state, 
    -- order_month, 
    tot_ord_val DESC;



-- -------> 12.) HOW IS ORDER VALUE DISTRIBUTED OVER CATEGORY OVER TIME?
-- ____________________________________________________________________


-- selects sum monthly sales by category and the growth rate month-over-month
	-- the month of 'March' has been excluded due to lack of data
    -- great for understanding market distribution
    -- useful for a time-series graph


WITH sum_rev AS (
	SELECT
		category, 
        order_month,
        SUM(amount) AS mon_ord_val
	FROM amazon_sales
    WHERE order_month != 3 -- ensures march is excluded (partial month)
    GROUP BY category, order_month
),
rev_stats AS (
	SELECT 
		category,
		order_month,
		mon_ord_val,
		LAG(mon_ord_val) OVER (PARTITION BY category ORDER BY category, order_month) AS prev_mon_ord_val -- calculates previous month's total order value
	FROM sum_rev
)
SELECT
	category,
    CASE
		WHEN order_month = 4 THEN 'April'
        WHEN order_month = 5 THEN 'May'
        WHEN order_month = 6 THEN 'June'
    END AS `month`, -- calculates month names in place of index
    mon_ord_val,
    prev_mon_ord_val,
    (mon_ord_val - prev_mon_ord_val) / prev_mon_ord_val * 100 AS growth_rate -- calculates growth rate by month
FROM rev_stats   
-- uncomment to search for a specific category
-- WHERE category = 'Blazzer' 
;



-- -------> 13.) WHICH PRODUCT SIZES ARE MOST COMMONLY SOLD PER CATEGORY?
-- _____________________________________________________________________


-- selects total items sold by category in each size
	-- the month of 'March' has been excluded due to lack of data
    -- great for understanding market distribution
    -- useful for a time-series graph


WITH size_chart AS (
	SELECT 
		category,
        size,
		COUNT(size) AS size_count,
		CASE
			WHEN size = 'Free' THEN 0
			WHEN size = 'XS' THEN 1
			WHEN size = 'S' THEN 2
			WHEN size = 'M' THEN 3
			WHEN size = 'L' THEN 4
			WHEN size = 'XL' THEN 5
			WHEN size = 'XXL' THEN 6
			WHEN size = '3XL' THEN 7
			WHEN size = '4XL' THEN 8
			WHEN size = '5XL' THEN 9
			WHEN size = '6XL' THEN 10
		END AS size_class -- calculates an index for sizes of items
	FROM amazon_sales
    GROUP BY category, 
            size, 
            size_class
),
overall_total AS (
	SELECT
		category,
		size,
		size_count,
		SUM(size_count) OVER(PARTITION BY category) AS total_sold, -- calculates total sold within each category
        size_class
	FROM size_chart
)
SELECT 
		category,
		size,
		size_count,
		total_sold,
        ROUND((size_count / total_sold) * 100, 2) AS perc_tot -- calculates % of total for size
	FROM overall_total	
ORDER BY category, size_class;


-- selects the same information as previous query, but breaks it down by month
	-- very helpful in determining issues around stock and demand
    -- useful for stacked bar graphs by month or comparative bar graph by category


WITH size_chart AS (
	SELECT 
		category,
		CASE
			WHEN order_month = 3 THEN 'March'
			WHEN order_month = 4 THEN 'April'
			WHEN order_month = 5 THEN 'May'
			WHEN order_month = 6 THEN 'June'
		END AS `month`, -- calculates month names in place of index
        size,
		COUNT(size) AS size_count,
		CASE
			WHEN size = 'Free' THEN 0
			WHEN size = 'XS' THEN 1
			WHEN size = 'S' THEN 2
			WHEN size = 'M' THEN 3
			WHEN size = 'L' THEN 4
			WHEN size = 'XL' THEN 5
			WHEN size = 'XXL' THEN 6
			WHEN size = '3XL' THEN 7
			WHEN size = '4XL' THEN 8
			WHEN size = '5XL' THEN 9
			WHEN size = '6XL' THEN 10
		END AS size_class -- calculates an index for sizes of items
	FROM amazon_sales
    GROUP BY category, 
			-- uncomment to include month
            `month`,
            size, 
            size_class
),
monthly_total AS (
	SELECT
		category,
		-- uncomment to include month
	   `month`,
		size,
		size_count,
		SUM(size_count) OVER(PARTITION BY category, `month`) AS mon_tot, -- calculates monthly total for each size
        size_class
	FROM size_chart
)
SELECT 
		category,
		-- uncomment to include month
	   `month`,
		size,
		size_count,
		mon_tot,
        ROUND((size_count / mon_tot) * 100, 2) AS perc_tot -- calculates monthly % for each size
	FROM monthly_total	
ORDER BY category, 
	-- uncommen to include month
    `month`,
    size_class;



-- -------> 14.) WHAT ARE THE TRENDS OF B2B ORDERS OVER TIME?
-- _________________________________________________________

    
-- selects total monthly sales and growth rate of b2b sales
	-- the month of 'March' has been excluded due to lack of data
    -- uncomment sections to include category breakdown
    -- great for understanding demand of business market
    -- useful for a time-series graph


WITH monthly_sales AS (
	SELECT 
		b2b,
		-- uncomment to include category
		-- category,
        order_month,
		CASE
			WHEN order_month = 3 THEN 'March'
			WHEN order_month = 4 THEN 'April'
			WHEN order_month = 5 THEN 'May'
			WHEN order_month = 6 THEN 'June'
		END AS `month`, -- calculates month names in place of index
		COUNT(b2b) AS num_sales -- calculates # of b2b sales
	FROM amazon_sales
	WHERE b2b = 1
	GROUP BY b2b, 
		-- uncomment to include category
        -- category, 
        order_month, `month`
),
monthly_difference AS (
	SELECT
		b2b,
		-- uncomment to include category
		-- category,
        order_month,
        `month`,
        num_sales,
        LAG(num_sales) OVER( 
				    -- uncomment to include category
					-- PARTITION BY category
					ORDER BY order_month) AS prev_sales -- calculates previous month's # of b2b sales
	FROM monthly_sales
)
SELECT 
	`month`,
    -- uncomment to include category
    -- category,
    num_sales AS monthly_sales,
    prev_sales AS prev_mon_sales,
    (num_sales - prev_sales) / prev_sales * 100 AS growth_rate -- calculates monthly growth rate of b2b sales
FROM monthly_difference
;



-- -------> 15.) WHAT'S THE RETURN OR CANCELLATION RATE BY CATEGORY?
-- _________________________________________________________

    
-- selects num and perc of orders for each category overall
	-- uncomment at bottom to select specific category/ies
	-- very helpful for predicting return rates and customer satisfaction by products
    -- could be combined with providers (more info would be needed) to find easy competitors to target
    -- useful for a side-by-side or stacked bar graph; traditional bar graph if limited to certain categories


WITH cancelled_orders AS (
	SELECT
		category,
        'Cancelled' AS curr_status,
        COUNT(`status`) AS num_orders -- calculates # of cancelled orders
	FROM amazon_sales
    WHERE `status` IN ('Cancelled') -- ensures only cancelled orders included
	GROUP BY category 
), 
returned_orders AS (
	SELECT
		category,
        'Returned' AS curr_status,
        COUNT(`status`) AS num_orders -- calculates # of returned orders
	FROM amazon_sales
    WHERE `status` IN (
                        'Shipped - Rejected by Buyer',
                        'Shipped - Returned to Seller',
                        'Shipped - Returning to Seller') -- ensures only returned/rejected orders included
	GROUP BY category
),
shipped_orders AS (
	SELECT
		category,
        'Shipped' AS curr_status,
        COUNT(`status`) AS num_orders -- calculates # of successful orders
	FROM amazon_sales
    WHERE `status` IN (
						'Shipped', 
                        'Shipping', 
                        'Shipped - Delivered to Buyer',
                        'Shipped - Out for Delivery',
                        'Shipped - Picked Up') -- ensures only successful orders included
    GROUP BY category 
),
pending_orders AS (
	SELECT
		category,
        'Pending' AS curr_status,
        COUNT(`status`) AS num_orders -- calculates # of pending orders
	FROM amazon_sales
    WHERE `status` IN (
						'Pending', 
                        'Pending - Waiting for Pickup') -- ensures only pending orders included
	GROUP BY category
),
category_totals AS (
	SELECT
		category,
        COUNT(`status`) AS total_count -- calculates total # of orders
	FROM amazon_sales
    WHERE `status` NOT IN (
						'Shipped - Damaged',
                        'Shipped - Lost in Transit'
	) -- ensures "damaged" and "lost" omitted
    GROUP BY category
)
SELECT
	comb.category,
    comb.curr_status,
    comb.num_orders,
    ROUND((comb.num_orders / ct.total_count) * 100, 2) AS perc_by_cat -- calculates % of order statuses by category
FROM (
	SELECT *
    FROM cancelled_orders
    UNION ALL 
    SELECT * 
    FROM returned_orders
    UNION ALL
    SELECT *
    FROM pending_orders
    UNION ALL
    SELECT *
    FROM shipped_orders
) comb -- connects all CTEs together
JOIN category_totals ct
	ON comb.category = ct.category
-- uncomment to look for specific category
-- WHERE comb.category = 'Blazzer'
ORDER BY comb.category, comb.curr_status;





-- ========================================= SECTION E ========================================
-- ================================== LOCATION DATA ANALYSIS ==================================
-- ____________________________________________________________________________________________



-- -------> 16.) WHICH STATES HAVE THE HIGHEST ORDER VALUE?
-- ________________________________________________________

    
-- selects num and perc of orders for each category overall in order of highest total sales
	-- uncomment at bottom to include monthly breakdown or top/bottom results (LIMIT clause)
    -- important for determining highest value markets, esp. for marketing
    -- limiting outcome would be great for visualizations, e.g., traditional bar graph or time-series line graph


SELECT 
	ship_state AS state,
    -- uncomment to include monthly breakdown
    -- order_month AS `month`,
    ROUND(AVG(amount), 2) AS avg_ord_val, -- calculates avg order value by state
    ROUND(SUM(amount), 2) AS tot_ord_val -- calculates total sales by state
FROM amazon_sales
WHERE ship_state IS NOT NULL -- ensures NULLs are omitted
GROUP BY ship_state
	-- uncomment to include monthly breakdown
	-- , order_month
ORDER BY tot_ord_val DESC
	-- uncomment to include monthly breakdown
    -- , ship_state, order_month
    -- uncomment to choose top or bottom results (adjust ASC/DESC in ORDER BY clause)
	-- LIMIT 10
;



-- -------> 17.) WHICH STATES HAVE THE AVERAGE ORDER VALUE BY UNIT?
-- ________________________________________________________


-- selects same results as previous query, but by avg unit value 
	-- uncomment at bottom to include monthly breakdown or top/bottom results (LIMIT clause)
    -- when combined with previous query results, very helpful for understanding types of orders made
    -- limiting outcome would be great for visualizations, e.g., traditional bar graph or time-series line graph


WITH avg_unit_value AS (
	SELECT
		ship_state,
		-- uncomment to include monthly breakdown
		-- order_month AS `month`,
        (amount / qty) AS unit_val -- calculates unit value per order
	FROM amazon_sales
)
SELECT 
	ship_state AS state,
    -- uncomment to include monthly breakdown
    -- order_month AS `month`,
    ROUND(AVG(unit_val), 2) AS avg_ord_val, -- calculates avg order value by state
    ROUND(SUM(unit_val), 2) AS tot_ord_val -- calculates total order value by state
FROM avg_unit_value
WHERE ship_state IS NOT NULL -- ensures NULLs are omitted
GROUP BY ship_state
	-- uncommen to include monthly breakdown
	-- , order_month
ORDER BY tot_ord_val DESC
	-- uncomment to include monthly breakdown
    -- , ship_state, order_month
    -- uncomment to choose top or bottom results (adjust ASC/DESC in ORDER BY clause)
	-- LIMIT 10
;



-- -------> 18.) WHICH STATES HAVE THE HIGHEST PERCENTAGE OF B2B SALES?
-- ________________________________________________________


-- selects states with highest number of b2b sales and their perc of overall b2b sales
	-- uncomment at bottom to choose highest or lowest states (LIMIT clause)
    -- helpful to determine amazon's presence in b2b sales by region
    -- limiting outcome would be great for visualizations, e.g., traditional bar graph or time-series line graph


SELECT
	ship_state,
    COUNT(*) AS b2b_sales, -- calculates # b2b orders by state
    ROUND(COUNT(*) / ( SELECT COUNT(*)
		FROM amazon_sales
        WHERE b2b IS NOT NULL
			AND b2b = 1) * 100, 2) AS perc_b2b_sales -- calculates % of b2b sales by state
FROM amazon_sales
WHERE b2b = 1
GROUP BY ship_state
	HAVING COUNT(*) > 0
ORDER BY b2b_sales DESC
-- uncomment to limit to highest or lowest (adjust ASC/DESC in ORDER BY clause if necessary)
-- LIMIT 10
;





-- ========================================= SECTION F ========================================
-- ==================================== PERFORMANCE ANALYSIS ==================================
-- ____________________________________________________________________________________________



-- -------> 19.) WHAT IS THE RANKING FOR AVERAGE MONTHLY ORDER VALUE BY STATE?
-- __________________________________________________________________________


-- selects a ranked list of states by avg monthly order value
	-- uncomment at bottom to choose highest or lowest states (LIMIT clause)


WITH mon_avg AS (
	SELECT
		ship_state,
		order_month,
		AVG(amount) AS month_avg -- calculates avg sales by month
	FROM amazon_sales
	GROUP BY ship_state, order_month
),
st_avg AS (
	SELECT
		ship_state,
		ROUND(AVG(month_avg), 2) AS state_avg -- calculates avg sales by state
	FROM mon_avg
	GROUP BY ship_state
)
SELECT 
	DENSE_RANK() OVER(ORDER BY state_avg DESC) AS state_rank, -- calculates rank of state based on avg sales
	ship_state,
    state_avg
FROM st_avg
ORDER BY state_rank -- orders by rank
-- uncomment to limit to highest or lowest (adjust ASC/DESC in ORDER BY clause if necessary)
-- LIMIT 10
;




-- -------> 20.) WHAT ARE THE FIVE MOST RECENT AND OLDEST ORDERS BY STATE?
-- _______________________________________________________________________


-- selects the five most recent and oldest orders for each month
	-- the num of orders (e.g., 25 oldest) can easily be adjusted by adjusting mr_rn and oo_rn in WHERE clauses
	-- good for determining common trends during certain periods of the month
    

WITH most_recent AS (
	SELECT
		ROW_NUMBER() OVER(PARTITION BY order_month ORDER BY order_date DESC) AS mr_rn, -- calculates row number for orders in consecutive order (newest)
		`index`,
		order_id,
		order_date,
		`status`,
		ship_service_level,
		category,
		size,
		qty,
		amount,
		ship_state,
		ship_postal_code,
		b2b,
        order_month
	FROM amazon_sales
	WHERE order_date IS NOT NULL
		AND `status` IN (
						'Shipped',
						'Shipped - Delivered to Buyer',
						'Shipped - Out for Delivery',
						'Shipped - Picked Up',
						'Shipping') -- ensures only successful orders considered
	),
    oldest_orders AS (
		SELECT
			ROW_NUMBER() OVER(PARTITION BY order_month ORDER BY order_date) AS oo_rn, -- calculates row number by date in reverse order (oldest)
			`index`,
			order_id,
			order_date,
			`status`,
			ship_service_level,
			category,
			size,
			qty,
			amount,
			ship_state,
			ship_postal_code,
			b2b,
            order_month
		FROM amazon_sales
		WHERE order_date IS NOT NULL
			AND `status` IN (
							'Shipped',
							'Shipped - Delivered to Buyer',
							'Shipped - Out for Delivery',
							'Shipped - Picked Up',
							'Shipping')
) -- ensures only successful orders considered
SELECT
	CASE
		WHEN order_month = 3 THEN 'March'
        WHEN order_month = 4 THEN 'April'
        WHEN order_month = 5 THEN 'May'
        WHEN order_month = 6 THEN 'June'
    END AS `month`, -- calculates month names in place of index
    'Most Recent' AS recent_oldest,
	mr_rn AS ranking,
	`index`,
	order_id,
	order_date,
	`status`,
	ship_service_level,
	category,
	size,
	qty,
	amount,
	ship_state,
	ship_postal_code,
	b2b
FROM most_recent
WHERE mr_rn < 6
UNION ALL -- stacks oldest and most recent orders into one table
SELECT
	CASE
		WHEN order_month = 3 THEN 'March'
        WHEN order_month = 4 THEN 'April'
        WHEN order_month = 5 THEN 'May'
        WHEN order_month = 6 THEN 'June'
    END AS `month`, -- calculates month names in place of index
	'Oldest' AS recent_oldest,
	oo_rn AS ranking,
	`index`,
	order_id,
	order_date,
	`status`,
	ship_service_level,
	category,
	size,
	qty,
	amount,
	ship_state,
	ship_postal_code,
	b2b
FROM oldest_orders
WHERE oo_rn < 6
ORDER BY `month`, recent_oldest, ranking;



-- -------> 21.) WHAT IS THE ORDER BY ORDER PRICE DIFFERENCE BETWEEN PURCHASES?
-- ______________________________________________________________________


-- selects an order's category by date and id, then compares the order price with that of the previous order
	-- helpful in noticing trends and outliers over time
    -- if timestamped, could also track purchase types and values throughout the day
	-- with enough data and specific timeframes, could be good for line graph or even histogram
    

WITH cat_purchases AS (
	SELECT 
		category,
        order_date,
        `index`,
        amount AS order_total, -- calculates individual sales
        LAG(amount) OVER(PARTITION BY category ORDER BY order_date, `index`) AS prev_purchase -- calculates previous sale amount by category
	FROM amazon_sales
)
SELECT
	category,
    order_date AS `date`,
    `index` AS id,
	order_total,
    prev_purchase,
    (order_total - prev_purchase) AS price_diff -- calculates price difference between consecutive orders. 
FROM cat_purchases
ORDER BY category, order_date, `index`;



-- -------> 22.) WHAT IS THE 7 DAY ROLLING AVERAGE FOR ORDERS?
-- ______________________________________________________________________


-- selects the 7 day rolling purchase price average
	-- uncomment the code to include a category division (and can specify a category in WHERE clause at the end)
    -- extremely important in spotting common trends
	-- perfect for a time-series line graph or histogram


WITH avgerage_amount AS (
	SELECT
		-- uncomment to include category
		-- category,		
		order_month,
		order_day,
		AVG(amount) AS avg_amount -- calculates daily avg for sales
	FROM amazon_sales
    GROUP BY 
		-- uncomment to include category
		-- category, 
		order_month, order_day
),
rolling_average AS (
SELECT
	-- uncomment to include category
	-- category,
    order_month AS `month`,
    order_day AS `day`,
	avg_amount,
    AVG(avg_amount) OVER(
					-- uncomment to include category
					-- PARTITION BY category
                    ORDER BY order_month, order_day
					ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) AS rolling_avg -- calculates daily rolling avg
FROM avgerage_amount
ORDER BY
	-- uncomment to include category
	-- category, 
    order_month, order_day
)
SELECT
	-- uncomment to include category
	-- category,
    CONCAT(`month`, '/', `day`, '/2022') AS `date`, -- creates date format 
    ROUND(avg_amount, 2) AS avg_price,
    ROUND(rolling_avg, 2) AS `7_day_rolling`
FROM rolling_average
-- uncomment to choose specific category
-- WHERE category = 'Blazzer'
ORDER BY 
	-- uncomment to include category
    -- category, 
    `date`;



