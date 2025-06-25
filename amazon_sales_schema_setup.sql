

-- =============================== DATABASE SETUP FOR AMAZON SALES ===============================
-- _______________________________________________________________________________________



-- use this code to access MySQL prompt in Terminal/Command Prompt (uncommented):
-- mysql -u ENTER_USER_NAME -p 



-- enter this code to make the database
DROP DATABASE IF EXISTS amazon_sales_data;
CREATE DATABASE amazon_sales_data;
USE amazon_sales_data;



-- use this code to create the table


CREATE TABLE amazon_sales (
	`index` INT PRIMARY KEY,
    `order_id` VARCHAR(30),
	`order_date` DATE,
	`status` VARCHAR(50),
	`fulfilment` VARCHAR(20),
	`sales_channel` VARCHAR(30),
	`ship_service_level` VARCHAR(30),
	`category` VARCHAR(30),
	`size` VARCHAR(5),
	`courier_status` VARCHAR(30),
	`qty` INT,
	`currency` VARCHAR(5),
	`amount` DECIMAL(10,2),
	`ship_city` VARCHAR(50),
	`ship_state` VARCHAR(50),
	`ship_postal_code` VARCHAR(10),
	`ship_country` VARCHAR(5),
	`b2b` BOOLEAN,
	`fulfilled_by` VARCHAR(30),
	`new` VARCHAR(10),
	`pendings` VARCHAR(10)
);


-- exit from mysql prompt and then enter this code into Terminal/Command prompt to access db (uncommented):
-- mysql --local-infile=1 -u ENTER_USER_NAME -p amazon_sales_data


-- enter this code to directly input .csv file

LOAD DATA LOCAL INFILE 'ENTER_PATHWAY_TO.csv'
INTO TABLE amazon_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  `index`,
  `order_id`,
  @order_date,
  `status`,
  `fulfilment`,
  `sales_channel`,
  `ship_service_level`,
  `category`,
  `size`,
  `courier_status`,
  `qty`,
  `currency`,
  `amount`,
  `ship_city`,
  `ship_state`,
  `ship_postal_code`,
  `ship_country`,
  @b2b,
  `fulfilled_by`,
  `new`,
  `pendings`
)
SET
  order_date = STR_TO_DATE(@order_date, '%m-%d-%y'),
  b2b = IF(@b2b = 'TRUE', TRUE, FALSE);
