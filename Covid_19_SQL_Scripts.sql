-- =============================================
-- Dataset Analysis fo COVID-19
-- Duration: 2020 to 2022
-- Description: SQL queries to analyze COVID-19 data, including cases, deaths, and vaccinations.
-- Purpose: Provides insights into COVID-19 metrics by country and date.
-- =============================================

-- =============================================
-- Initial Data Exploration: Preview COVID-19 data
-- =============================================
SELECT * 
FROM Portfolio_Project..Covid_Deaths
ORDER BY 3,4

SELECT * 
FROM Portfolio_Project..Covid_vaccinations
ORDER BY 3,4

SELECT country, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project..Covid_Deaths
ORDER BY 1,2

-- =============================================
-- Case and Death Analysis
-- =============================================
-- Total cases and deaths by country and date
SELECT country, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project..Covid_Deaths
ORDER BY country, date;

-- Total cases, total deaths, and death percentage for all countries
SELECT 
    country, 
    MAX(total_cases) AS total_cases, 
    MAX(total_deaths) AS total_deaths, 
    ROUND((MAX(total_deaths) * 100.0) / NULLIF(MAX(total_cases), 0), 2) AS Death_Percentage
FROM Portfolio_Project..Covid_Deaths
GROUP BY country
ORDER BY Death_Percentage DESC, country, total_cases

-- Percentage of population infected with COVID: India
SELECT country, date, population, total_cases, ROUND((CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) *100,2) AS Covid_percentage
FROM Portfolio_Project..Covid_Deaths
WHERE country like '%india%'
ORDER BY 1,2

