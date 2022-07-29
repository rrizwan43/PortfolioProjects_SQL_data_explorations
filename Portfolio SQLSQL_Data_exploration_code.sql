select * from portfolioproject..['covid-death']
order by 3, 4

--select * 
--from portfolioproject..['covid-vaccinations']

--SELECTING THE CASES,DEATH,POPULATION BY COUNTRY

SELECT LOCATION, DATE, TOTAL_CASES, NEW_CASES, TOTAL_DEATHS, POPULATION
FROM portfolioproject..['covid-death']
ORDER BY 1,2

--LOOKING AT TOTAL CASES AND TOTAL DEATHS
-- SHOWS THE LIKELIHOOD OF DYING IF YOU CONTRACT COVID IN YOUR COUNTRY.

SELECT LOCATION, DATE, TOTAL_CASES, TOTAL_DEATHS, (TOTAL_DEATHS/total_cases)*100 AS DEATH_PERCENTAGE
FROM portfolioproject..['covid-death']
WHERE LOCATION LIKE '%STATES%'
ORDER BY 1,2

--LOOKING AT TOTAL CASES VS POPULATION
--SHOWS WHAT PERCENTAGE OF POPULATION GOT COVID

SELECT LOCATION, DATE, TOTAL_CASES, population, (total_cases/population)*100 AS INFECTED_WITH_COVID
FROM portfolioproject..['covid-death']
WHERE LOCATION LIKE '%STATE%'
ORDER BY 1,2


-- LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION

SELECT LOCATION, population, MAX(TOTAL_CASES) AS HIGHESTINFECTIONCOUNT, MAX(total_cases/population)*100 AS PERCENTPOPULATIONINFECTED
FROM portfolioproject..['covid-death']
--WHERE LOCATION LIKE '%STATE%'
GROUP BY LOCATION, POPULATION
ORDER BY PERCENTPOPULATIONINFECTED DESC


-- SHOWING COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION

SELECT LOCATION, MAX(CAST(TOTAL_DEATHS AS int)) AS TOTALDEATHCOUNT
FROM portfolioproject..['covid-death']
--WHERE LOCATION LIKE '%STATE%'
WHERE continent IS NOT NULL   -- THIS IS TO TAKE THE DATA ONLY FOR ROWS WHICH ALSO HAVE CONTINENT
GROUP BY LOCATION
ORDER BY TOTALDEATHCOUNT DESC


------LETS BREAK THINGS DOWN BY CONTINENT

SELECT CONTINENT, MAX(CAST(TOTAL_DEATHS AS int)) AS TOTALDEATHCOUNT
FROM portfolioproject..['covid-death']
--WHERE LOCATION LIKE '%STATE%'
WHERE continent IS NOT NULL   -- THIS IS TO TAKE THE DATA ONLY FOR ROWS WHICH ALSO HAVE CONTINENT
GROUP BY continent
ORDER BY TOTALDEATHCOUNT DESC


--THE ABOVE QUERY IS NOT GIVING US THE CORRECT NUMBERS
--SO WE WRITE IT IN THIS WAY.
SELECT location, MAX(CAST(TOTAL_DEATHS AS int)) AS TOTALDEATHCOUNT
FROM portfolioproject..['covid-death']
--WHERE LOCATION LIKE '%STATE%'
WHERE continent IS NULL   -- THIS IS TO TAKE THE DATA ONLY FOR ROWS WHICH ALSO HAVE CONTINENT
GROUP BY location
ORDER BY TOTALDEATHCOUNT DESC


--------------------------------------------------------------------------------------------------------------------------------------------
-- GLOBAL NUMBERS

--SELECT DATE, TOTAL_CASES, TOTAL_DEATHS, (TOTAL_DEATHS/total_cases)*100 AS DEATH_PERCENTAGE
--FROM portfolioproject..['covid-death']
----WHERE LOCATION LIKE '%STATES%'
--WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY 1,2 


-- this tells us the total cases and total deaths per day and percentage
select date, SUM(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Death_percentage
from portfolioproject..['covid-death']
where continent is  not null
group by date
order by 1,2


-- this will tell us total cases and total deaths and overall percentage

select SUM(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Death_percentage
from portfolioproject..['covid-death']
where continent is  not null
--group by date
order by 1,2

----------------------------------------------------------------------------------------------------------------------------------------------

--joining two tables covid deaths and covid vaccinations

select * 
from portfolioproject..['covid-death'] dea
join portfolioproject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date

-- Now looking at total population (what is total amount of people who got vaccinated)

select dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
--RollingPeopleVaccinated   (we cannot use a column we just created so we will have to create CTE)
from portfolioproject..['covid-death'] dea
join portfolioproject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3



-- Use CTE
with PopvsVac(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as 
(
select dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
--RollingPeopleVaccinated   (we cannot use a column we just created so we will have to create CTE)
from portfolioproject..['covid-death'] dea
join portfolioproject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/population)*100 from PopvsVac



--temp table
create table #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated

select dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
--RollingPeopleVaccinated   (we cannot use a column we just created so we will have to create CTE)
from portfolioproject..['covid-death'] dea
join portfolioproject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated



--Creating Views to store data for later visualization

create view PercentPopulationVaccinated as 
Select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, 
dea.date) as RollingPeopleVaccinated
from portfolioproject..['covid-death'] as dea
join portfolioproject..['covid-vaccinations'] as vac
 on dea.location = vac.location
 and dea.date = vac.date
where dea.continent is not null
