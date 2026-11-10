use cartAbandonmentDB;
SELECT TABLE_NAME,COLUMN_NAME,DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME,ORDINAL_POSITION

/* How many sessions reached each stage of the checkout funnel and what is the dropoff percentage at each stage?*/
select count(distinct case when Checkout_Started = 1 then session_id end) as Checkout_Started,
count(distinct case when Payment_Started = 1 then session_id end) as Payment_Started,
count(distinct case when Purchase_Completed = 1 then session_id end) as Purchase_Completed 
from [checkout activity clean];

/*Calculating Drop-off percentage*/
SELECT
    COUNT(DISTINCT CASE
        WHEN Checkout_Started = 1 THEN Session_ID
    END) AS Checkout_Started,

    COUNT(DISTINCT CASE
        WHEN Payment_Started = 1 THEN Session_ID
    END) AS Payment_Started,

    COUNT(DISTINCT CASE
        WHEN Purchase_Completed = 1 THEN Session_ID
    END) AS Purchase_Completed,

    CAST(
        100.0 * (
            COUNT(DISTINCT CASE
                WHEN Checkout_Started = 1 THEN Session_ID
            END)
            -
            COUNT(DISTINCT CASE
                WHEN Payment_Started = 1 THEN Session_ID
            END)
        )
        / NULLIF(COUNT(DISTINCT CASE
            WHEN Checkout_Started = 1 THEN Session_ID
        END), 0)
        AS DECIMAL(10,2)
    ) AS Checkout_Dropoff_Percentage,

    CAST(
        100.0 * (
            COUNT(DISTINCT CASE
                WHEN Payment_Started = 1 THEN Session_ID
            END)
            -
            COUNT(DISTINCT CASE
                WHEN Purchase_Completed = 1 THEN Session_ID
            END)
        )
        / NULLIF(COUNT(DISTINCT CASE
            WHEN Payment_Started = 1 THEN Session_ID
        END), 0)
        AS DECIMAL(10,2)
    ) AS Payment_Dropoff_Percentage

FROM [checkout activity clean];	

/* identifying the highest dropoff stage*/
WITH Funnel AS
(
    SELECT
        COUNT(DISTINCT CASE
            WHEN Checkout_Started = 1
            THEN Session_ID END) AS Checkout_Count,

        COUNT(DISTINCT CASE
            WHEN Payment_Started = 1
            THEN Session_ID END) AS Payment_Count,

        COUNT(DISTINCT CASE
            WHEN Purchase_Completed = 1
            THEN Session_ID END) AS Purchase_Count

    FROM [checkout activity clean]
),

Dropoff AS
(
    SELECT
        'Checkout to Payment' AS Funnel_Stage,
        Checkout_Count - Payment_Count AS Dropoff_Count,
        CAST(
            100.0 * (Checkout_Count - Payment_Count)
            / NULLIF(Checkout_Count, 0)
            AS DECIMAL(10,2)
        ) AS Dropoff_Percentage
    FROM Funnel

    UNION ALL

    SELECT
        'Payment to Purchase',
        Payment_Count - Purchase_Count,
        CAST(
            100.0 * (Payment_Count - Purchase_Count)
            / NULLIF(Payment_Count, 0)
            AS DECIMAL(10,2)
        )
    FROM Funnel
)

SELECT *
FROM Dropoff
ORDER BY Dropoff_Percentage DESC;

/* which device type has the highest cart abondoment rate?*/
WITH CheckoutStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
),

CartSessions AS
(
    SELECT DISTINCT
        CS.Session_ID,
        CS.Device_Type,
        ISNULL(CHK.Purchase_Completed, 0) AS Purchase_Completed

    FROM [customer sessions] CS

    INNER JOIN [cart product activity clean] CART
        ON CS.Session_ID = CART.Session_ID

    LEFT JOIN CheckoutStatus CHK
        ON CS.Session_ID = CHK.Session_ID
)

