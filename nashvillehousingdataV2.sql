# Drop Table if exists 
#DROP TABLE IF EXISTS `pp`.`pp`;
#DROP TABLE IF EXISTS `pp`.`nhd`;

/*ALTER TABLE `pp`.`pp` 
RENAME TO  `pp`.`nhd` ;*/


# Select all columns by current name 
/*
SELECT `nhd`.`uniqueid`,
    `nhd`.`parcelid`,
    `nhd`.`landuse`,
    `nhd`.`propertyaddress`,
    `nhd`.`saledate`,
    `nhd`.`saleprice`,
    `nhd`.`legalreference`,
    `nhd`.`soldasvacant`,
    `nhd`.`ownername`,
    `nhd`.`owneraddress`,
    `nhd`.`acreage`,
    `nhd`.`taxdistrict`,
    `nhd`.`landvalue`,
    `nhd`.`buildingvalue`,
    `nhd`.`totalvalue`,
    `nhd`.`yearbuilt`,
    `nhd`.`bedrooms`,
    `nhd`.`fullbath`,
    `nhd`.`halfbath`
FROM `pp`.`nhd`;
*/

# From here - all sql statements will be need to be highlighted and run as they won't be commented out 
# Manually inspect data - check to ensure the data apppears consistent 
SELECT * 
FROM pp.nhd
LIMIT 10;

----------------------------------------------------
-- Standardize Date Format

-- Standardize Date Format

SELECT saledate, CONVERT(saledate,	DATE) AS saledateconverted
FROM pp.nhd
LIMIT 10;

#Add Column 
ALTER TABLE pp.nhd
ADD SaleDateConverted Date;


SET SQL_SAFE_UPDATES=0;

UPDATE pp.nhd
SET saledateconverted = SaleDate; 

# Modify date format to Date instead of date time 
ALTER TABLE pp.nhd MODIFY COLUMN SaleDateConverted DATE;


#Fix error code 1175 - you are using safe update mode 
/*SET SQL_SAFE_UPDATES=0;*/

#Populate values into new column 
/*UPDATE pp.nhd
SET saledateconverted = CONVERT(saledate, DATE);  */


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property address data

SELECT *
	FROM pp.nhd
	WHERE Propertyaddress IS NULL
ORDER BY parcelid
LIMIT 100;



SELECT a.parcelid, a.Propertyaddress, b.parcelid, b.Propertyaddress, IFNULL(a.Propertyaddress,b.Propertyaddress) AS update_addr
FROM pp.nhd a
JOIN pp.nhd b
	ON a.parcelid = b.parcelid
	AND a.uniqueid <> b.uniqueid
WHERE a.Propertyaddress IS NULL;

/*UPDAte doesn't work on MYSQL - SQLServer has ISNULL function but equivalent IFNULL in MYSQL doesn't allow update

UPDATE pp.nhd AS a
SET Propertyaddress = IFNULL(a.propertyaddress,b.propertyaddress)
FROM pp.nhd AS a
JOIN pp.nhd AS b
	ON a.parcelid = b.parcelid
	AND a.uniqueid <> b.uniqueid
WHERE a.Propertyaddress IS NULL;
*/

#Therefore Use Instead join 
UPDATE pp.nhd AS a
LEFT JOIN pp.nhd b 
	ON a.parcelid = b.parcelid 
	AND a.uniqueid <> b.uniqueid 
SET a.propertyaddress = b.propertyaddress 
WHERE
    a.PropertyAddress IS NULL;


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out address into Individual Columns (address, City, State). For Property Address and OwnerAddress

#Current address format is not useful for segmentation 
SELECT Propertyaddress
FROM pp.nhd
ORDER BY parcelid
LIMIT 50;

#Breakdown information into Address line 1, city and State(applicable for owner address)  - SQL Server Specific See difference when ran in MYSQL 
SELECT propertyaddress, 
	SUBSTR(propertyaddress, 1, LOCATE(',', propertyaddress) -1 ) AS address1, 
	SUBSTR(propertyaddress, LOCATE(',', propertyaddress) + 1 , CHAR_LENGTH(propertyaddress)) AS address2
    FROM pp.nhd
LIMIT 50;

# For MY SQL - Breakdown information into Address line 1, city and State 
SELECT
SUBSTRING_INDEX(propertyaddress, ",", 1) AS addr1,
SUBSTRING_INDEX((SUBSTRING_INDEX(propertyaddress, ",", -2)),",",1) AS city
FROM pp.nhd;


#Add New Columns required 
ALTER TABLE pp.nhd
ADD propertysplit_addr Nvarchar(255);
ALTER TABLE pp.nhd
ADD propertysplit_city Nvarchar(255);


