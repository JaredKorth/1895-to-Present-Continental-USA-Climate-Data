-- Querying climate data on the continental United States from 1895-2023

USE usa_climate;

/*
'clim_div', a numeric ID column, created as CHAR type to retain leading zeroes
'year' column also CHAR type to bypass YEAR's 1901 minimum and DATE's requirement for month/day
*/
DROP TABLE IF EXISTS precip_24mo;
CREATE TABLE precip_24mo
(clim_div char(4) NOT NULL,
year char(4) NOT NULL,
January float,
February float,
March float,
April float,
May float,
June float,
July float,
August float,
September float,
October float,
November float,
December float
);

LOAD DATA INFILE "C:/***/precip 24 month csv.csv"
INTO TABLE precip_24mo
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Creating a table for similarly structured data
DROP TABLE IF EXISTS precip_1mo;
CREATE TABLE precip_1mo LIKE precip_24mo;
LOAD DATA INFILE "C:/***/precip 1 month csv.csv"
INTO TABLE precip_1mo
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- Combining tables for comprehensive reference
CREATE VIEW full_ids AS
SELECT gi.*, gn.county, gn.state
FROM geo_ids gi
JOIN geo_names gn
ON gi.postal_fips = gn.postal_fips;


-- Removing incomplete/irrelevant data (e.g. non-continental areas)
WITH fipsless_counties AS
(
SELECT gn.county 
FROM geo_names gn
LEFT JOIN geo_ids gi
ON gn.postal_fips = gi.postal_fips
WHERE ncdc_fips IS NULL
)
DELETE FROM geo_names
WHERE county IN (SELECT * FROM fipsless_counties);

-- Confirming desired result
SELECT * FROM full_ids;


/*
60+ lines for this table creation feels like a lot, but using CTEs proved to be vastly faster
 than subqueries or CASE statements, and more readable than temp tables.
  
Still takes ~five seconds to run, so I eventually saved it as a table rather than a view.
 In real world application, my choice would depend on company policy regarding database normalization
 (new tables that can be calculated from existing tables).
 
TODO - had to Edit > Preferences > Query Editor, disable code completion to keep Workbench responsive while
  typing this query. Turn that on again when finished.
*/
CREATE TABLE county_averages
WITH past_min AS
(
SELECT ncdc_fips, ROUND(AVG(january+february+march+april+may+june+july+august+september+october+november+december)/12, 2) AS past_minimum
FROM temps_min
WHERE year < 1931
GROUP BY ncdc_fips
),
recent_min AS
(
SELECT ncdc_fips, ROUND(AVG(january+february+march+april+may+june+july+august+september+october+november+december)/12, 2) AS recent_minimum
FROM temps_min
WHERE year > 1990
GROUP BY ncdc_fips
),
past_avg AS
(SELECT ncdc_fips, ROUND(AVG(january+february+march+april+may+june+july+august+september+october+november+december)/12, 2) AS past_average
FROM temps_avg
WHERE year < 1931
GROUP BY ncdc_fips
),
recent_avg AS
(SELECT ncdc_fips, ROUND(AVG(january+february+march+april+may+june+july+august+september+october+november+december)/12, 2) AS recent_average
FROM temps_avg
WHERE year > 1990
GROUP BY ncdc_fips
),
past_max AS
(SELECT ncdc_fips, ROUND(AVG(january+february+march+april+may+june+july+august+september+october+november+december)/12, 2) AS past_maximum
FROM temps_max
WHERE year < 1931
GROUP BY ncdc_fips
),
recent_max AS
(SELECT ncdc_fips, ROUND(AVG(january+february+march+april+may+june+july+august+september+october+november+december)/12, 2) AS recent_maximum
FROM temps_max
WHERE year > 1990
GROUP BY ncdc_fips
),
avg_precip_past AS
(SELECT clim_div, 
	ROUND(AVG(january+february+march+april+may+june+july+august+september+october+november+december)/12, 2) AS past_precip
FROM precip_1mo
WHERE year < 1931
GROUP BY clim_div
),
avg_precip_recent AS
(SELECT clim_div, 
	ROUND(AVG(january+february+march+april+may+june+july+august+september+october+november+december)/12, 2) AS recent_precip
FROM precip_1mo
WHERE year > 1990
GROUP BY clim_div
)
SELECT id.ncdc_fips, past_minimum, recent_minimum, past_average, recent_average,
		past_maximum, recent_maximum, past_precip, recent_precip
FROM full_ids id
JOIN past_min USING (ncdc_fips)
JOIN recent_min USING (ncdc_fips)
JOIN past_avg USING (ncdc_fips)
JOIN recent_avg USING (ncdc_fips)
JOIN past_max USING (ncdc_fips)
JOIN recent_max USING (ncdc_fips)
JOIN avg_precip_past USING (clim_div)
JOIN avg_precip_recent USING (clim_div);


-- Now just exploring the data
CREATE VIEW shift AS
SELECT ncdc_fips,
	CAST(recent_minimum - past_minimum AS DECIMAL(4,2)) AS delta_min,
	CAST(recent_average - past_average AS DECIMAL(4,2)) AS delta_avg,
    CAST(recent_maximum - past_maximum AS DECIMAL(4,2)) AS delta_max,
    CAST(recent_precip - past_precip AS DECIMAL(4,2)) AS delta_precip
FROM county_averages;


SELECT 'lows' AS '',
	(SELECT COUNT(*) FROM shift WHERE delta_min < 0) AS lower,
    (SELECT COUNT(*) FROM shift WHERE delta_min = 0) AS no_change,
    (SELECT COUNT(*) FROM shift WHERE delta_min > 0) AS higher
