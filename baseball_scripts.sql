-- 1. What range of years for baseball games played does the provided database cover?
SELECT DISTINCT yearid
FROM teams;

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT
	namegiven,
	namelast,
	height,
	teams.name,
	COUNT(*) AS games_played
FROM appearances
	INNER JOIN teams USING (teamid, yearid)
	INNER JOIN (
		SELECT *
		FROM people
		ORDER BY height
		LIMIT 1) AS shortest_player USING(playerid)
GROUP BY playerid, namegiven, namelast, height, teams.name;

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
WITH vandy_players AS(
	SELECT DISTINCT playerid
	FROM collegeplaying
	WHERE schoolid = 'vandy'
)
SELECT 
	namegiven,
	namelast,
	SUM(salary)::numeric::money AS total
FROM people
	INNER JOIN vandy_players USING(playerid)
	INNER JOIN salaries USING(playerid)
GROUP BY playerid
ORDER BY total DESC;

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.
SELECT
	CASE WHEN pos LIKE 'OF' THEN 'Outfield'
		WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery' END AS position,
	SUM (po) AS putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position;

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
SELECT
	(yearid / 10) * 10 AS decade,
	ROUND(AVG(so::numeric / G::numeric), 2) AS avg_so,
	ROUND(AVG(hr::numeric / G::numeric), 2) AS avg_hr
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;

-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.
SELECT
	namegiven,
	namelast,
	ROUND(SUM(COALESCE(sb,0))::numeric / SUM(COALESCE(sb,0) + COALESCE(cs,0))::numeric, 3) AS success_rate
FROM batting
	INNER JOIN people USING (playerid)
WHERE yearid = 2016
GROUP BY playerid, namegiven, namelast
HAVING SUM(COALESCE(sb,0) + COALESCE(cs,0)) >= 20
ORDER BY success_rate DESC
LIMIT 1;

-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. 
-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
SELECT yearid, 
	teamid, 
	W AS wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
		AND WSWin <> 
		'Y'
ORDER BY wins DESC
LIMIT 1;
-- Answer: 2001 SEA

SELECT yearid,
	teamid,
	W AS wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
		AND WSWin = 'Y'
ORDER BY wins;
-- Answer: 1981 LAN - 63 (player strike in the midst of the season)

SELECT yearid,
	teamid,
	W AS wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
		AND WSWin = 'Y'
		AND NOT yearid = 1981
ORDER BY wins
LIMIT 1;
-- Answer: 2006 SLN - 83

WITH sub_teams AS(
	SELECT
		yearid,
		wt.teamid AS winning_team,
		wt.W AS w_wins,
		MAX(teams.W) AS max_wins
	FROM teams
		INNER JOIN (
			SELECT *
			FROM teams
			WHERE yearid BETWEEN 1970 AND 2016
				AND WSWin = 'Y') AS wt USING (yearid)
	GROUP BY yearid, winning_team , w_wins
	HAVING wt.W >= MAX(teams.W)
)
SELECT ROUND(COUNT(*)::numeric / (2016 - 1970)::numeric, 3) AS percentage
FROM sub_teams;
-- Answer: 12 (12/46 = 26.1%)

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). 
-- Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
SELECT
	park_name,
	teams.name,
	ROUND(AVG(homegames_stats.attendance / games), 0) AS avg_attendance
FROM (
	SELECT *
	FROM homegames
	WHERE games >= 10) AS homegames_stats
	INNER JOIN parks USING (park)
	INNER JOIN teams ON teams.teamid = homegames_stats.team
		AND teams.yearid = homegames_stats.year
WHERE year = 2016
GROUP BY park_name, teams.name
ORDER BY avg_attendance DESC LIMIT 5;

SELECT
	park_name,
	teams.name,
	ROUND(AVG(homegames_stats.attendance / games), 0) AS avg_attendance
FROM (
	SELECT *
	FROM homegames
	WHERE games >= 10) AS homegames_stats
	INNER JOIN parks USING (park)
	INNER JOIN teams ON teams.teamid = homegames_stats.team
		AND teams.yearid = homegames_stats.year
WHERE year = 2016
GROUP BY park_name, teams.name
ORDER BY avg_attendance LIMIT 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
WITH award_winners AS (
	SELECT playerid,
		l_managers.yearid
	FROM awardsmanagers AS l_managers
		INNER JOIN people USING(playerid)
		FULL JOIN awardsmanagers AS r_managers USING(playerid)
	WHERE (l_managers.awardid LIKE 'TSN Manager of the Year' AND r_managers.awardid LIKE 'TSN Manager of the Year') AND
		((l_managers.lgid = 'NL' AND r_managers.lgid = 'AL') OR (l_managers.lgid = 'AL' AND r_managers.lgid = 'NL'))
	GROUP BY playerid, l_managers.yearid
)
SELECT DISTINCT
	namegiven,
	namelast,
	name
