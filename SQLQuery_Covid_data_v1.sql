--1) select columns of interest
select Location, date, total_cases, new_cases, total_deaths, population
from Portfolio_Project..[CoviddeathsCSV]
order by 1,2 --sort the selected columns by the first two which are location and date

--2) view new column which is calculated as percentage of total_cases versus total_deaths for everyday in all countries
Select location, date, total_cases, total_deaths, 
(CAST(total_deaths as float)/NULLIF(CAST(total_cases as float),0)) * 100 as Deathpercentage --cast varchar columns into floats for calculations, remove divide by zero error by NULLIF
from Portfolio_Project..CoviddeathsCSV
where location like '%states%' --select particular country of interest
order by 1,2

-- 3) view new column which is calculated as percentage of total_cases versus population for everyday globally
Select date, SUM(cast(new_cases as float)) as NewCases, SUM(cast(new_deaths as float)) as NewDeaths, SUM(cast(new_deaths as float))/NULLIF(SUM(cast(new_cases as float)),0)*100 as DeathPercentage 
from Portfolio_Project..CoviddeathsCSV
where continent is not null --if continent is null then it would be in the country column, disregard these 
Group by date
order by DeathPercentage desc --see from largest percentages


-- 4)view new column which is countries with highest infection rate (total_cases) versus population for all countries
Select location, MAX(total_cases) as HighestInfectionCount, population, --select the maximum total_cases per country so far
MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0))) * 100 AS PercentPopInfected
from Portfolio_Project..CoviddeathsCSV
Group by location, population
order by PercentPopInfected desc --compare highest rates of infections in differnet countries

--5) view new column which is countries with highest death rate (total_deaths) for all countries
UPDATE Portfolio_Project..[CoviddeathsCSV] --first put null in continent empty cells so they can be selected
SET continent = NULLIF(continent, '')

Select location, MAX(cast(total_deaths as float)) as HighestDeathCount 
from Portfolio_Project..CoviddeathsCSV
where continent is not null
Group by location
order by HighestDeathCount desc 

--6) view new column which is continents with highest death rate
Select continent, MAX(cast(total_deaths as float)) as HighestDeathCount 
from Portfolio_Project..CoviddeathsCSV
where continent is not null 
Group by continent
order by HighestDeathCount desc --see highest rates of infections in continents

--7) display columns for global information on new_cases, new_deaths and caluclate their percentages
Select date, SUM(cast(new_cases as float)) as NewCases, SUM(cast(new_deaths as float)) as NewDeaths, (SUM(cast(new_deaths as float)) / NULLIF(SUM(cast(new_cases as float)),0))*100 as DeathPercentage 
from Portfolio_Project..CoviddeathsCSV
where continent is not null 
Group by date
order by DeathPercentage

--8) Making a JOIN of the two tables using location and date as keys: 
Select *
from Portfolio_Project..CoviddeathsCSV dea
Join Portfolio_Project..Covid_vaccinationsCSV vac
	on dea.location=vac.location
	and dea.date=vac.date

--9) View population versus vaccination for everyday in each country: 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from Portfolio_Project..CoviddeathsCSV dea
Join Portfolio_Project..Covid_vaccinationsCSV vac
	on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null
order by 2,3

--10) Determine the total vaccinations per location using PARTITION function: 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast (vac.new_vaccinations as float)) over (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated -- set partition for new_vaccinations by location and date 
from Portfolio_Project..CoviddeathsCSV dea
Join Portfolio_Project..Covid_vaccinationsCSV vac
	on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null
order by 2,3

--11) Determine the percentage total vaccinations per population location using CTE 
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)--temporary table called 'PopvsVac' is created and percentage can be worked out from temporary columns
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast (vac.new_vaccinations as float)) over (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated

from Portfolio_Project..CoviddeathsCSV dea
Join Portfolio_Project..Covid_vaccinationsCSV vac
	on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/population)*100
from PopvsVac



--12) The above could have been done by creating NEW TABLE which contains the columns from original 2 tables:
drop table if exists #PercentPopulationVaccinated --necessary for alterations to occur
create table #PercentPopulationVaccinated 
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
New_vaccinations float,
RollingPeopleVaccinated float
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast (vac.new_vaccinations as float)) over (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated

from Portfolio_Project..CoviddeathsCSV dea
Join Portfolio_Project..Covid_vaccinationsCSV vac
	on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated

--13) Creating a VIEW for future visualizations
--can use query of death numbers for the continents: 
Select continent, MAX(cast(total_deaths as int)) as HighestDeathCount 
from Portfolio_Project..CoviddeathsCSV
where continent is not null 
Group by continent