UNION
SELECT 'averages',    
	(SELECT COUNT(*) FROM shift WHERE delta_avg < 0),
    (SELECT COUNT(*) FROM shift WHERE delta_avg = 0),
    (SELECT COUNT(*) FROM shift WHERE delta_avg > 0)
UNION
SELECT 'highs',    
	(SELECT COUNT(*) FROM shift WHERE delta_max < 0),
    (SELECT COUNT(*) FROM shift WHERE delta_max = 0),
    (SELECT COUNT(*) FROM shift WHERE delta_max > 0)
UNION
SELECT 'precipitation',    
	(SELECT COUNT(*) FROM shift WHERE delta_precip < 0),
    (SELECT COUNT(*) FROM shift WHERE delta_precip = 0),
    (SELECT COUNT(*) FROM shift WHERE delta_precip > 0);


SELECT	'average increase' AS '',
    (SELECT ROUND(AVG(delta_min), 2) FROM shift WHERE delta_min > 0) AS lows,
	(SELECT ROUND(AVG(delta_avg), 2) FROM shift WHERE delta_avg > 0) AS average,
    (SELECT ROUND(AVG(delta_max), 2) FROM shift WHERE delta_max > 0) AS highs,
    (SELECT ROUND(AVG(delta_precip), 2) FROM shift WHERE delta_precip > 0) AS precip
UNION
SELECT 'average decrease',
	(SELECT ROUND(AVG(delta_min), 2) FROM shift WHERE delta_min < 0),
	(SELECT ROUND(AVG(delta_avg), 2) FROM shift WHERE delta_avg < 0),
    (SELECT ROUND(AVG(delta_max), 2) FROM shift WHERE delta_max < 0),
    (SELECT ROUND(AVG(delta_precip), 2) FROM shift WHERE delta_precip < 0)
UNION
SELECT 'greatest increase',
	(SELECT ROUND(MAX(delta_min), 2) FROM shift),
	(SELECT ROUND(MAX(delta_avg), 2) FROM shift),
    (SELECT ROUND(MAX(delta_max), 2) FROM shift),
    (SELECT ROUND(MAX(delta_precip), 2) FROM shift)
UNION    
SELECT 'greatest decrease',
	(SELECT ROUND(MIN(delta_min), 2) FROM shift),
	(SELECT ROUND(MIN(delta_avg), 2) FROM shift),
    (SELECT ROUND(MIN(delta_max), 2) FROM shift),
    (SELECT ROUND(MIN(delta_precip), 2) FROM shift);


CREATE VIEW temps_variance AS
SELECT id.ncdc_fips, mn.year,
	ROUND(mx.january-mn.january, 1) AS January,
	ROUND(mx.february - mn.february, 1) AS February,
	ROUND(mx.march - mn.march, 1)  AS March,
	ROUND(mx.april - mn.april, 1)  AS April,
	ROUND(mx.may - mn.may, 1)  AS May,
	ROUND(mx.june - mn.june, 1)  AS June,
	ROUND(mx.july - mn.july, 1)  AS July,
	ROUND(mx.august - mn.august, 1)  AS August,
	ROUND(mx.september - mn.september, 1)  AS September,
	ROUND(mx.october - mn.october, 1)  AS October,
	ROUND(mx.november - mn.november, 1)  AS November,
	ROUND(mx.december - mn.december, 1)  AS December
FROM full_ids id
JOIN temps_min mn USING (ncdc_fips)
JOIN temps_max mx USING (ncdc_fips, year);


CREATE VIEW delta_var AS
SELECT ncdc_fips,
ROUND(
	AVG(CASE WHEN year > 1990 THEN (january+february+march+april+may+june+july+august+september+october+november+december)/12 END) -
	AVG(CASE WHEN year < 1931 THEN (january+february+march+april+may+june+july+august+september+october+november+december)/12 END)
	, 2) as delta_variance
FROM temps_variance
GROUP BY ncdc_fips;

-- realizing that while 'variance' made sense earlier, "delta variance" translates roughly to "change change" and 
--  doesn't very well describe a table for diurnal temperature range data.
RENAME TABLE temps_variance TO temps_range, delta_var TO delta_range;


-- adding new data to our comprehensive table
ALTER TABLE county_averages
ADD COLUMN past_range DOUBLE, 
ADD COLUMN recent_range DOUBLE;

WITH cte_past_range AS
(
SELECT ncdc_fips,
	ROUND(AVG(CASE WHEN year < 1931 THEN (january+february+march+april+may+june+july+august+september+october+november+december)/12 END), 2)
AS past_range
FROM temps_range
GROUP BY ncdc_fips
),
cte_recent_range AS
(
SELECT ncdc_fips,
	ROUND(AVG(CASE WHEN year > 1990 THEN (january+february+march+april+may+june+july+august+september+october+november+december)/12 END), 2)
AS recent_range
FROM temps_range
GROUP BY ncdc_fips)
UPDATE county_averages ca
JOIN cte_past_range pr USING (ncdc_fips)
JOIN cte_recent_range rr USING (ncdc_fips)
SET ca.past_range = pr.past_range, ca.recent_range = rr.recent_range;


-- Exporting
SELECT id.*, 
	ca.past_minimum, ca.recent_minimum, ca.past_average, ca.recent_average, ca.past_maximum, ca.recent_maximum,
		ca.past_precip, ca.recent_precip, ca.past_range, ca.recent_range,
	sh.delta_min, sh.delta_avg, sh.delta_max, sh.delta_precip,
    dr.delta_variance AS delta_range
FROM full_ids id
JOIN county_averages ca USING (ncdc_fips)
JOIN shift sh USING (ncdc_fips)
JOIN delta_range dr USING (ncdc_fips)
INTO OUTFILE "C:/***/climate county averages csv.csv"
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n';

SELECT * FROM temps_range
INTO OUTFILE "C:/***/temps daily range csv.csv"
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n';

