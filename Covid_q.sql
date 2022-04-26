-- This is the EDA of the covid data following Alex the anlyst
-- I have made many changes to the data and the queries 
-- according to what worked for me
-- my system is diffrent it's the Docker sql server on a macbook pro

-------------------------------------------------
-- SELECT COUNT(*)
-- FROM dbo.CovideDeaths
-- where [continent] is not null


Alter table dbo.CovideDeaths alter COLUMN total_cases DECIMAL (5, 2);
Alter table dbo.CovideDeaths alter COLUMN [population] bigint;
Alter table dbo.CovideDeaths alter COLUMN total_deaths bigint;
Alter table [dbo].[CovidVaccination] alter COLUMN new_vaccinations bigint;
Alter table [dbo].[CovidVaccination] alter COLUMN [positive_rate] float;
--Alter table [dbo].[CovideDeaths] alter COLUMN [date] datetime;


-- select data that we'll use 
select [location], convert(datetime, date, 103), total_cases, new_cases, total_deaths, population
from CovideDeaths
order by 1,2

-- Looking at the total cases vs total deaths for each country 

select  [location], [date], total_cases,population, (total_cases/(population *1.0))*100 as InfectedPop
from CovideDeaths
where [location] like '%states%'
Order  by  1,3

-- rate of deaths compared to cases 

select  [location], [date], total_cases,total_deaths, (total_deaths/(total_cases *1.0))*100 as deathPer
from CovideDeaths
where [location] like '%states%' and [continent] is not null
Order  by  1,2

--looking at highest Infection vs population

select  [location], [population], MAX(total_cases) as MaxCases, MAX(total_cases/(population *1.0))*100 as mostInfectedPopulation
from [dbo].[CovideDeaths]
group by [location], [population]
order by mostInfectedPopulation desc

-- Looking into the highest death rates based on the city
-- we had the issue of having some continents at the top 
-- we romved em by making sure it's not null
SELECT [location], max(cast(total_deaths as int)) as totDeaths
from [dbo].[CovideDeaths]
where [continent] is not null
GROUP by location
ORDER by totDeaths desc

-- let's split things by continent 

SELECT [location], max(cast(total_deaths as int)) as totDeaths
from [dbo].[CovideDeaths]
where [continent] is  null
GROUP by location 
ORDER by totDeaths desc

-- lets look at the percentage of deaths around the world 

select  sum(cast(new_cases as int)) as total_cases,sum(cast(new_deaths as int))as total_deaths, 
sum(cast(new_deaths as int))/sum(cast(new_cases as int)*1.00)*100.00 as deathPer
from CovideDeaths
where [continent] is not null
Order  by  1,2

-- join two tables 
SELECT  dea.continent, dea.[location], dea.[date], dea.[population],
vac.new_vaccinations, sum((vac.new_vaccinations )) over(
    PARTITION by dea.location 
    ORDER by dea.location, convert(datetime, vac.date, 103)
) as RollingPplVac
from dbo.CovideDeaths dea
join CovidVaccination vac
    on dea.[location] =vac.[location]
     and dea.[date]=vac.[date]
where dea.continent is not null
order by 2,convert(datetime, vac.date, 103) asc

---------------------------------------------------------
-- we make a CTE to make further calculations

with PopvsVac (continent,[location], [date],[population],new_vaccinations,RollingPplVac)
as (
    SELECT  dea.continent, dea.[location], dea.[date], dea.[population],
    vac.new_vaccinations, sum((vac.new_vaccinations )) over(
    PARTITION by dea.location 
    ORDER by dea.location, convert(datetime, vac.date, 103)
) as RollingPplVac
from dbo.CovideDeaths dea
join CovidVaccination vac
    on dea.[location] =vac.[location]
     and dea.[date]=vac.[date]
where dea.continent is not null
)
SELECT *, (RollingPplVac/(population*1.0))*100 as vacvspop
from PopvsVac


--temp table
DROP TABLE if EXISTS #pov
CREATE TABLE #PerPopvac
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPplVac NUMERIC
)

insert into #PerPopvac
    SELECT  dea.continent, dea.[location], dea.[date], dea.[population],
    vac.new_vaccinations, sum((vac.new_vaccinations )) over(
    PARTITION by dea.location 
    ORDER by dea.location, convert(datetime, dea.date, 103)
) as RollingPplVac
from dbo.CovideDeaths dea
join CovidVaccination vac
    on dea.[location] =vac.[location]
     and dea.[date]=vac.[date]
where dea.continent is not null

SELECT *, (RollingPplVac/(population*1.0))*100 as vacvspop
from #PerPopvac


-- creating views for later Visuals 

CREATE VIEW deathPer 
as 
select  sum(cast(new_cases as int)) as total_cases,sum(cast(new_deaths as int))as total_deaths, 
sum(cast(new_deaths as int))/sum(cast(new_cases as int)*1.00)*100.00 as deathPer
from CovideDeaths
where [continent] is not null
--Order  by  1,2

select * 
from deathPer


create view totDeathLoc as 
SELECT [location], max(cast(total_deaths as int)) as totDeaths
from [dbo].[CovideDeaths]
where [continent] is  null
GROUP by location 
ORDER by totDeaths desc

select * 
from totDeathLoc 