-- Countries with the highest infection rates compared to population
SELECT country, population, 
       MAX(total_cases) AS HighestInfectionCount, 
       MAX(ROUND((CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100, 2)) AS PercentagePopulationInfected
FROM Portfolio_Project..Covid_Deaths
GROUP BY country, population
ORDER BY PercentagePopulationInfected DESC;

-- Countries with highest death counts
SELECT country, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Portfolio_Project..Covid_Deaths
GROUP BY country
ORDER BY TotalDeathCount DESC;

-- =============================================
-- Global Trends
-- =============================================
-- Global daily new cases and deaths, with deaths-to-cases ratio
SELECT date, 
	SUM(new_cases) AS Total_New_Cases,
    SUM(CAST(new_deaths AS INT)) AS Total_New_Deaths,
    SUM(CAST(new_deaths AS INT)) * 1.0 / NULLIF(SUM(new_cases), 0) AS Deaths_Per_Case_Ratio
FROM Portfolio_Project..Covid_Deaths
GROUP BY date
ORDER BY date;

-- =============================================
-- Vaccination Analysis
-- =============================================
-- Join Covid_Deaths and Covid_vaccinations tables
SELECT * 
FROM Portfolio_Project..Covid_Deaths D
JOIN Portfolio_Project..Covid_vaccinations V
ON D.country = V.country
AND D.date = V.date

-- Total population vs daily vaccinations
SELECT d.country, d.date, d.population, V.new_vaccinations
FROM Portfolio_Project..Covid_Deaths D
JOIN Portfolio_Project..Covid_vaccinations V
ON D.country = V.country
AND D.date = V.date
ORDER BY 2,3

-- Total population vs cumulative vaccinations
SELECT d.country, d.date, d.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER (PARTITION BY d.country ORDER BY d.country, d.date) AS Cummulative_Vaccinations
FROM Portfolio_Project..Covid_Deaths D
JOIN Portfolio_Project..Covid_vaccinations V
ON D.country = V.country
AND D.date = V.date
ORDER BY 2,3

-- Cumulative fully vaccinated percentage by population
WITH PopvsFullVac (Country, date, population, people_fully_vaccinated) AS
(
   SELECT d.country, d.date, d.population, v.people_fully_vaccinated
   FROM Portfolio_Project..Covid_Deaths D
   JOIN Portfolio_Project..Covid_vaccinations V
   ON D.country = V.country
   AND D.date = V.date
)
SELECT *,
   (people_fully_vaccinated * 100.0 / population) AS Fully_Vaccinated_Percentage
FROM PopvsFullVac;

-- =============================================
-- Additional Analysis
-- =============================================
-- Mortality Analysis
SELECT d.date, d.country,
    d.total_deaths, d.new_deaths_per_million, d.hospital_beds_per_thousand,
    CASE WHEN d.total_cases > 0 THEN ROUND((d.total_deaths * 1.0 / d.total_cases) * 100, 2) ELSE NULL END AS Case_Fatality_Ratio,
    v.people_fully_vaccinated_per_hundred
FROM Portfolio_Project..Covid_Deaths d
JOIN Portfolio_Project..Covid_Vaccinations v
ON d.country = v.country AND d.date = v.date
AND d.date BETWEEN '2020-01-01' AND '2022-12-31'
ORDER BY country;

-- Vaccination Impact on Death Rates
SELECT v.date, v.country,
    v.people_fully_vaccinated_per_hundred,
    d.new_deaths_smoothed_per_million,
    d.stringency_index
FROM Portfolio_Project..Covid_Vaccinations v
JOIN Portfolio_Project..Covid_Deaths d
ON v.country = d.country AND v.date = d.date
ORDER BY country;

-- Healthcare Capacity and COVID-19 Strain
SELECT d.date, d.country,
    d.hospital_beds_per_thousand, d.hosp_patients_per_million,
    d.weekly_hosp_admissions_per_million
FROM Portfolio_Project..Covid_Deaths d
ORDER BY d.country, d.date;

-- Policy Analysis
SELECT d.date, d.country, d.stringency_index, d.reproduction_rate, d.new_cases_smoothed, d.new_deaths_smoothed_per_million, v.people_fully_vaccinated_per_hundred
FROM covid_deaths d
JOIN covid_vaccinations v 
  ON d.country = v.country AND d.date = v.date
ORDER BY d.country, d.date;

-- Explore Socioeconomic Drivers
SELECT d.country,
  MAX(d.population_density) AS population_density,
  MAX(d.gdp_per_capita) AS gdp_per_capita,
  MAX(d.extreme_poverty) AS extreme_poverty,
  MAX(d.human_development_index) AS hdi,
  MAX(v.people_fully_vaccinated_per_hundred) AS fully_vaccinated
FROM covid_deaths d
JOIN covid_vaccinations v 
  ON d.country = v.country
GROUP BY d.country;

-- Malaysia VS Peers
SELECT d.date, d.country, d.new_cases_smoothed, v.people_fully_vaccinated_per_hundred, d.stringency_index, d.hospital_beds_per_thousand
FROM covid_deaths d
JOIN covid_vaccinations v 
  ON d.country = v.country AND d.date = v.date
WHERE d.country IN ('Malaysia', 'Singapore', 'Indonesia', 'Vietnam', 'South Korea', 'India')


-- =============================================
-- Creating a Table for Vaccination Data
-- =============================================
-- Create a temporary table for fully vaccinated data
CREATE TABLE #PercentPopulationVaccinated (
    Country NVARCHAR(50),
    Date DATETIME,
    Population FLOAT,
    New_Vaccination FLOAT,
    People_Fully_Vaccinated FLOAT
);

-- Insert Data
INSERT INTO #PercentPopulationVaccinated
SELECT d.country, d.date, d.population, v.new_vaccinations,
    v.people_fully_vaccinated
FROM 
    Portfolio_Project..Covid_Deaths D
JOIN 
    Portfolio_Project..Covid_vaccinations V
ON 
    D.country = V.country
    AND D.date = V.date;

-- Select data with fully vaccinated percentage calculation
SELECT *, 
       (People_Fully_Vaccinated / Population) * 100 AS Fully_Vaccinated_Percentage
FROM #PercentPopulationVaccinated;

-- Create View to Store Data for Visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT d.country, d.date, 
    d.population, 
    v.new_vaccinations, 
    v.people_fully_vaccinated, 
    (v.people_fully_vaccinated * 100.0 / d.population) AS Fully_Vaccinated_Percentage
FROM 
    Portfolio_Project..Covid_Deaths d
JOIN 
    Portfolio_Project..Covid_vaccinations v
ON 
    d.country = v.country 
    AND d.date = v.date;


SELECT *
FROM #PercentPopulationVaccinated