SELECT
    Device_Type,

    COUNT(*) AS Total_Cart_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 1 THEN 1
        ELSE 0
    END) AS Purchased_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 0 THEN 1
        ELSE 0
    END) AS Abandoned_Sessions,

    CAST(
        100.0 * SUM(CASE
            WHEN Purchase_Completed = 0 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Abandonment_Rate

FROM CartSessions
GROUP BY Device_Type
ORDER BY Abandonment_Rate DESC;

/* which product categories have the highest cart abondonment rate?*/
WITH CheckoutStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
),

CategorySessions AS
(
    SELECT DISTINCT
        CART.Product_Category,
        CART.Session_ID,
        ISNULL(CHK.Purchase_Completed, 0) AS Purchase_Completed

    FROM [cart product activity clean] CART

    LEFT JOIN CheckoutStatus CHK
        ON CART.Session_ID = CHK.Session_ID

    WHERE CART.Product_Category IS NOT NULL
)

SELECT
    Product_Category,

    COUNT(*) AS Total_Cart_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 1 THEN 1
        ELSE 0
    END) AS Purchased_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 0 THEN 1
        ELSE 0
    END) AS Abandoned_Sessions,

    CAST(
        100.0 * SUM(CASE
            WHEN Purchase_Completed = 0 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Abandonment_Rate

FROM CategorySessions

GROUP BY Product_Category

ORDER BY Abandonment_Rate DESC;

/* which products are added to cart frequently but rarely purchased ?*/
WITH CheckoutStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
),

ProductSessions AS
(
    SELECT DISTINCT
        CART.Product_ID,
        CART.Session_ID,
        ISNULL(CHK.Purchase_Completed, 0) AS Purchase_Completed

    FROM [cart product activity clean] CART

    LEFT JOIN CheckoutStatus CHK
        ON CART.Session_ID = CHK.Session_ID
)

SELECT
    Product_ID,

    COUNT(*) AS Total_Cart_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 1 THEN 1
        ELSE 0
    END) AS Purchased_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 0 THEN 1
        ELSE 0
    END) AS Abandoned_Sessions,

    CAST(
        100.0 * SUM(CASE
            WHEN Purchase_Completed = 0 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Abandonment_Rate

FROM ProductSessions

GROUP BY Product_ID

ORDER BY Total_Cart_Sessions DESC, Abandonment_rate desc;

/* which customer segment has the highest cart abandonment rate?- new or returning customers*/
WITH CustomerHistory AS
(
    SELECT
        Customer_ID,
        COUNT(DISTINCT Session_ID) AS Total_Sessions
    FROM [customer sessions]
    WHERE Customer_ID IS NOT NULL
    GROUP BY Customer_ID
),

CheckoutStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
),

CustomerCartSessions AS
(
    SELECT DISTINCT
        CS.Session_ID,
        CASE
            WHEN CS.Customer_ID IS NULL THEN 'Unknown'
            WHEN CH.Total_Sessions = 1 THEN 'New Customer'
            ELSE 'Returning Customer'
        END AS Customer_Segment,

        ISNULL(CHK.Purchase_Completed, 0) AS Purchase_Completed

    FROM [customer sessions] CS

    INNER JOIN [cart product activity clean] CART
        ON CS.Session_ID = CART.Session_ID

    LEFT JOIN CustomerHistory CH
        ON CS.Customer_ID = CH.Customer_ID

    LEFT JOIN CheckoutStatus CHK
        ON CS.Session_ID = CHK.Session_ID
)

SELECT
    Customer_Segment,

    COUNT(*) AS Total_Cart_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 1 THEN 1
        ELSE 0
    END) AS Purchased_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 0 THEN 1
        ELSE 0
    END) AS Abandoned_Sessions,

    CAST(
        100.0 * SUM(CASE
            WHEN Purchase_Completed = 0 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Abandonment_Rate

FROM CustomerCartSessions
GROUP BY Customer_Segment
ORDER BY Abandonment_Rate DESC;

/*what is the Average cart value of abandonment sessions? */
WITH CheckoutStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
),

SessionCartValue AS
(
    SELECT
        Session_ID,
        SUM(Cart_Value) AS Total_Cart_Value
    FROM [cart product activity clean]
    GROUP BY Session_ID
),

AbandonedCarts AS
(
    SELECT
        SCV.Session_ID,
        SCV.Total_Cart_Value

    FROM SessionCartValue SCV

    LEFT JOIN CheckoutStatus CHK
        ON SCV.Session_ID = CHK.Session_ID

    WHERE ISNULL(CHK.Purchase_Completed, 0) = 0
)

SELECT
    COUNT(*) AS Total_Abandoned_Sessions,

    SUM(Total_Cart_Value) AS Total_Abandoned_Cart_Value,

    CAST(
        AVG(Total_Cart_Value)
        AS DECIMAL(10,2)
    ) AS Average_Abandoned_Cart_Value

FROM AbandonedCarts;

/* which time of day has the highest cart abandonment rate?*/
WITH CheckoutStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
),

