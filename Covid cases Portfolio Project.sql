--select * from PortfolioProject..CovidDeaths
--order by 3,4

--select * from PortfolioProject..CovidVaccinations
--order by 3,4

select location,date,total_cases,new_cases,total_deaths,population
from CovidDeaths
order by 1,2

--looking at total cases vs total deaths
--shows the likelihood of dying if you contact covid in your country
select location,date,total_cases,total_deaths,
(total_deaths/total_cases)*100 as death_percentage
from CovidDeaths
where location like '%india%'
order by 1,2

--looking at the total cases vs the population
select location,date,total_cases,population,(total_cases/population)*100 as deathpercentage
from CovidDeaths
--where location like '%india%'
order by 1,2

--looking at contruies with highest infection rate compared to population
select location,population,MAX(total_cases) as highest_infection,max((total_cases/population))*100 as 
percentpopulationinfected
from CovidDeaths
group by location,population
order by 4 desc

--how many people died due to infection
select location,max(cast(total_deaths as int)) as totaldeaths
from CovidDeaths
where continent is not null
group by location
order by totaldeaths desc

-- lets group by continent
select continent,max(cast(total_deaths as int)) as totaldeaths
from CovidDeaths
where continent is not  null
group by continent
order by totaldeaths desc

--showing continent with the highest deathcount
select continent,Max(total_deaths) as deathcount
from CovidDeaths
where continent is not null
group by continent
order by 2 desc

--global numbers

select sum(new_cases) as totalcases,sum(cast(new_deaths as int)) as newdeaths, sum(cast(new_deaths as int))/
	   SUM(new_cases)*100 as deathprecent
from CovidDeaths
where continent is not null
--group by date
order by 1,2 

--looking at total population vs vaccination

select dea.location,dea.date,dea.population,vac.new_vaccinations,
       sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) 
       as roolingvaccinationsum
from CovidDeaths dea
	join CovidVaccinations vac
	  on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null
order by 1,2

--vaacinated / population percentage using common table expression

with PopvsVac (continent,location,date,population,new_vaccinations,roolpepvac)
as
(
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
       sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) 
	   as roolpepVac
from CovidDeaths dea
	join CovidVaccinations vac
	   on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null
--order by 2,3
)
select * ,(roolpepvac/population)*100
from PopvsVac

--temptable
drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(continent varchar(100),location varchar(100), date datetime,
 population numeric,new_vaccination numeric,roolpepvac numeric)

insert into #percentpopulationvaccinated
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
		sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) 
		as roolpepVac
from CovidDeaths dea
	join CovidVaccinations vac
	   on dea.location=vac.location and dea.date=vac.date
--where dea.continent is not null
select * ,(roolpepvac/population)*100
from #percentpopulationvaccinated

--creating view to store data for later visualization 

create view percentpopulationvaccinated as
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
       SUM(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date)
       as rollingpeoplevaccinated
from CovidDeaths dea
	join CovidVaccinations vac
	    on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null