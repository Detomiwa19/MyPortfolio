---Calculating percentage death among infected people
select location, date, total_cases, total_deaths, (convert(float, total_deaths)/convert(float, total_cases))*100 as DeathPercentage
from Project..coviddeaths
---where total_cases is not null and total_deaths is not null
where location like '%Africa%'
order by 1,2

---Calculating percentage of infected people from the total population
select location, date, total_cases, population, (convert(float, total_cases)/convert(float, population))*100 as covid_casesPercentage
from Project..coviddeaths
--where total_cases is not null and total_deaths is not null
where location like '%Africa%'
order by 1,2
--------------------------------
---Max deathcount based on continents
select continent, max(cast(total_deaths as int)) as HighestdeathCount
from Project..coviddeaths
where continent is not null
group by continent
order by HighestdeathCount desc
------------------------------------------
---Total continental deaths where continent is not empty(null)
select location, sum(convert(int, total_deaths)) as continental_deaths from project..coviddeaths
where continent is null
group by location;
------------------------------------------
--Total cases, total deaths and overallpercentage (globally) 
select  sum(new_cases) as new_cases, sum(new_deaths) as new_deaths, 
case
when sum(new_cases) = 0 then NULL
else
 (sum(new_deaths)/sum(new_cases))*100
end as new_deathpercent
from project..coviddeaths
where new_cases is not null and new_cases <> 0
-----------------------------------------
--Determining the cumulative vaccination coverage over time...using CTEs
with Cummulative_vac (continent, location, date, population, new_vaccination, Cummulative_vac_perloc)
as(
select distinct death.continent, death.location, death.date, death.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by death.location order by death.date ) as Cummulative_vac_perlocation
from project..covid_vac vac
join project..coviddeaths death
on death.location = vac.location and death.date = vac.date
where death.continent is not null and vac.new_vaccinations is not null
)
select *, (Cummulative_vac_perloc/population)*100 as percent_Cummulative_vac_perloc
from Cummulative_vac
order by 2,3
-------------------------------------------
---creating views in order select first 30 locations with their relative continents
drop view if exists continents
create view continents as
select continent, location, max(cast(total_deaths as int)) as HighestdeathCount
from Project..coviddeaths death
where continent is not null
group by continent, location
--order by HighestdeathCount desc

select top(30) continent, location from continents
order by location
-----------------------------------
drop view if exists cummulative
create view cummulative as
with Cummulative_vac (continent, location, date, population, new_vaccination, Cummulative_vac_perloc)
as(
select distinct death.continent, death.location, death.date, death.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by death.location order by death.date ) as Cummulative_vac_perlocation
from project..covid_vac vac
join project..coviddeaths death
on death.location = vac.location and death.date = vac.date
where death.continent is not null and vac.new_vaccinations is not null
)
select *, (Cummulative_vac_perloc/population)*100 as percent_Cummulative_vac_perloc
from Cummulative_vac

select * from cummulative
--------------------------------------
---calculating the location with the highest vaccination rate
select * from cummulative
where percent_Cummulative_vac_perloc = (select max(percent_Cummulative_vac_perloc) from cummulative)