CartSessions AS
(
    SELECT DISTINCT
        CS.Session_ID,
        CASE
            WHEN CAST(CS.Time AS TIME) >= '06:00:00'
             AND CAST(CS.Time AS TIME) < '12:00:00'
                THEN 'Morning'

            WHEN CAST(CS.Time AS TIME) >= '12:00:00'
             AND CAST(CS.Time AS TIME) < '17:00:00'
                THEN 'Afternoon'

            WHEN CAST(CS.Time AS TIME) >= '17:00:00'
             AND CAST(CS.Time AS TIME) < '21:00:00'
                THEN 'Evening'

            ELSE 'Night'
        END AS Time_Period,

        ISNULL(CHK.Purchase_Completed, 0) AS Purchase_Completed

    FROM [customer sessions] CS

    INNER JOIN [cart product activity clean] CART
        ON CS.Session_ID = CART.Session_ID

    LEFT JOIN CheckoutStatus CHK
        ON CS.Session_ID = CHK.Session_ID
)

SELECT
    Time_Period,

    COUNT(*) AS Total_Cart_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 1 THEN 1
        ELSE 0
    END) AS Purchased_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 0 THEN 1
        ELSE 0
    END) AS Abandoned_Sessions,

    CAST(
        100.0 * SUM(CASE
            WHEN Purchase_Completed = 0 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Abandonment_Rate

FROM CartSessions

GROUP BY Time_Period

ORDER BY Abandonment_Rate DESC;

/*which traffic source brings customers with the highest cart abandonment rate ? */
WITH CheckoutStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
),

CartSessions AS
(
    SELECT DISTINCT
        CS.Session_ID,
        CS.Traffic_Source,

        ISNULL(CHK.Purchase_Completed, 0)
            AS Purchase_Completed

    FROM [customer sessions] CS

    INNER JOIN [cart product activity clean] CART
        ON CS.Session_ID = CART.Session_ID

    LEFT JOIN CheckoutStatus CHK
        ON CS.Session_ID = CHK.Session_ID
)

SELECT
    Traffic_Source,

    COUNT(*) AS Total_Cart_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 1 THEN 1
        ELSE 0
    END) AS Purchased_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 0 THEN 1
        ELSE 0
    END) AS Abandoned_Sessions,

    CAST(
        100.0 * SUM(CASE
            WHEN Purchase_Completed = 0 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Abandonment_Rate

FROM CartSessions

GROUP BY Traffic_Source

ORDER BY Abandonment_Rate DESC;


/*how does cart abandonment change day by day?*/
WITH CheckoutStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
),

DailyCartSessions AS
(
    SELECT DISTINCT
        CS.Session_ID,
        CAST(CS.Date AS DATE) AS Session_Date,
        ISNULL(CHK.Purchase_Completed, 0) AS Purchase_Completed

    FROM [customer sessions] CS

    INNER JOIN [cart product activity clean] CART
        ON CS.Session_ID = CART.Session_ID

    LEFT JOIN CheckoutStatus CHK
        ON CS.Session_ID = CHK.Session_ID
)

SELECT
    Session_Date,

    COUNT(*) AS Total_Cart_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 1 THEN 1
        ELSE 0
    END) AS Purchased_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 0 THEN 1
        ELSE 0
    END) AS Abandoned_Sessions,

    CAST(
        100.0 * SUM(CASE
            WHEN Purchase_Completed = 0 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Abandonment_Rate

FROM DailyCartSessions

GROUP BY Session_Date

ORDER BY Session_Date;

/*which month has the highest cart abandonment rate? */
WITH CheckoutStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
),

MonthlyCartSessions AS
(
    SELECT DISTINCT
        CS.Session_ID,
        YEAR(CS.Date) AS Session_Year,
        MONTH(CS.Date) AS Session_Month,
        ISNULL(CHK.Purchase_Completed, 0) AS Purchase_Completed

    FROM [customer sessions] CS

    INNER JOIN [cart product activity clean] CART
        ON CS.Session_ID = CART.Session_ID

    LEFT JOIN CheckoutStatus CHK
        ON CS.Session_ID = CHK.Session_ID
)

SELECT
    Session_Year,
    Session_Month,

    COUNT(*) AS Total_Cart_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 1 THEN 1
        ELSE 0
    END) AS Purchased_Sessions,

    SUM(CASE
        WHEN Purchase_Completed = 0 THEN 1
        ELSE 0
    END) AS Abandoned_Sessions,

    CAST(
        100.0 * SUM(CASE
            WHEN Purchase_Completed = 0 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Abandonment_Rate

FROM MonthlyCartSessions

GROUP BY Session_Year, Session_Month

ORDER BY Session_Year, Session_Month;

/* which payment method has the highest purchase completion rate and which has the lowest ?*/
WITH PaymentSessions AS
(
    SELECT DISTINCT
        Session_ID,
        Payment_Method,
        CAST(Purchase_Completed AS INT) AS Purchase_Completed
    FROM [checkout activity clean]
    WHERE Payment_Started = 1
      AND Payment_Method IS NOT NULL
)

SELECT
    Payment_Method,

    COUNT(DISTINCT Session_ID) AS Total_Payment_Sessions,

    COUNT(DISTINCT CASE
        WHEN Purchase_Completed = 1
        THEN Session_ID
    END) AS Successful_Purchases,

    COUNT(DISTINCT CASE
        WHEN Purchase_Completed = 0
        THEN Session_ID
    END) AS Incomplete_Purchases,

    CAST(
        100.0 * COUNT(DISTINCT CASE
            WHEN Purchase_Completed = 1
            THEN Session_ID
        END)
        / NULLIF(COUNT(DISTINCT Session_ID), 0)
        AS DECIMAL(10,2)
    ) AS Purchase_Completion_Rate

FROM PaymentSessions

GROUP BY Payment_Method

ORDER BY Purchase_Completion_Rate DESC;

/*does applying discount influence purchase completion ? */
WITH SessionDiscount AS
(
    SELECT
        Session_ID,
        MAX(CASE
            WHEN ISNULL(Discount, 0) > 0 THEN 1
            ELSE 0
        END) AS Discount_Applied
    FROM [cart product activity clean]
    GROUP BY Session_ID
),
PurchaseStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
)
SELECT
    CASE
        WHEN SD.Discount_Applied = 1 THEN 'Discount Applied'
        ELSE 'No Discount'
    END AS Discount_Status,

    COUNT(DISTINCT SD.Session_ID) AS Total_Sessions,

    COUNT(DISTINCT CASE
        WHEN PS.Purchase_Completed = 1 THEN SD.Session_ID
    END) AS Successful_Purchases,

    COUNT(DISTINCT CASE
        WHEN ISNULL(PS.Purchase_Completed, 0) = 0
        THEN SD.Session_ID
    END) AS Abandoned_Sessions,

    CAST(
        100.0 * COUNT(DISTINCT CASE
            WHEN PS.Purchase_Completed = 1 THEN SD.Session_ID
        END)
        / NULLIF(COUNT(DISTINCT SD.Session_ID), 0)
        AS DECIMAL(10,2)
    ) AS Purchase_Completion_Rate

FROM SessionDiscount SD
LEFT JOIN PurchaseStatus PS
    ON SD.Session_ID = PS.Session_ID
GROUP BY SD.Discount_Applied
ORDER BY Purchase_Completion_Rate DESC;

/* which location has the highest cart abandonment rate ? */
WITH CheckoutStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
),
LocationSessions AS
(
    SELECT DISTINCT
        CS.Session_ID,
        CS.Location,
        ISNULL(CTS.Purchase_Completed, 0) AS Purchase_Completed
    FROM [customer sessions] CS
    INNER JOIN [cart product activity clean] CP
        ON CS.Session_ID = CP.Session_ID
    LEFT JOIN CheckoutStatus CTS
        ON CS.Session_ID = CTS.Session_ID
    WHERE CS.Location IS NOT NULL
)
SELECT
    Location,
    COUNT(DISTINCT Session_ID) AS Total_Cart_Sessions,

    COUNT(DISTINCT CASE
        WHEN Purchase_Completed = 1 THEN Session_ID
    END) AS Successful_Purchases,

    COUNT(DISTINCT CASE
        WHEN Purchase_Completed = 0 THEN Session_ID
    END) AS Abandoned_Sessions,

    CAST(
        100.0 * COUNT(DISTINCT CASE
            WHEN Purchase_Completed = 0 THEN Session_ID
        END)
        / NULLIF(COUNT(DISTINCT Session_ID), 0)
        AS DECIMAL(10,2)
    ) AS Abandonment_Rate

