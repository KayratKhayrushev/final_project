CREATE DATABASE Customers_transactions;
UPDATE customers SET Gender = NULL WHERE Gender = '';
UPDATE customers SET Age = NULL WHERE Age = '';
ALTER TABLE customers MODIFY AGE INT NULL;


SELECT * FROM customers ;


CREATE TABLE Transactions
(date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL(10,3),
Sum_payment DECIMAL(10,2));




LOAD DATA LOCAL INFILE '/Users/kayratkhayrushev/Documents/Academica/Финальный проект/TRANSACTIONS final.csv'
INTO TABLE Transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = 1;


SHOW VARIABLES LIKE 'secure_file_priv';