--Covid Data Analysis 
--Canice Cunnane 
--10/06/2022
--Using POSTGRES SQL 
-- Version 1.0 



--Initial Check counts 
/*SELECT count(*) 
FROM covidvaccinations;*/
--221260 rows returned @ 10/11/2022 

/*SELECT count(*)
FROM coviddeaths;*/
--221260 rows returned @ 10/11/2022 

-- Visually inspect data
/*SELECT * 
FROM coviddeaths
ORDER BY 3,4;*/

-- Visually inspect data
/*SELECT *
FROM covidvaccinations
--WHERE total_tests IS NOT NULL
ORDER BY 3,4;*/

/*SELECT * 
FROM coviddeaths
ORDER BY 3,4;*/

--Select the data we are going to use 
--Canice Cunnane 
--10/06/2022 10:06am

/*SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY location ASC, date ASC; */

/*====================================================================
--       Looking at Total Cases vs Total deaths
====================================================================*/

/* 
--------------------------------------------------------------------
A. Show likelihood of dying if you contract Covid by geographic area 
--------------------------------------------------------------------
*/


/* 
--------------------------------------------------------------------
Query 1. Show percentage  likelihood of dying if you contract Covid by country area 
--------------------------------------------------------------------
*/
/*SELECT location, date, total_cases, total_deaths, ROUND(((total_deaths::decimal/total_cases)*100),2) as death_percentage 
FROM coviddeaths
WHERE location LIKE '%States' --and date like in ('2021-04-30')
ORDER BY location ASC, date ASC; */

/* 
--------------------------------------------------------------------
Query 2. Show death count if you contract Covid by country area 
--------------------------------------------------------------------
*/
--Looking at countries that have the highest death count after infection 
/*SELECT location, continent, MAX(total_deaths::decimal) as highest_death_count_by_country 
FROM coviddeaths
WHERE total_deaths IS NOT NULL  AND continent IS NOT NULL
GROUP BY location, continent
order by highest_death_count_by_country DESC
LIMIT 10;*/

/* 
--------------------------------------------------------------------
Query 3. Show death count if you contract Covid by continent area 
--------------------------------------------------------------------
*/
--Looking at continents that have the highest death count after infection 
/*SELECT  continent, MAX(total_deaths::decimal) as highest_death_count_by_continent 
FROM coviddeaths
WHERE total_deaths IS NOT NULL  AND continent IS NOT NULL
GROUP BY continent
order by highest_death_count_by_continent DESC
LIMIT 10;*/


/* 
--------------------------------------------------------------------
Query 4. Show death count if you contract Covid by continent and other grouping 
--------------------------------------------------------------------
*/
--Looking at continents that have the highest death count after infection 
/*
SELECT  continent, location, MAX(total_deaths::decimal) as highest_death_count_by_continent 
FROM coviddeaths
WHERE total_deaths IS NOT NULL  AND continent IS NULL
GROUP BY continent, location
order by highest_death_count_by_continent DESC
LIMIT 15;
*/

/* 
--------------------------------------------------------------------
Query 5. Show death count if you contract Covid by location - country
--------------------------------------------------------------------
*/

--Looking at countries that have the highest rate of infection  TOP 10
-- Only use with data after certain date 

/*
SELECT location, population, total_deaths, total_cases, MAX(ROUND(((total_deaths::decimal/total_cases)*100),2)) as highest_death_rate_by_country 
FROM coviddeaths
WHERE total_deaths IS NOT NULL AND total_cases IS NOT NULL AND date = '2022-09-01'
GROUP BY location, population, total_deaths, total_cases
order by highest_death_rate_by_country DESC
LIMIT 10; 
*/


/* 
--------------------------------------------------------------------
B. Show total cases by volume and percentage by geographic area 
--------------------------------------------------------------------
*/

--Looking at Total Cases vs population
--Show what percentage of population got covid


/* 
--------------------------------------------------------------------
Query 6. Show total cases by proportion of population count by specificcountry
--------------------------------------------------------------------
*/

/*
SELECT location, date, total_cases, population, ROUND(((total_cases::decimal/population)*100),2) as infected_percentage_by_country 
FROM coviddeaths
WHERE location LIKE '%Ireland' --and date like in ('2021-04-30')
ORDER BY location ASC, date ASC; 
*/

/* 
--------------------------------------------------------------------
Query 7. Show total cases by proportion of population count by location - country
--------------------------------------------------------------------
*/