#Update Columns with split data
UPDATE pp.nhd
SET propertysplit_addr = SUBSTRING_INDEX(propertyaddress, ",", 1);

UPDATE pp.nhd
SET propertysplit_city = SUBSTRING_INDEX(propertyaddress, ",", -1);


#Check data. Visually inspect 
SELECT *
FROM pp.nhd
LIMIT 50;

# Repeat address split for owner address column 

SELECT owneraddress
FROM pp.nhd;


SELECT
SUBSTRING_INDEX(owneraddress, ",", 1) AS string1,
SUBSTRING_INDEX((SUBSTRING_INDEX(owneraddress, ",", -2)),",",1) AS string2,
SUBSTRING_INDEX(owneraddress, ",", -1) AS string3
FROM pp.nhd;

# Add columns 

ALTER TABLE pp.nhd
ADD ownersplit_addr Nvarchar(255);

ALTER TABLE pp.nhd
ADD ownersplit_city Nvarchar(255);

ALTER TABLE pp.nhd
ADD ownersplit_state Nvarchar(32);

# Update columns with owner address data 
UPDATE pp.nhd
SET ownersplit_addr  = SUBSTRING_INDEX(owneraddress, ",", 1); 

UPDATE pp.nhd
SET ownersplit_city  = SUBSTRING_INDEX((SUBSTRING_INDEX(owneraddress, ",", -2)),",",1); 

UPDATE pp.nhd
SET ownersplit_state= SUBSTRING_INDEX(owneraddress, ",", -1);

# Visually inspect the data - 50 rows 
SELECT *
FROM pp.nhd
LIMIT 50;


--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "SoldASVacant" field


SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM pp.nhd
Group by SoldAsVacant
ORDER BY 2;



#Code to 
SELECT uniqueid, SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM pp.nhd
WHERE SoldAsVacant NOT IN ('Yes','No');

#Run Update on values 
UPDATE pp.nhd
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;






-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

SELECT DISTINCT parcelid, COUNT(parcelid)  
FROM pp.nhd
GROUP BY parcelid 
HAVING COUNT(parcelid)  > 1
ORDER BY parcelid ASC;

 
#Output duplicate information for reference 
SELECT * 
FROM pp.nhd
	WHERE parcelid in 
    (
		SELECT distinct(parcelid)
			FROM pp.nhd
			GROUP BY parcelid 
			HAVING COUNT(parcelid)  > 1
			ORDER BY parcelid ASC
	);

#If you want to check any values 
SELECT * 
FROM pp.nhd
	WHERE parcelid in 
    (
    '081 02 0 144.00'#--, '015 14 0 060.00'
    );
 
SELECT ROW_NUMBER() OVER (
ORDER BY propertyaddress, ownername
) row_num, propertyaddress, ownername, parcelid
FROM pp.nhd;


WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY parcelid,
				 Propertyaddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					parcelid
					) row_num

FROM pp.nhd
)
SELECT *  
FROM RowNumCTE
WHERE row_num > 1
Order by parcelid;


#Fix error code 1175 - you are using safe update mode 
SET SQL_SAFE_UPDATES=0;

# Below query is timing out error code 2013 - Lost connection - extend timeout - works on second connection? 
#SELECT *
DELETE t1 
FROM pp.nhd AS t1
JOIN pp.nhd AS t2 
ON t1.parcelid = t2.parcelid 
	AND t1.propertyaddress = t2.propertyaddress
	AND t1.saleprice = t2.saleprice
	AND t1.saledate = t2.saledate
	AND t1.legalreference = t2.legalreference
    AND t1.uniqueid > t2.uniqueid;
#ORDER BY t1.parcelid, t1.propertyaddress, t1.saleprice, t1.saledate, t1.legalreference;

#Fix error code 1175 - you are using safe update mode - post change 
SET SQL_SAFE_UPDATES=1;






SELECT COUNT(*)
FROM pp.nhd;


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


# Visual inspect columns 
SELECT *
FROM pp.nhd
LIMIT 100;

SET SQL_SAFE_UPDATES=0;
#Drop owneraddress 
ALTER TABLE pp.nhd
DROP COLUMN owneraddress;

#Drop propertyaddress 
ALTER TABLE pp.nhd
DROP COLUMN propertyaddress;

#Drop saledate 
ALTER TABLE pp.nhd
DROP COLUMN saledate;

# May drop this column in iteration 2 
SELECT DISTINCT taxdistrict
FROM pp.nhd;

# Run through ETL Section of project. 