FROM people
	INNER JOIN award_winners USING (playerid)
	INNER JOIN managers USING (yearid, playerid)
	INNER JOIN teams USING (yearid, teamid)
ORDER BY namegiven;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
-- Report the players' first and last names and the number of home runs they hit in 2016.
WITH tenyear_players AS (
	SELECT playerid, COUNT(DISTINCT yearid)
	FROM appearances
	GROUP BY playerid
	HAVING COUNT(DISTINCT yearid) >= 10
),
career_stats AS (
	SELECT playerid, 
		MAX(season_hr) AS career_high
	FROM (
		SELECT playerid, yearid, SUM(hr) AS season_hr
		FROM batting
		GROUP BY playerid, yearid
		HAVING SUM(hr) >= 1
	)
	GROUP BY playerid
)
SELECT
	namegiven,
	namelast,
	SUM(hr) AS hr_2016
FROM batting
	INNER JOIN tenyear_players USING(playerid)
	INNER JOIN people USING(playerid)
	INNER JOIN career_stats USING(playerid)
WHERE yearid = 2016
GROUP BY playerid, namegiven, namelast, career_high
HAVING SUM(hr) = career_high
ORDER BY hr_2016 DESC;

-- OEQ-1: Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. 
-- As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- Comparing average salaries of teams by year with total wins
WITH team_salaries AS (
	SELECT
		yearid,
		teamid,
		ROUND(SUM(salary)::numeric, 0) AS team_salary
	FROM teams
		INNER JOIN salaries USING (yearid, teamid)
	GROUP BY yearid, teamid
)
/*SELECT
	yearid,
	teamid,
	w,
	avg_salary
FROM teams
	INNER JOIN team_salaries USING (yearid, teamid)
WHERE yearid >= 2000
ORDER BY yearid, avg_salary DESC;*/
/*SELECT
	yearid,
	CASE WHEN divwin = 'Y' OR wcwin = 'Y' THEN 'playoffs'
	ELSE 'eliminated' END AS playoff_result,
	ROUND(AVG(team_salary), 0) AS avg_salary
FROM teams
	INNER JOIN team_salaries USING (yearid, teamid)
WHERE yearid >= 2000
GROUP BY yearid, playoff_result;*/
SELECT
	yearid,
	teamid,
	r AS runs,
	team_salary
FROM teams
	INNER JOIN team_salaries USING (yearid, teamid)
WHERE yearid >= 2000;

-- OEQ-2: In this question, you will explore the connection between number of wins and attendance.
-- a. Does there appear to be any correlation between attendance at home games and number of wins?
-- b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
WITH team_salaries AS (
	SELECT
		yearid,
		teamid,
		ROUND(SUM(salary)::numeric, 0) AS team_salary
	FROM teams
		INNER JOIN salaries USING (yearid, teamid)
	GROUP BY yearid, teamid
)
SELECT yearid, teamid, w, attendance, team_salary
FROM teams
	INNER JOIN team_salaries USING (yearid, teamid);

WITH winning_years AS(
	SELECT yearid AS ws_year, 
		teamid, 
		attendance, 
		WSWin
	FROM teams
	WHERE wswin = 'Y' AND yearid >= 1985
)
SELECT yearid,
	teamid,
	teams.attendance,
	(yearid - ws_year) AS yrs_since_ws
FROM teams
	INNER JOIN winning_years USING (teamid)
WHERE (ws_year - yearid) < 5 AND (yearid - ws_year) < 5;

WITH playoff_years AS(
	SELECT yearid AS po_year,
		teamid,
		attendance,
		DivWin,
		WCWin
	FROM teams
	WHERE divwin = 'Y' OR wcwin = 'Y'
)
SELECT yearid,
	teamid,
	teams.attendance,
	po_year
FROM teams
	INNER JOIN playoff_years USING (teamid)
WHERE (po_year - yearid) < 5 AND (yearid - po_year) < 5;

-- OEQ-3: It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. 
-- First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
SELECT people.throws,
	ROUND(AVG(pitching.era::numeric), 3) AS avg_era,
	ROUND(AVG(((pitching.h + pitching.bb) / NULLIF(pitching.ipouts / 3.0, 0))::numeric), 3) AS avg_whip
FROM pitching
JOIN people
	ON people.playerid = pitching.playerid
WHERE people.throws IN ('L','R')
GROUP BY people.throws;
