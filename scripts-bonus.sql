--[1] In this question, you'll get to practice correlated subqueries and learn about the LATERAL keyword. Note: This could be done using window functions, but we'll do it in a different way in order to revisit correlated subqueries and see another keyword - LATERAL.
--a. First, write a query utilizing a correlated subquery to find the team with the most wins from each league in 2016.

--If you need a hint, you can structure your query as follows:
--SELECT DISTINCT lgid, ( <Write a correlated subquery here that will pull the teamid for the team with the highest number of wins from each league> )
--FROM teams t
--WHERE yearid = 2016;

SELECT DISTINCT lgid,
	(SELECT teamid
	FROM teams
	WHERE lgid = t.lgid AND yearid = 2016
	ORDER BY w DESC
	LIMIT 1)
FROM teams t
WHERE yearid = 2016;

--b. One downside to using correlated subqueries is that you can only return exactly one row and one column. This means, for example that if we wanted to pull in not just the teamid but also the number of wins, we couldn't do so using just a single subquery. (Try it and see the error you get). 
-- Add another correlated subquery to your query on the previous part so that your result shows not just the teamid but also the number of wins by that team.
SELECT DISTINCT lgid,
	(SELECT teamid
	FROM teams
	WHERE lgid = t.lgid AND yearid = 2016
	ORDER BY w DESC
	LIMIT 1),
	(SELECT w
	FROM teams
	WHERE lgid = t.lgid AND yearid = 2016
	ORDER BY w DESC
	LIMIT 1)
FROM teams t
WHERE yearid = 2016;

--c. If you are interested in pulling in the top (or bottom) values by group, you can also use the DISTINCT ON expression (https://www.postgresql.org/docs/9.5/sql-select.html#SQL-DISTINCT). Rewrite your previous query into one which uses DISTINCT ON to return the top team by league in terms of number of wins in 2016. Your query should return the league, the teamid, and the number of wins.
SELECT DISTINCT ON (lgid) lgid, teamid, w
FROM teams
WHERE yearid = 2016
ORDER BY lgid, w DESC;

--d. If we want to pull in more than one column in our correlated subquery, another way to do it is to make use of the LATERAL keyword (https://www.postgresql.org/docs/9.4/queries-table-expressions.html#QUERIES-LATERAL). This allows you to write subqueries in FROM that make reference to columns from previous FROM items. This gives us the flexibility to pull in or calculate multiple columns or multiple rows (or both). Rewrite your previous query using the LATERAL keyword so that your result shows the teamid and number of wins for the team with the most wins from each league in 2016. 

--If you want a hint, you can structure your query as follows:
--SELECT *
--FROM (SELECT DISTINCT lgid 
--	  FROM teams
--	  WHERE yearid = 2016) AS leagues,
--	  LATERAL ( <Fill in a subquery here to retrieve the teamid and number of wins> ) as top_teams;
	  
--e. Finally, another advantage of the LATERAL keyword over using correlated subqueries is that you return multiple result rows. (Try to return more than one row in your correlated subquery from above and see what type of error you get). Rewrite your query on the previous problem sot that it returns the top 3 teams from each league in term of number of wins. Show the teamid and number of wins.

/*[2] Another advantage of lateral joins is for when you create calculated columns. In a regular query, when you create a calculated column, you cannot refer it it when you create other calculated columns. This is particularly useful if you want to reuse a calculated column multiple times. For example,
SELECT 
	teamid,
	w,
	l,
	w + l AS total_games,
	w*100.0 / total_games AS winning_pct
FROM teams
WHERE yearid = 2016
ORDER BY winning_pct DESC;

results in the error that "total_games" does not exist. However, I can restructure this query using the LATERAL keyword.

SELECT
	teamid,
	w,
	l,
	total_games,
	w*100.0 / total_games AS winning_pct
FROM teams t,
LATERAL (
	SELECT w + l AS total_games
) AS tg
WHERE yearid = 2016
ORDER BY winning_pct DESC;*/

--a. Write a query which, for each player in the player table, assembles their birthyear, birthmonth, and birthday into a single column called birthdate which is of the date type.

--b. Use your previous result inside a subquery using LATERAL to calculate for each player their age at debut and age at retirement. (Hint: It might be useful to check out the PostgreSQL date and time functions https://www.postgresql.org/docs/8.4/functions-datetime.html).

--c. Who is the youngest player to ever play in the major leagues?

--d. Who is the oldest player to player in the major leagues? You'll likely have a lot of null values resulting in your age at retirement calculation. Check out the documentation on sorting rows here https://www.postgresql.org/docs/8.3/queries-order.html about how you can change how null values are sorted.