create database customers_transactions;
update customers set Gender = null where Gender = '';
update customers set Age = null where Age = '';
alter table customers modify Age int null;

select * from customers;

select * from transactions;

create table Transactions 
(date_new date,
Id_check int,
ID_client int,
Count_products decimal(10,3),
Sum_payment decimal(10,2)
);


LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\TRANSACTIONS.csv"
INTO TABLE Transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

show variables like 'secure_file_priv';

# 1 задача список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за указанный годовой период, 

WITH monthly_activity AS (
    SELECT
        t.ID_client,
        DATE_FORMAT(t.date_new, '%Y-%m') AS ym
    FROM transactions t
    WHERE t.date_new >= '2015-06-01'
      AND t.date_new <  '2016-06-01'
    GROUP BY t.ID_client, DATE_FORMAT(t.date_new, '%Y-%m')
),

activity_count AS (
    SELECT
        ID_client,
        COUNT(*) AS active_months
    FROM monthly_activity
    GROUP BY ID_client
)

SELECT
    c.ID_client,
    c.Gender,
    c.Age,
    c.Count_city,
    c.Tenure
FROM activity_count a
JOIN customers c ON c.ID_client = a.ID_client
WHERE a.active_months = 12
ORDER BY c.ID_client;



# средний чек за период с 01.06.2015 по 01.06.2016, 


SELECT 
    ROUND(AVG(Sum_payment), 2) AS avg_check_period
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01';


# средняя сумма покупок за месяц, 
WITH monthly_sums AS (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        SUM(Sum_payment) AS total_amount_month
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <  '2016-06-01'
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
)
SELECT 
    ROUND(AVG(total_amount_month), 2) AS avg_monthly_amount
FROM monthly_sums;



# количество всех операций по клиенту за период;


SELECT
    ID_client,
    COUNT(*) AS operations_count
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY ID_client
ORDER BY operations_count DESC;




###################################################################
# 2 задача информация в разрезе месяцев:


# информация в разрезе месяцев: средняя сумма чека в месяц;
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    ROUND(AVG(Sum_payment), 2) AS avg_check_month
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;

# информация в разрезе месяцев: среднее количество операций в месяц;

SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(*) AS operations_in_month
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;


# информация в разрезе месяцев: среднее количество клиентов, которые совершали операции

SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(DISTINCT ID_client) AS unique_clients_in_month
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;


# информация в разрезе месяцев: долю от общего количества операций за год и долю в месяц от общей суммы операций;

WITH base AS (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        Sum_payment
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <  '2016-06-01'
),

year_totals AS (
    SELECT
        COUNT(*) AS total_ops,
        SUM(Sum_payment) AS total_amount
    FROM base
)

SELECT
    b.month,

    COUNT(*) AS operations_in_month,
    ROUND(COUNT(*) / MAX(yt.total_ops) * 100, 2) AS operations_share_percent,

    SUM(b.Sum_payment) AS amount_in_month,
    ROUND(SUM(b.Sum_payment) / MAX(yt.total_amount) * 100, 2) AS amount_share_percent

FROM base b
CROSS JOIN year_totals yt
GROUP BY b.month
ORDER BY b.month;





# информация в разрезе месяцев:  вывести % соотношение M/F/NA в каждом месяце с их долей затрат;

WITH base AS (                                    # CTE: берём транзакции за год
    SELECT
        DATE_FORMAT(t.date_new, '%Y-%m') AS month, # месяц YYYY-MM
        t.Sum_payment,                             # сумма покупки
        c.Gender                                   # пол клиента (M/F/NULL)
    FROM transactions t
    LEFT JOIN customers c ON t.ID_client = c.ID_client   # присоединяем пол
    WHERE t.date_new >= '2015-06-01'               # начало периода
      AND t.date_new <  '2016-06-01'               # конец периода
),

