--- Customers who have no rentals ---
SELECT c.CustomerID
FROM Customer AS c
LEFT JOIN Payment AS p
    ON c.CustomerID = p.CustomerID
GROUP BY c.CustomerID
HAVING COUNT(p.PaymentID) = 0;

--- Films that were never been rented ---
SELECT f.FilmID, f.Title
FROM Film AS f
LEFT JOIN Inventory AS i
	ON f.FilmID = i.FilmID
LEFT JOIN Rental AS r
	ON i.InventoryID = r.InventoryID
WHERE r.RentalID IS NULL;

--- Rank customers by total rentals per store ---
WITH CustomerRentalRankPerStore AS (
	SELECT
	s.StoreID,
	p.CustomerID,
	COUNT(*) AS TotalRentals,
	DENSE_RANK() OVER (PARTITION BY s.StoreID ORDER BY COUNT(*) DESC) AS CustomerRank
FROM Store AS s
JOIN Inventory AS i
	ON s.StoreID = i.StoreID
JOIN Rental AS r
	ON i.InventoryID = r.InventoryID
JOIN Payment AS p
	ON r.PaymentID = p.PaymentID
GROUP BY p.CustomerID, s.StoreID
)
SELECT *
FROM CustomerRentalRankPerStore
ORDER BY StoreID, CustomerRank;

--- Best-Selling movies ---
SELECT
	f.Title,
	COUNT(*) AS TotalRental,
	DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS FilmRank
FROM Rental AS r
JOIN Inventory AS i
	ON r.InventoryID = i.InventoryID
JOIN Film AS f
	ON i.FilmID = f.FilmID
GROUP BY f.FilmID, f.Title;

