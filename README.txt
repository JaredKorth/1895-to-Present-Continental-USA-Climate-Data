SQL Analysis of Climate Data for the Continental United States, 1895-2023 by Jared Korth

DESCRIPTION
A series of queries written in MySQL [using Workbench 8.0], exploring temperature and precipitation data from the National Climatic Data Center [NCDC]. The data runs consistently from the starting point of January 1895 through the most recent update of April 2023. 
Note that the period 1931-1990 was used in original calibration of precipitation data; to avoid redundancy and as a simple demarcation option, many of the queries compare values from before and after that period.

The .csv files used to create the tables are included in this repository
 - the table creation statements for most of them were trimmed from the queries
 - tables for temperature data were truncated to fit on github. Data for ncdc_fips >= 40001 has been cut.

For up-to-date data, users can download the following files: climdiv-tmpccy-v1.0.0- climdiv-tmincy-v1.0.0- climdiv-tmaxcy-v1.0.0- climdiv-sp24dv-v1.0.0- climdiv-sp01dv-v1.0.0- county-to-climdivs.txt from https://www.ncei.noaa.gov/pub/data/cirs/climdiv/?C=S;O=D, along with any table that matches postal or NCDC FIPS codes to county and state names. As that data will not develop much with time, I recommend just using the 'postal county state' .csv included here.
Some cleaning will be required.

Alternatively, a link to the visualized data is pending.


CREDITS
Thanks to NCDC -> NCEI -> NESDIS -> NOAA -> DoC -> the United States Government for gathering and maintaining this data, and for making it freely available. Thanks to countless scientists: for collecting this and other data, for reliable and repeatable methods of measurement, and for your inspiring enthusiasm. Thanks to the developers of various data analysis tools including MySQL and Tableau.

Due to the combined efforts of groups like those above, it is no longer necessary to take anybody's word for granted, nor to wonder when various groups speak of politicized questions and prove their opposite points with equally convincing charts and numbers. It is now possible to download original data, examine and analyze it ourselves, and find unfiltered truth. While falsehood is uncommonly pervasive today, the truth is also uncommonly accessible.