--Looking at countries that have the highest rate of infection  TOP 10
/*
SELECT location, population, MAX(ROUND(((total_cases::decimal/population)*100),2)) as highest_infected_countries 
FROM coviddeaths
WHERE total_cases IS NOT NULL AND population IS NOT NULL 
GROUP BY location, population
order by highest_infected_countries DESC
LIMIT 10;
*/

------ GLOBAL Numbers 
--Query 8. Query to show the global numbers - aka the world 
--------------------------------------------------------------

/*SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, ROUND((SUM(new_deaths::decimal)/SUM(new_cases))*100,2) as death_percentage 
FROM coviddeaths 
WHERE continent IS NOT NULL AND new_cases > 0 ;   */



/*
========================================================
--Query 9. Query Joining vaccinations and deaths tables 
Visually inspect Join is ok 
==============================================================
*/

/*SELECT * 
FROM public.covidvaccinations AS v1
JOIN public.coviddeaths as d1
	ON v1.iso_code = d1.iso_code 
	AND v1.date = d1.date
LIMIT 1000;*/

/*
========================================================
--Query 10. Looking at Total Populations vs Vaccinations  

==============================================================
*/
/*
SELECT d1.continent, d1.location, d1.date, d1.population, v1.new_vaccinations, 
		SUM(v1.new_vaccinations) OVER (PARTITION BY d1.iso_code ORDER BY d1.iso_code, d1.date) AS Rolling_Vaccination_Count
FROM public.covidvaccinations AS v1
JOIN public.coviddeaths as d1
	ON v1.iso_code = d1.iso_code 
	AND v1.date = d1.date
WHERE d1.continent IS NOT NULL AND d1.location = 'Albania'
ORDER BY d1.location, d1.date
LIMIT 10000;

*/

/*
========================================================
--Query 10. Looking at Total Populations vs Vaccinations  

==============================================================
*/

/*
WITH popvsvac(continent, location, date, population, new_vaccinations, rolling_vaccination_count) AS (
SELECT d1.continent, d1.location, d1.date, d1.population, v1.new_vaccinations, 
		SUM(v1.new_vaccinations) OVER (PARTITION BY d1.iso_code ORDER BY d1.iso_code, d1.date) AS rolling_vaccination_count
FROM public.covidvaccinations AS v1
JOIN public.coviddeaths as d1
	ON v1.iso_code = d1.iso_code 
	AND v1.date = d1.date
WHERE d1.continent IS NOT NULL)

SELECT *, ROUND((rolling_vaccination_count::decimal/population)*100,2) AS population_vaccinated_percent
FROM popvsvac
ORDER BY 2,3
LIMIT 900;

*/

/*
=================================================
CREATE TABLE #PercentPopulationVaccinated 
===================================================
*/


--DROP TABLE IF EXISTS percent_population_vaccinated
/*
CREATE TABLE percent_population_vaccinated 
(
	continent CHARACTER VARYING(255), 
	location CHARACTER VARYING(255), 
	date date, 
	population bigint, 
	new_vaccinations bigint, 
	rolling_vaccination_count double precision
)
;
*/

/*
INSERT INTO percent_population_vaccinated
(
SELECT d1.continent, d1.location, d1.date, d1.population, v1.new_vaccinations, 
		SUM(v1.new_vaccinations) OVER (PARTITION BY d1.iso_code ORDER BY d1.iso_code, d1.date) AS rolling_vaccination_count
FROM public.covidvaccinations AS v1
JOIN public.coviddeaths as d1
	ON v1.iso_code = d1.iso_code 
	AND v1.date = d1.date
WHERE d1.continent IS NOT NULL);
*/

/*
SELECT *, ROUND((rolling_vaccination_count::decimal/population)*100,2) AS population_vaccinated_percent 
FROM percent_population_vaccinated
WHERE location = 'Ireland'
ORDER BY 2,3
LIMIT 5900;
*/


CREATE VIEW percent_population_vaccinated_view AS (
SELECT d1.continent, d1.location, d1.date, d1.population, v1.new_vaccinations, 
		SUM(v1.new_vaccinations) OVER (PARTITION BY d1.iso_code ORDER BY d1.iso_code, d1.date) AS rolling_vaccination_count
FROM public.covidvaccinations AS v1
JOIN public.coviddeaths as d1
	ON v1.iso_code = d1.iso_code 
	AND v1.date = d1.date
WHERE d1.continent IS NOT NULL
);