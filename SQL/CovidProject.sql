SELECT *
FROM CovidProject..Deaths
Where continent is null
order by 3, 4

SELECT *
FROM CovidProject..Vax
order by 3, 4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..Deaths
order by 1,2

-- explore the table data_types
EXEC sp_help Deaths

-- Seeing Total Cases vs Total Deaths
-- Shows the likelihood of dying with Covid in Australia
SELECT location, date, total_cases, total_deaths, Round((total_deaths/total_cases)*100, 2) AS PercentageDeaths
FROM CovidProject..Deaths
WHERE location LIKE '%australia%'
order by 1, 2

-- Seeing Total Cases vs Population
-- Shows what percentage of population got Covid 
SELECT location, date, population, total_cases,  Round((total_cases/population)*100, 2) AS PercInfected
FROM CovidProject..Deaths
WHERE location LIKE '%australia%'
order by 1, 2

-- Looking at Countries with highest infection rate with respect to population
SELECT location, population, max(total_cases) as InfectionCount,  max(round((total_cases/population)*100, 2)) AS PercInfected
FROM CovidProject..Deaths
WHERE population >10000000
GROUP BY location, population
Order by 4 desc

-- Interesting obserevation 
---> the percentage infected number is ordered roughly according to the national income level
-- (and literally according to the different income groups)
-- Maybe something to do with the amount of tests conducted per capita

--Looking at Countries with highest death rate with respect to population
SELECT location, population, max(total_deaths) as DeathCount,  max(round((total_deaths/population)*100, 2)) AS PercDeaths
FROM CovidProject..Deaths
WHERE population >10000000 
GROUP BY location, population
Order by 4 desc

-- Interesting obserevation 
---> South American countries succumbed more to Covid compared to any other region (especially Peru)
---> similar to the previous query, the percentage deaths is ordered roughly according to the national income level
-- (and literally according to the different income groups)
-- Maybe something to do with the quality of data reported

-- Same thing as above, but keeping only nations 
SELECT location, population, max(total_deaths) as DeathCount,  max(round((total_deaths/population)*100, 2)) AS PercDeaths
FROM CovidProject..Deaths
WHERE population >10000000 and continent is not null
GROUP BY location, population
Order by 3 desc

-- To break things down by country

SELECT location, max(total_deaths) as DeathCount
FROM CovidProject..Deaths
WHERE continent is not null
GROUP BY location
Order by DeathCount desc 

SELECT location, max(total_deaths) as DeathCount,  max(round((total_deaths/population)*100, 2)) AS PercDeaths
FROM CovidProject..Deaths
WHERE continent is not null
GROUP BY location
Order by PercDeaths desc 

-- To break things down by continent

SELECT continent, max(total_deaths) as DeathCount
FROM CovidProject..Deaths
WHERE continent is not null
GROUP BY continent
Order by DeathCount desc 

SELECT continent, max(total_deaths) as DeathCount, max(round((total_deaths/population)*100, 2)) AS PercDeaths
FROM CovidProject..Deaths
WHERE continent is not null
GROUP BY continent
Order by PercDeaths desc 

-- Global IQ

-- Aggregated New cases and deaths per day

SELECT date, SUM(new_cases) as NewCases, SUM(new_deaths) as NewDeaths, ROUND(ISNULL(SUM(new_deaths)/NULLIF(SUM(new_cases), 0) * 100, 0), 2) as PercDeaths
FROM CovidProject..Deaths
WHERE continent is not null
Group By date
Order by 1, 2

-- Total cases and deaths till now

SELECT SUM(new_cases) as NewCases, SUM(new_deaths) as NewDeaths, ROUND(ISNULL(SUM(new_deaths)/NULLIF(SUM(new_cases), 0) * 100, 0), 2) as PercDeaths
FROM CovidProject..Deaths
WHERE continent is not null
Order by 1, 2


-- Joining both the tables
SELECT *
FROM CovidProject..Deaths d
JOIN CovidProject..Vax v
	ON d.location = v.location
	AND d.date = v.date

-- Taking a look at total population vs vaccinations
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as VaxCount
FROM CovidProject..Deaths d
JOIN CovidProject..Vax v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
ORDER BY 2, 3

-- Putting the above query through as a CTE 
-- Taking a look at the percentage of population vaccinated after each day

WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, VaxCount)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as VaxCount
FROM CovidProject..Deaths d
JOIN CovidProject..Vax v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
)
SELECT *, ROUND((CONVERT(FLOAT, VaxCount)/Population) * 100, 2) AS PercentageVaxxedCumulative, 
ROUND((CONVERT(FLOAT, New_Vaccinations)/Population) * 100, 2) AS PercentageVaxxedPerDay
FROM PopvsVac
WHERE location LIKE '%UNITED STATES%'


-- Using a Temp table

DROP TABLE IF EXISTS #PercPopVax
CREATE TABLE #PercPopVax
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_Vaccinations NUMERIC,
VaxCount NUMERIC
)
INSERT INTO #PercPopVax
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as VaxCount
FROM CovidProject..Deaths d
JOIN CovidProject..Vax v
	ON d.location = v.location
	AND d.date = v.date
--WHERE d.continent is not null

SELECT *, ROUND((CONVERT(FLOAT, VaxCount)/Population) * 100, 2) AS PercentageVaxxedCumulative, 
ROUND((CONVERT(FLOAT, New_Vaccinations)/Population) * 100, 2) AS PercentageVaxxedPerDay
FROM #PercPopVax
WHERE Location LIKE 'United States'


-- Create View

CREATE VIEW PercPopVaxxed AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as VaxCount
FROM CovidProject..Deaths d
JOIN CovidProject..Vax v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