gender_stats AS (                                  # CTE: считаем операции и суммы по полу
    SELECT
        month,
        
        SUM(CASE WHEN Gender = 'M' THEN 1 ELSE 0 END) AS ops_m,        # операции мужчин
        SUM(CASE WHEN Gender = 'F' THEN 1 ELSE 0 END) AS ops_f,        # операции женщин
        SUM(CASE WHEN Gender IS NULL OR Gender = '' THEN 1 ELSE 0 END) AS ops_na,  
            # операции c неизвестным полом
        
        SUM(CASE WHEN Gender = 'M' THEN Sum_payment ELSE 0 END) AS amount_m, # сумма мужчин
        SUM(CASE WHEN Gender = 'F' THEN Sum_payment ELSE 0 END) AS amount_f, # сумма женщин
        SUM(CASE WHEN Gender IS NULL OR Gender = '' THEN Sum_payment ELSE 0 END) AS amount_na 
            # сумма неизвестного пола

    FROM base
    GROUP BY month
)

SELECT
    month,

    # % распределение клиентов по полу
    ROUND(ops_m / (ops_m + ops_f + ops_na) * 100, 2) AS percent_m,
    ROUND(ops_f / (ops_m + ops_f + ops_na) * 100, 2) AS percent_f,
    ROUND(ops_na / (ops_m + ops_f + ops_na) * 100, 2) AS percent_na,

    # % распределение затрат по полу
    ROUND(amount_m / (amount_m + amount_f + amount_na) * 100, 2) AS spending_m_percent,
    ROUND(amount_f / (amount_m + amount_f + amount_na) * 100, 2) AS spending_f_percent,
    ROUND(amount_na / (amount_m + amount_f + amount_na) * 100, 2) AS spending_na_percent

FROM gender_stats
ORDER BY month;

###################################################################


# 3 задача: возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, 
# с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.


WITH base AS (
    SELECT
        t.ID_client,
        t.Sum_payment,
        t.date_new,
        c.Age,
        
        CASE
            WHEN c.Age IS NULL OR c.Age = '' THEN 'NA'
            ELSE CONCAT(FLOOR(c.Age / 10) * 10, '-', FLOOR(c.Age / 10) * 10 + 9)
        END AS age_group
        # Пример: 25 -> '20-29'
        # NULL -> 'NA'
    FROM transactions t
    LEFT JOIN customers c ON t.ID_client = c.ID_client
),

group_totals AS (
    SELECT
        age_group,
        COUNT(*) AS operations_total,
        SUM(Sum_payment) AS amount_total
    FROM base
    GROUP BY age_group
),

quarter_stats AS (
    SELECT
        age_group,
        CONCAT(YEAR(date_new), '-Q', QUARTER(date_new)) AS quarter,
        
        AVG(Sum_payment) AS avg_payment_quarter,
        COUNT(*) AS ops_quarter,
        
        SUM(Sum_payment) AS amount_quarter
    FROM base
    GROUP BY age_group, CONCAT(YEAR(date_new), '-Q', QUARTER(date_new))
),

quarter_shares AS (
    SELECT
        qs.age_group,
        qs.quarter,
        qs.avg_payment_quarter,
        qs.ops_quarter,
        qs.amount_quarter,
        
        ROUND(qs.ops_quarter /
              (SELECT SUM(q2.ops_quarter)
               FROM quarter_stats q2
               WHERE q2.quarter = qs.quarter) * 100, 2) AS ops_share_percent,

        ROUND(qs.amount_quarter /
              (SELECT SUM(q3.amount_quarter)
               FROM quarter_stats q3
               WHERE q3.quarter = qs.quarter) * 100, 2) AS amount_share_percent
    FROM quarter_stats qs
)

SELECT
    gt.age_group,

    gt.operations_total AS ops_total_period,
    gt.amount_total AS amount_total_period,

    qs.quarter,
    qs.avg_payment_quarter,
    qs.ops_quarter,
    qs.ops_share_percent,
    qs.amount_share_percent

FROM group_totals gt
LEFT JOIN quarter_shares qs ON gt.age_group = qs.age_group
ORDER BY gt.age_group, qs.quarter;