FROM LocationSessions
GROUP BY Location
ORDER BY Abandonment_Rate DESC;

/* which combination of device type and traffic source has the highest cart abandonment rate ? */
WITH CheckoutStatus AS
(
    SELECT
        Session_ID,
        MAX(CAST(Purchase_Completed AS INT)) AS Purchase_Completed
    FROM [checkout activity clean]
    GROUP BY Session_ID
),
DeviceTrafficSessions AS
(
    SELECT DISTINCT
        CS.Session_ID,
        CS.Device_Type,
        CS.Traffic_Source,
        ISNULL(CTS.Purchase_Completed, 0) AS Purchase_Completed
    FROM [customer sessions] CS
    INNER JOIN [cart product activity clean] CP
        ON CS.Session_ID = CP.Session_ID
    LEFT JOIN CheckoutStatus CTS
        ON CS.Session_ID = CTS.Session_ID
)
SELECT
    Device_Type,
    Traffic_Source,

    COUNT(DISTINCT Session_ID) AS Total_Cart_Sessions,

    COUNT(DISTINCT CASE
        WHEN Purchase_Completed = 1 THEN Session_ID
    END) AS Successful_Purchases,

    COUNT(DISTINCT CASE
        WHEN Purchase_Completed = 0 THEN Session_ID
    END) AS Abandoned_Sessions,

    CAST(
        100.0 * COUNT(DISTINCT CASE
            WHEN Purchase_Completed = 0 THEN Session_ID
        END)
        / NULLIF(COUNT(DISTINCT Session_ID), 0)
        AS DECIMAL(10,2)
    ) AS Abandonment_Rate

FROM DeviceTrafficSessions
GROUP BY Device_Type, Traffic_Source
ORDER BY Abandonment_Rate DESC;