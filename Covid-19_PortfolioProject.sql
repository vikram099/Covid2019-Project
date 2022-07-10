
/*
DATA ANALYST PROJECT:

Explored the Data of Covid-19 Deaths and Vaccinations and joining valuable data set to achieve 
different results recived from https://ourworldindata.org/covid-deaths

Skills used: Joins, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types, CTE's, Temp Tables

*/

use PortfolioProject
go


select * from PortfolioProject..coviddeaths$
order by 3,4


-- Ques1.
-- Looking at total cases vs total deaths and calculating death percentage in all countries as of 4th April,2022.

select location,date,total_cases,total_deaths, (total_deaths/total_cases * 100) as DeathPercentage 
from PortfolioProject..coviddeaths$
order by 1,2


-- Ques2.
-- Calculating death percentage per total cases in United States as of 4th April,2022.

select location,date,total_cases,total_deaths, (total_deaths/total_cases * 100) as DeathPercentage 
from PortfolioProject..coviddeaths$
where location like'%states%'
order by 1,2


--Ques3.
-- Comparing total cases vs population in India 
---shows what percentage of population got covid as of 4th April,2022.

select location,date,total_cases,population, (total_cases/population * 100) as CasePercentage 
from PortfolioProject..coviddeaths$
where location like'%india%'
order by 1,2


--Ques4.
-- Now if we want to know counties with highest infection rate as of 4th April,2022.

select location,population, max(total_cases) as highestcases, MAX((total_cases/population)) * 100 as InfectedCasePercentage 
from PortfolioProject..coviddeaths$
group by location, population
order by InfectedCasePercentage desc


-- Ques5.
-- Now if we want to find the country with highest death count as of 4th April,2022.

select location, max(cast(total_deaths as int)) as Totaldeathcases
from PortfolioProject..coviddeaths$
where continent is not null
group by location
order by Totaldeathcases desc

--Calculate the total number of deaths per continent
--we will set (where continent to null to find accurate numbers)


select location, max(cast(total_deaths as int)) as Totaldeathcases
from PortfolioProject..coviddeaths$
where continent is  null and location <> 'high income' and  location <> 'upper middle income' and location <> 'lower middle income'
group by location
order by Totaldeathcases desc



------Now lets join the data consisting of deaths and data consisting of vaccination together

Select * from PortfolioProject..coviddeaths$ deaths 
join PortfolioProject..covidvaccination$ vaccinations 
on deaths.location = vaccinations.location and deaths.date = vaccinations.date 


-- Compare the Total population vs vaccinations using Partition By

Select deaths.continent, deaths.location,deaths.date,deaths.population,vaccinations.new_vaccinations, sum(cast(vaccinations.new_vaccinations as bigint)) over (partition by deaths.location) as rollingpeoplevaccinated
from PortfolioProject..coviddeaths$ deaths 
join PortfolioProject..covidvaccination$ vaccinations 
on deaths.location = vaccinations.location and deaths.date = vaccinations.date 
where deaths.continent is not null
order by 2,3


--Now we ill use CTE to perform calculation on partion by in the previous query

With populationvsvaccine (continent, location, Date, Population, new_vaccinations, rollingpeoplevaccinated)
as
(
Select deaths.continent, deaths.location,deaths.date,deaths.population,vaccinations.new_vaccinations, sum(cast(vaccinations.new_vaccinations as bigint)) over (partition by deaths.location) as rollingpeoplevaccinated
from PortfolioProject..coviddeaths$ deaths 
join PortfolioProject..covidvaccination$ vaccinations 
on deaths.location = vaccinations.location and deaths.date = vaccinations.date 
where deaths.continent is not null
--order by 2,3
)
Select *, (rollingpeoplevaccinated/population)*100 as PercentageVaccinated
from populationvsvaccine


-- We can aslo perform calculations on Partitions By using Temp Tabeles:



Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations
, SUM(CONVERT(bigint,vaccinations.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as RollingPeopleVaccinated
From PortfolioProject..coviddeaths$ deaths
Join PortfolioProject..covidvaccination$ vaccinations
	On deaths.location = vaccinations.location
	and deaths.date = vaccinations.date



Select *, (rollingpeoplevaccinated/Population)* 100 as PercentageVaccinated
from #PercentPopulationVaccinated

-- We can always make use of Drop table if we want to make any changes in table

Drop table if exists #percentpopulationvaccinated




-----Making use of views to store data for visualizations

Create View PercentageVaccinated as
Select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations
, SUM(CONVERT(bigint,vaccinations.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as RollingPeopleVaccinated
From PortfolioProject..coviddeaths$ deaths
Join PortfolioProject..covidvaccination$ vaccinations
	On deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
	where deaths.continent is not null
