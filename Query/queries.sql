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

--- Total rental sales for each movie Genre per store ---
SELECT *
FROM (
	SELECT
		g.[Name] AS Genre,
		i.StoreID,
		i.RentalRate,
		SUM(i.RentalRate) OVER (PARTITION BY i.StoreID) AS StoreTotalSales
	FROM Rental AS r
	JOIN Inventory AS i
		ON r.InventoryID = i.InventoryID
	JOIN Film AS f
		ON i.FilmID = f.FilmID
	JOIN FilmGenre AS fg
		ON f.FilmID = fg.FilmID
	JOIN Genre AS g
		ON fg.GenreID = g.GenreID
) AS SourceTable
PIVOT (
	SUM(RentalRate)
	FOR Genre IN (
		[Action],
		[Animation], 
		[Children],
		[Classics],
		[Comedy],
		[Documentary],
		[Drama],
		[Family],
		[Foreign],
		[Games],
		[Horror],
		[Music],
		[New],
		[Sci-Fi],
		[Sports],
		[Travel]
	)
) AS PivotTable
ORDER BY StoreTotalSales DESC;
