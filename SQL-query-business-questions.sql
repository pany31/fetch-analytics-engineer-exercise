-- What are the top 5 brands by receipts scanned for most recent month?
/* Each receipt_id corresponds to a single transaction (receipt), which may contain multiple items from potentially different brands. Hence we are using Distinct receipt_id count*/

SELECT TOP 5 b.name, COUNT(DISTINCT ril.receipt_id) as receipt_count
FROM brands b
JOIN receipt_item_list ril ON b.barcode = ril.barcode
JOIN receipts r ON ril.receipt_id = r.id
WHERE MONTH(r.dateScanned) = MONTH(CURRENT_DATE)
    AND YEAR(r.dateScanned) = YEAR(CURRENT_DATE)
GROUP BY b.name
ORDER BY receipt_count DESC;


-- How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
/* This query uses rank to determine top five brands for each month and does a full outer join on rank to compare top five brands of each month side by side */
WITH CurrentMonthRank AS (
    SELECT b.name, COUNT(DISTINCT r.id) as receipt_count,
    RANK() OVER (ORDER BY COUNT(DISTINCT r.id) DESC) as rnk
    FROM brands b
    JOIN receipt_item_list ril ON b.barcode = ril.barcode
    JOIN receipts r ON ril.receipt_id = r.id
    WHERE MONTH(r.dateScanned) = MONTH(CURRENT_DATE)
    AND YEAR(r.dateScanned) = YEAR(CURRENT_DATE)
    GROUP BY b.name
	HAVING rnk <= 5
),
PreviousMonthRank AS (
    SELECT b.name, COUNT(DISTINCT r.id) as receipt_count,
    RANK() OVER (ORDER BY COUNT(DISTINCT r.id) DESC) as rank
    FROM brands b
    JOIN receipt_item_list ril ON b.barcode = ril.barcode
    JOIN receipts r ON ril.receipt_id = r.id
    WHERE MONTH(r.dateScanned) = MONTH(CURRENT_DATE)
    AND YEAR(r.dateScanned) = YEAR(CURRENT_DATE))
    GROUP BY b.name
	HAVING rnk <= 5
)
SELECT	c.rnk, 
		cm.name AS CurrentMonthBrand,
		cm.receipt_count AS CurrentMonthReceiptCount,
		pm.name AS PreviousMonthBrand, 
		pm.receipt_count AS PreviousMonthReceipt
FROM CurrentMonthRank cm
FULL OUTER JOIN PreviousMonthRank pm ON cm.name = pm.name


-- When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?

/* According to data this query assumes FINISHED rewardsReceiptStatus means Accepted */

SELECT rewardsReceiptStatus, AVG(totalSpend) as AverageSpend
FROM receipts
WHERE rewardsReceiptStatus IN ('FINISHED')

UNION ALL

SELECT rewardsReceiptStatus, AVG(totalSpend) as AverageSpend
FROM receipts
WHERE rewardsReceiptStatus IN ('REJECTED')

-- Which brand has the most spend among users who were created within the past 6 months?
/* This query calculates the sum of final price assuming that is the amount spend on an item of a particular brand within a receipt */
SELECT TOP 1 b.brand_name, SUM(ri.final_price) AS total_spend
FROM brands b
JOIN receipt_items ri ON b.brand_id = ri.brand_id
JOIN receipts r ON ri.receipt_id = r.receipt_id
JOIN users u ON r.user_id = u.user_id
WHERE u.created_at >= DATEADD(month, -6, GETDATE())
GROUP BY b.brand_name
ORDER BY total_spend DESC

-- Which brand has the most transactions among users who were created within the past 6 months?

/* this query assumes a single recepit is considered as a single transaction for a brand and each receipt can have multiple brands in it */
SELECT TOP 1 b.brand_name, COUNT(DISTINCT r.receipt_id) AS transaction_count
FROM brands b
JOIN receipt_items ri ON b.brand_id = ri.brand_id
JOIN receipts r ON ri.receipt_id = r.receipt_id
JOIN users u ON r.user_id = u.user_id
WHERE u.created_at >= DATEADD(MONTH, -6, GETDATE())
GROUP BY b.brand_name
ORDER BY transaction_count DESC;
