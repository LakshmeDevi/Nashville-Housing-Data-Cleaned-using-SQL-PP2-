--- Cleaning data with SQL queries: (90% of cleaning and 10% of ETL stuff kinda  in the referance : Alex the Analyst Github) -

--SELECT *
--FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData

---a). Standardize Date Format

--- Convert the datetype
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData

----Update the table now that u coverted the datetype
Update HousingData
SET SaleDate = CONVERT(Date, SaleDate)

----But since the date type did not change in the existing column but created a new column, add a new column to the table by altering the table structure with a new name
ALTER TABLE HousingData
Add SaleShortDate Date;

----With this query , u can add a new column with converted datetype change
Update HousingData
SET SaleShortDate = CONVERT(Date, SaleDate)

----Check it :
SELECT *
FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData

 ---b). Populate Property Address data
		---New learning : new function : ISNULL function

 SELECT *
    FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData
    ---where PropertyAddress is null
	order by ParcelID  ---(referance point)

	----Self-join:
	SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
    FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData A
	JOIN NashvilleHousingCleaningPortfolioProject2.dbo.HousingData B
	 on A.ParcelID = B.ParcelID
	 AND A.[UniqueID ] <> B.[UniqueID ]
	 where A.PropertyAddress is null

UPDATE A
SET PropertyAddress =ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData A
	JOIN NashvilleHousingCleaningPortfolioProject2.dbo.HousingData B
	 on A.ParcelID = B.ParcelID
	 AND A.[UniqueID ] <> B.[UniqueID ]
	 where A.PropertyAddress is null

---C). Breaking out Address(es) into Individual Columns ( Address, City, State):
	   ---New learning : new function : SUBSTRING and 
	   ---								CHARINDEX function 
	   ---								LEN function

SELECT PropertyAddress
    FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData

SELECT
SUBSTRING(PropertyAddress, 1,CHARINDEX(',', PropertyAddress) -1 ) as Address
---CHARINDEX(',', PropertyAddress)
    FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData

SELECT
SUBSTRING(PropertyAddress, 1,CHARINDEX(',', PropertyAddress) -1 ) as StreetAddress,
SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) as City

    FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData

ALTER TABLE HousingData
Add PropertyStreetAddress NVarchar(255);
Update HousingData
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1,CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE HousingData
Add PropertyCity NVarchar(255);
Update HousingData
SET PropertyCity = SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress))

SELECT *
FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData


----c) Simpler way to break the Owner Address to individual3 columns :
	---New learning : new function : PARSENAME function for delimited by value stuff;
	--- //By default Parsename function looks for 'Periods' as delimiter so replace them for commas!
	----Better design practice to alter all columns i.e table and add columns first and set columns with that function/formula
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
 PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousingCleaningPortfolioProject2..HousingData

ALTER TABLE HousingData
Add OwnerStreetAddress NVarchar(255);

ALTER TABLE HousingData
Add OwnerCity NVarchar(255);

ALTER TABLE HousingData
Add OwnerState NVarchar(255);

Update HousingData
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

Update HousingData
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

Update HousingData
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData

----d). Change 'Y' and 'N' to "Yes" and "No" respectively in the "SoldAsVacant" column:
	----DISTINCT function for a list of different values; ...

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData
Group by SoldAsVacant
order by 2

Select SoldAsVacant,
	CASE When SoldAsVacant = 'Y' THEN 'Yes'
		 When SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END     
FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData

Update HousingData
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
		 When SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END  

---To check again :
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData
Group by SoldAsVacant
order by 2

---e). Remove Duplicates : using a window function -
----Better practice to not delete all duplicates for the sake of keeping originad data intact and using temp table to store all duplicate values seperately...
----To identify duplicates in the first places , different ways : Ranknumber, dense rank number,
    ---- New learning : new function : Row number

WITH RowNumCTE AS (
--1
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

	FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData
	----where row_num > 1
	----order by ParcelID
	)
---2

	-----Msg 207, Level 16, State 1, Line 159
---------Invalid column name 'row_num'. The above query of 13 lines from 1 to 2 wouldn't work with "Where" in query since it has Windows function " PARTITION BY 
	
	DELETE 
	FROM RowNumCTE
	where row_num > 1
	---Order by PropertyAddress

	---Check :
	SELECT *
     FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData


---F). Delete Unused Columns

SELECT *
FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData

Alter table HousingData
DROP COLUMN OwnerAddress, SaleDate, PropertyAddress

---Just to tell u to go a step back and check with these 2 lines of queries just from above
SELECT *
FROM NashvilleHousingCleaningPortfolioProject2.dbo.HousingData











