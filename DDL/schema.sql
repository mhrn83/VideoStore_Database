--- CREATE DATABASE ---
CREATE DATABASE VideoStore;
GO
USE VideoStore;

--- CREATE TABLE ---
CREATE TABLE Actor (
    ActorID INT IDENTITY,
    FirstName VARCHAR(45) NOT NULL,
    LastName VARCHAR(45) NOT NULL,
    PRIMARY KEY(ActorID)
);
GO

CREATE TABLE Country (
    CountryID INT IDENTITY,
    [Name] VARCHAR(50) NOT NULL,
    PRIMARY KEY(CountryID)
);
GO

CREATE TABLE City (
    CityID INT IDENTITY,
    [Name] VARCHAR(50) NOT NULL,
    CountryID INT NOT NULL,
    PRIMARY KEY(CityID),
    CONSTRAINT FK_CityCountry FOREIGN KEY(CountryID) REFERENCES Country(CountryID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

CREATE TABLE [Address] (
    AddressID INT IDENTITY,
    [Address] VARCHAR(50) NOT NULL,
    DetailedAddress VARCHAR(50),
    District VARCHAR(20),
    PostalCode VARCHAR(10),
    Phone VARCHAR(20) NOT NULL,
    CityID INT NOT NULL,
    PRIMARY KEY(AddressID),
    CONSTRAINT FK_AddressCity FOREIGN KEY(CityID) REFERENCES City(CityID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

CREATE TABLE [Language] (
    LanguageID INT IDENTITY,
    [Name] VARCHAR(20) NOT NULL,
    PRIMARY KEY(LanguageID)
);
GO

CREATE TABLE Genre (
    GenreID INT IDENTITY,
    [Name] VARCHAR(25) NOT NULL,
    PRIMARY KEY(GenreID)
);
GO

CREATE TABLE Customer (
    CustomerID INT IDENTITY,
    FirstName VARCHAR(45) NOT NULL,
    LastName VARCHAR(45) NOT NULL,
    Email VARCHAR(50),
    CreateDate DATETIME NOT NULL,
    AddressID INT NOT NULL,
    PRIMARY KEY(CustomerID),
    CONSTRAINT AK_CustomerEmail UNIQUE(Email), 
    CONSTRAINT FK_CustomerAddress FOREIGN KEY(AddressID) REFERENCES [Address](AddressID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO
ALTER TABLE Customer ADD CONSTRAINT [DF_CustomerCreateDate] DEFAULT (GETDATE()) FOR CreateDate;
GO


CREATE TABLE Film (
    FilmID INT IDENTITY,
    Title VARCHAR(255) NOT NULL,
    [Description] TEXT,
    ReleaseYear VARCHAR(4),
    [Length] SMALLINT,
    Rating VARCHAR(10) DEFAULT 'G',
    LanguageID INT NOT NULL,
    PRIMARY KEY(FilmID),
    CONSTRAINT FK_FilmLanguage FOREIGN KEY(LanguageID) REFERENCES [Language](LanguageID)
);
GO
ALTER TABLE Film ADD CONSTRAINT CH_FilmRating CHECK(Rating IN ('G','PG','PG-13','R','NC-17'));
GO

CREATE TABLE [Cast] (
    ActorID INT NOT NULL,
    FilmID INT NOT NULL,
    PRIMARY KEY(ActorID, FilmID),
    CONSTRAINT FK_CastActor FOREIGN KEY(ActorID) REFERENCES Actor(ActorID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_CastFilm FOREIGN KEY(FilmID) REFERENCES Film(FilmID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

CREATE TABLE FilmGenre (
    FilmID INT NOT NULL,
    GenreID INT NOT NULL,
    PRIMARY KEY(FilmID, GenreID),
    CONSTRAINT FK_FFilmGenre FOREIGN KEY(FilmID) REFERENCES Film(FilmID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_GFilmGenre FOREIGN KEY(GenreID) REFERENCES Genre(GenreID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

CREATE TABLE Staff (
    StaffID INT IDENTITY,
    FirstName VARCHAR(45) NOT NULL,
    LastName VARCHAR(45) NOT NULL,
    Picture IMAGE,
    Email VARCHAR(50) NOT NULL,
    Username VARCHAR(50) NOT NULL,
    [Password] VARCHAR(40) NOT NULL,
    Salt UNIQUEIDENTIFIER,
    AddressID INT NOT NULL,
    StoreID INT NOT NULL,
    PRIMARY KEY(StaffID),
    CONSTRAINT AK_StaffEmail UNIQUE(Email),
    CONSTRAINT AK_StaffUsername UNIQUE(Username),
    CONSTRAINT FK_StaffAddress FOREIGN KEY(AddressID) REFERENCES [Address](AddressID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

CREATE TABLE Store (
    StoreID INT IDENTITY,
    [Name] VARCHAR(20) NOT NULL,
    AddressID INT NOT NULL,
    ManagerStaffID INT NOT NULL,
    PRIMARY KEY(StoreID),
    CONSTRAINT FK_StoreAddress FOREIGN KEY(AddressID) REFERENCES [Address](AddressID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_StoreManager FOREIGN KEY(ManagerStaffID) REFERENCES Staff(StaffID)
);
GO

ALTER TABLE Staff ADD CONSTRAINT FK_StaffStore FOREIGN KEY(StoreID) REFERENCES Store(StoreID);
GO

CREATE TABLE Inventory (
    InventoryID INT IDENTITY,
    RentalDuration TINYINT NOT NULL DEFAULT 3,
    RentalRate DECIMAL(4,2) NOT NULL DEFAULT 4.99,
    ReplacementCost DECIMAL(5,2) NOT NULL DEFAULT 19.99,
    SpecialFeatures VARCHAR(255),
    StoreID INT NOT NULL,
    DubbedLanguageID INT,
    FilmID INT NOT NULL,
    PRIMARY KEY(InventoryID),
    CONSTRAINT FK_InventoryStore FOREIGN KEY(StoreID) REFERENCES Store
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_InventoryDubbedLanguage FOREIGN KEY(DubbedLanguageID) REFERENCES [Language](LanguageID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_InventoryFilm FOREIGN KEY(FilmID) REFERENCES Film(FilmID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO
ALTER TABLE Inventory ADD CONSTRAINT CH_SpecialFeatures CHECK(SpecialFeatures IS NULL OR 
                                                              SpecialFeatures LIKE '%Trailers%' OR 
                                                              SpecialFeatures LIKE '%Commentaries%' OR 
                                                              SpecialFeatures LIKE '%Deleted Scenes%' OR 
                                                              SpecialFeatures LIKE '%Behind the Scenes%');
GO

CREATE TABLE Payment (
    PaymentID INT IDENTITY,
    Amount DECIMAL(5,2) NOT NULL,
    PaymentDate DATETIME NOT NULL,
    CustomerID INT NOT NULL,
    PRIMARY KEY(PaymentID),
    CONSTRAINT FK_PaymentCustomer FOREIGN KEY(CustomerID) REFERENCES Customer(CustomerID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO
ALTER TABLE Payment ADD CONSTRAINT [DF_PaymentDate] DEFAULT (GETDATE()) FOR PaymentDate;
GO

CREATE TABLE Rental (
    RentalID INT IDENTITY,
    ReturnDate DATETIME,
    InventoryID INT NOT NULL,
    PaymentID INT NOT NULL,
    PRIMARY KEY(RentalID),
    CONSTRAINT FK_RentalInventory FOREIGN KEY(InventoryID) REFERENCES Inventory(InventoryID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_RentalPayment FOREIGN KEY(PaymentID) REFERENCES Payment(PaymentID)
);
GO

--- CREATE VIEW ---
CREATE VIEW CustomerList
AS
SELECT
    c.CustomerID AS ID,
    c.FirstName + ' ' + c.LastName AS FullName,
    a.[Address],
    a.PostalCode AS ZipCode,
	a.Phone AS PhoneNumber, 
	ci.[Name] AS City,
	co.[Name] AS Country
FROM Customer AS c
JOIN [Address] AS a
    ON c.AddressID = a.AddressID
JOIN City AS ci
    ON a.CityID = ci.CityID
JOIN Country AS co
    ON ci.CountryID = co.CountryID;
GO

CREATE VIEW FilmList
AS
WITH FilmActorsAggregate AS (
    SELECT
        c.FilmID,
	    STRING_AGG(CONCAT(a.FirstName, ' ', a.LastName), ', ')
        WITHIN GROUP (ORDER BY a.FirstName, a.LastName) AS ActorList
    FROM [Cast] AS c
    JOIN Actor AS a
        ON c.ActorID = a.ActorID
    GROUP BY c.FilmID
),
FilmGenreAggregate AS (
    SELECT
        fg.FilmID,
        STRING_AGG(g.Name, ', ') AS GenreList
    FROM FilmGenre AS fg
    JOIN Genre AS g
        ON fg.GenreID = g.GenreID
    GROUP BY fg.FilmID
)
SELECT
    f.FilmID,
    f.Title,
    f.[Description],
	f.[Length], 
	f.Rating, 
    fga.GenreList,
    fa.ActorList
FROM Film AS f
LEFT JOIN FilmGenreAggregate AS fga
    ON f.FilmID = fga.FilmID
LEFT JOIN FilmActorsAggregate AS fa
    ON f.FilmID = fa.FilmID;
GO

CREATE VIEW StaffList
AS
SELECT
    s.StaffID AS ID, 
    s.FirstName + ' ' + s.LastName AS [FullName], 
    a.Address AS [Address], 
    a.PostalCode AS ZipCode, 
    a.Phone AS PhoneNumber,
	c.[Name] AS City, 
	co.[Name] AS Country, 
	st.[Name] AS Store
FROM Store AS st
JOIN Staff AS s
    ON st.StoreID = s.StoreID
JOIN [Address] AS a
    ON s.AddressID = a.AddressID
JOIN City AS c
    ON a.CityID = c.CityID
JOIN Country AS co
    ON c.CountryID = co.CountryID;
GO

CREATE VIEW ActorInfo
AS
    SELECT
        a.FirstName,
        a.LastName,
        STRING_AGG(f.Title, ', ')
        WITHIN GROUP (ORDER BY f.Title) AS FilmEnrolled
    FROM Actor AS a
    LEFT JOIN [Cast] AS c
        ON a.ActorID = c.ActorID
    LEFT JOIN Film AS f
        ON c.FilmID = f.FilmID
    GROUP BY a.ActorID, a.FirstName, a.LastName;
GO

--- CREATE FUNCTION ---
CREATE FUNCTION HashPassword(@PlainPassword VARCHAR(40), @Salt UNIQUEIDENTIFIER)
RETURNS VARBINARY(32)
AS
BEGIN
    DECLARE @SaltedPassword VARCHAR(100) = @PlainPassword + CAST(@Salt AS VARCHAR(36))
    RETURN HASHBYTES('SHA2_256', @SaltedPassword)
END;
GO

CREATE FUNCTION InventoryHeldByCustomer(@InventoryID INT)
RETURNS INT
AS
BEGIN
    DECLARE @CustomerID INT;

    SELECT @CustomerID = p.CustomerID
    FROM Rental AS r
    JOIN Payment AS p
        ON r.PaymentID = p.PaymentID
    WHERE ReturnDate IS NULL AND InventoryID = @InventoryID;

    RETURN @CustomerID; 
END;
GO

CREATE FUNCTION CustomerTotalPayment(@CustomerID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @TotalPayment DECIMAL(10,2);

    SELECT @TotalPayment = ISNULL(SUM(Amount), 0.0)
    FROM Payment
    WHERE CustomerID = @CustomerID;

    RETURN @TotalPayment;
END;
GO

CREATE FUNCTION GetAddressPhoneNumber(@AddressID INT)
RETURNS VARCHAR(40)
AS
BEGIN
    DECLARE @PhoneNumber VARCHAR(40);
    
    SELECT @PhoneNumber = Phone
    FROM [Address]
    WHERE AddressID = @AddressID;

    RETURN @PhoneNumber;
END;
GO

CREATE FUNCTION GetCustomerBalance(@CustomerID INT, @EffectiveDate DATETIME)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @TotalFees DECIMAL(10,2);
    DECLARE @Payments DECIMAL(10,2);

    SELECT @TotalFees = SUM
        (
            i.RentalRate +
            CASE
                WHEN ISNULL(r.ReturnDate, @EffectiveDate) > DATEADD(day, i.RentalDuration, p.PaymentDate)
                    THEN DATEDIFF(
                        day,
                        DATEADD(day, i.RentalDuration, p.PaymentDate),
                        ISNULL(r.ReturnDate, @EffectiveDate)
                    ) * i.RentalRate
                ELSE 0
            END
        )
    FROM Customer AS c
    JOIN Payment AS p
        ON c.CustomerID = p.CustomerID
    JOIN Rental AS r
        ON p.PaymentID = r.PaymentID
    JOIN Inventory AS i
        ON r.InventoryID = i.InventoryID
    WHERE p.PaymentDate <= @EffectiveDate AND c.CustomerID = @CustomerID;

    SELECT @Payments = SUM(amount)
    FROM Payment
    WHERE PaymentDate <= @EffectiveDate AND CustomerID = @CustomerID;

    RETURN @TotalFees - @Payments;
END;
GO

--- CREATE PROCEDURE ---
CREATE PROCEDURE FilmInStock
    @FilmID INT,
    @StoreID INT
AS
BEGIN
    SELECT InventoryID
    FROM Inventory
    WHERE FilmID = @FilmID AND
        StoreID = @StoreID AND
        dbo.InventoryHeldByCustomer(InventoryID) IS NULL;
END;
GO

CREATE PROCEDURE GetCustomersByPurchaseAmount
    @MinAmountPurchased DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LastMonthStart DATE;
    DECLARE @LastMonthEnd DATE;

    IF @MinAmountPurchased <= 0.00
    BEGIN
        SELECT 'Minimum monthly purchases parameter must be > 0.00' AS ErrorMessage;
        RETURN;
    END;

    SET @LastMonthStart = DATEADD(month, DATEDIFF(month, 0, GETDATE()) - 1, 0);
    SET @LastMonthEnd = EOMONTH(@LastMonthStart);

    SELECT CustomerID
    FROM Payment
    WHERE CAST(PaymentDate AS DATE) >= @LastMonthStart AND
        CAST(PaymentDate AS DATE) <= @LastMonthEnd
    GROUP BY CustomerID
    HAVING SUM(Amount) >= @MinAmountPurchased;
END;
GO

CREATE PROCEDURE NotReturnedInventories
	@StoreID INT
AS
BEGIN
	SELECT
		i.InventoryID,
		p.CustomerID,
		p.PaymentDate AS RentalDate,
		CASE
			WHEN GETDATE() > DATEADD(day, i.RentalDuration, p.PaymentDate) THEN 'Late'
			ELSE 'Not Late'
		END AS [Status]
	FROM Store AS s
	JOIN Inventory AS i
		ON s.StoreID = i.StoreID
	JOIN Rental AS r
		ON i.InventoryID = r.InventoryID
	JOIN Payment AS p
		ON r.PaymentID = p.PaymentID
	WHERE s.StoreID = @StoreID AND r.ReturnDate IS NULL
END;
GO

CREATE PROCEDURE ProcessNewRental
	@CustomerID INT,
	@InventoryID INT,
	@Amount DECIMAL(5,2)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION

		DECLARE @PaymentID INT;

		INSERT INTO Payment (Amount, CustomerID)
		VALUES (@Amount, @CustomerID);

		SET @PaymentID = SCOPE_IDENTITY();

		INSERT INTO Rental (InventoryID, PaymentID)
		VALUES (@InventoryID, @PaymentID);

		COMMIT TRANSACTION

		PRINT 'Rental and Payment successfully processed.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
			PRINT 'Transaction rolled back due to an error!';
		END;

		THROW;
	END CATCH;
END;
GO

--- CREATE TRIGGER ---
CREATE TRIGGER SetCredentials
ON Staff
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Staff (FirstName, LastName, AddressID, StoreID, Email, Username, Salt, [Password])
    SELECT
        i.FirstName,
        i.LastName,
        i.AddressID,
        i.StoreID,
        i.Email,
        ISNULL(i.Username, Email),
        s.Salt,
        CONVERT(
            VARCHAR(40),
            dbo.HashPassword(
                ISNULL(i.[Password], dbo.GetAddressPhoneNumber(i.AddressID)),
                s.Salt
            )
        )
    FROM INSERTED i
    CROSS APPLY (
        SELECT NEWID() AS Salt
    ) s
END;
GO
