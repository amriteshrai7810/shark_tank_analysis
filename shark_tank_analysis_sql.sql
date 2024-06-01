-- Import the table to create the structure of the table 
SELECT * FROM sharktank;
TRUNCATE TABLE sharktank;

-- Change column name
ALTER TABLE sharktank
RENAME COLUMN `Namita_Investment_Amount_in lakhs` TO Namita_Investment_Amount_in_lakhs;

-- Paste the data in your show variables location
SHOW VARIABLES LIKE 'secure_file_priv';

--  Load the data using the infile command
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\sharktank.csv'
INTO TABLE sharktank
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Change -1 to 0 for calculations in Monthly and Yearly sales and revenue
UPDATE sharktank
SET Monthly_Sales_in_lakhs = 0
WHERE Monthly_Sales_in_lakhs = -1;

UPDATE sharktank
SET Yearly_Revenue_in_lakhs = 0
WHERE Yearly_Revenue_in_lakhs = -1;

SELECT * FROM sharktank;

-- 1 Query: You Team must promote shark Tank India season 4, The senior come up with the idea to show highest funding domain wise so that new startups can be attracted, and you were assigned the task to show the same.
SELECT 
	Industry, 
	MAX(Total_Deal_Amount_in_lakhs) AS total_amount
FROM sharktank
GROUP BY Industry
ORDER BY total_amount DESC;

-- 2 Query: You have been assigned the role of finding the domain where female as pitchers have female to male pitcher ratio > 70%
SELECT 
	Industry, 
    ROUND(SUM(Female_Presenters) / SUM(Male_Presenters), 2) female_ratio
FROM sharktank
GROUP BY Industry
HAVING female_ratio > 0.7;

-- 3 Query: You are working at marketing firm of Shark Tank India, you have got the task to determine volume of per season sale pitch made, pitches who received offer and pitches that were converted. 
-- 			Also show the percentage of pitches converted and percentage of pitches entertained.
SELECT 
    Season_Number, 
    COUNT(Pitch_Number) Num_Episodes,
    SUM(Received_Offer = "Yes") Received_Offer,
    ROUND(SUM(Received_Offer = "Yes") / COUNT(Pitch_Number), 2) Received_percent,
    SUM(Accepted_Offer = "Yes") Accepted_Offer,
    ROUND(SUM(Accepted_Offer = "Yes") / COUNT(Pitch_Number), 2) Accpeted_percent
FROM sharktank
GROUP BY Season_Number;

-- 4 Query: As a venture capital firm specializing in investing in startups featured on a renowned entrepreneurship TV show, you are determining the season with the highest average monthly sales 
-- 			and identify the top 5 industries with the highest average monthly sales during that season to optimize investment decisions?
SET @season = 
(SELECT Season_Number
FROM sharktank
GROUP BY Season_Number
ORDER BY AVG(Monthly_Sales_in_lakhs) DESC
LIMIT 1);

SELECT 
	Industry, 
	ROUND(AVG(Monthly_Sales_in_lakhs)) average 
FROM sharktank
WHERE Season_Number = @season
GROUP BY Industry
ORDER BY average DESC
LIMIT 5;

-- 5 Query: As a data scientist at our firm, your role involves solving real-world challenges like identifying industries with consistent increases in funds raised over multiple seasons. 
-- 			This requires focusing on industries where data is available across all three seasons. Once these industries are pinpointed, your task is to delve into the specifics, analyzing the number of pitches made, offers received, and offers converted per season within each industry.
WITH cte AS (
    SELECT 
        Industry, 
        SUM(IF(Season_Number = 1, total_deal_amount_in_lakhs, 0)) season_1,
        SUM(IF(Season_Number = 2, total_deal_amount_in_lakhs, 0)) season_2,
        SUM(IF(Season_Number = 3, total_deal_amount_in_lakhs, 0)) season_3
    FROM sharktank 
    GROUP BY industry 
    HAVING season_1 < season_2 AND season_2 < season_3 AND season_1 <> 0
)

SELECT
    Season_Number,
    Industry,
    COUNT(*) AS Total,
    SUM(Received_offer = "Yes") AS Received,
    SUM(Accepted_offer = "Yes") AS Accepted
FROM sharktank
WHERE Industry IN (SELECT Industry FROM cte)
GROUP BY Season_Number, Industry
ORDER BY Industry, Season_Number, Total;

-- 6 Query: Every shark wants to know in how much year their investment will be returned, so you must create a system for them, where shark will enter the name of the startup’s and the based on the total deal 
-- 			and equity given in how many years their principal amount will be returned and make their investment decisions.
DELIMITER //
CREATE PROCEDURE `tat`(IN startup VARCHAR(100))
BEGIN
	CASE
    WHEN (SELECT accepted_offer = "No" FROM sharktank WHERE startup_name = startup)
    THEN SELECT "TAT cannot be calculated! 1";
    WHEN (SELECT accepted_offer = "Yes" AND Yearly_Revenue_in_lakhs = 0 FROM sharktank WHERE startup_name = startup)
	THEN SELECT "TAT cannot be calculated! 2";
    ELSE
		SELECT startup_name, `Yearly_Revenue_in_lakhs`, `Total_Deal_Amount_in_lakhs`, `Total_Deal_Equity_%`,
        `Total_Deal_Amount_in_lakhs` / ((`Total_Deal_Equity_%` / 100) * `Yearly_Revenue_in_lakhs`) turnaround_time FROM sharktank
        WHERE startup_name = startup;
        END CASE;
END
DELIMITER ;

-- 7 Query: In the world of startup investing, we're curious to know which big-name investor, often referred to as "sharks," tends to put the most money into each deal on average. 
-- 			This comparison helps us see who's the most generous with their investments and how they measure up against their fellow investors.

SELECT sharkname, ROUND(AVG(investment),2)  AS 'average' from
(
SELECT Namita_Investment_Amount_in_lakhs AS Investment, 'Namita' AS sharkname FROM sharktank WHERE Namita_Investment_Amount_in_lakhs > 0
UNION ALL
SELECT Vineeta_Investment_Amount_in_lakhs AS Investment, 'Vineeta' AS sharkname FROM sharktank WHERE Vineeta_Investment_Amount_in_lakhs > 0
UNION ALL
SELECT Anupam_Investment_Amount_in_lakhs AS Investment, 'Anupam' AS sharkname FROM sharktank WHERE Anupam_Investment_Amount_in_lakhs > 0
UNION ALL
SELECT Aman_Investment_Amount_in_lakhs AS Investment, 'Aman' AS sharkname FROM sharktank WHERE Aman_Investment_Amount_in_lakhs > 0
UNION ALL
SELECT Peyush_Investment_Amount__in_lakhs AS Investment, 'peyush' AS sharkname FROM sharktank WHERE Peyush_Investment_Amount__in_lakhs > 0
UNION ALL
SELECT Amit_Investment_Amount_in_lakhs AS Investment, 'Amit' AS sharkname FROM sharktank WHERE Amit_Investment_Amount_in_lakhs > 0
UNION ALL
SELECT Ashneer_Investment_Amount AS Investment, 'Ashneer' AS sharkname FROM sharktank WHERE Ashneer_Investment_Amount > 0
) table1 
GROUP BY sharkname
ORDER BY average DESC;

-- 8 Query: Develop a stored procedure that accepts inputs for the season number and the name of a shark. The procedure will then provide detailed insights into the 
-- 			total investment made by that specific shark across different industries during the specified season. Additionally, it will calculate the percentage of their investment in each sector relative to the total investment in that year, giving a comprehensive understanding of the shark's investment distribution and impact.
DELIMITER //
CREATE PROCEDURE `season_info`(IN season INT, IN sharkname VARCHAR(100))
BEGIN
	CASE
		WHEN sharkname = "Namita" THEN
        SET @total = (SELECT SUM(Namita_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number = season AND Namita_Investment_Amount_in_lakhs > 0);
		SELECT Industry, SUM(Namita_Investment_Amount_in_lakhs) sums, ROUND((SUM(Namita_Investment_Amount_in_lakhs) / @total) * 100) AS 'percent' FROM sharktank WHERE Season_Number = season AND Namita_Investment_Amount_in_lakhs > 0
			GROUP BY Industry;
		
		WHEN sharkname = "Vineeta" THEN
        SET @total = (SELECT SUM(Vineeta_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number = season AND Vineeta_Investment_Amount_in_lakhs > 0);
		SELECT Industry, SUM(Vineeta_Investment_Amount_in_lakhs) sums, ROUND((SUM(Vineeta_Investment_Amount_in_lakhs) / @total) * 100) AS 'percent' FROM sharktank WHERE Season_Number = season AND Vineeta_Investment_Amount_in_lakhs > 0
			GROUP BY Industry;
		
		WHEN sharkname = "Anupam" THEN
        SET @total = (SELECT SUM(Anupam_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number = season AND Anupam_Investment_Amount_in_lakhs > 0);
		SELECT Industry, SUM(Anupam_Investment_Amount_in_lakhs) sums, ROUND((SUM(Anupam_Investment_Amount_in_lakhs) / @total) * 100) AS 'percent' FROM sharktank WHERE Season_Number = season AND Anupam_Investment_Amount_in_lakhs > 0
			GROUP BY Industry;
		
		WHEN sharkname = "Peyush" THEN
        SET @total = (SELECT SUM(Peyush_Investment_Amount__in_lakhs) FROM sharktank WHERE Season_Number = season AND Peyush_Investment_Amount__in_lakhs > 0);
		SELECT Industry, SUM(Peyush_Investment_Amount__in_lakhs) sums, ROUND((SUM(Peyush_Investment_Amount__in_lakhs) / @total) * 100) AS 'percent' FROM sharktank WHERE Season_Number = season AND Peyush_Investment_Amount__in_lakhs > 0
			GROUP BY Industry;
		
		WHEN sharkname = "Aman" THEN
        SET @total = (SELECT SUM(Aman_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number = season AND Aman_Investment_Amount_in_lakhs > 0);
		SELECT Industry, SUM(Aman_Investment_Amount_in_lakhs) sums, ROUND((SUM(Aman_Investment_Amount_in_lakhs) / @total) * 100) AS 'percent' FROM sharktank WHERE Season_Number = season AND Aman_Investment_Amount_in_lakhs > 0
			GROUP BY Industry;
		
		WHEN sharkname = "Ashneer" THEN
        SET @total = (SELECT SUM(Ashneer_Investment_Amount) FROM sharktank WHERE Season_Number = season AND Ashneer_Investment_Amount > 0);
		SELECT Industry, SUM(Ashneer_Investment_Amount) sums, ROUND((SUM(Ashneer_Investment_Amount) / @total) * 100) AS 'percent' FROM sharktank WHERE Season_Number = season AND Ashneer_Investment_Amount > 0
			GROUP BY Industry;
		
		WHEN sharkname = "Amit" THEN
		SET @total = (SELECT SUM(Amit_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number = season AND Amit_Investment_Amount_in_lakhs > 0);
		SELECT Industry, SUM(Amit_Investment_Amount_in_lakhs) AS sums, ROUND((SUM(Amit_Investment_Amount_in_lakhs) / @total) * 100) AS 'percent'  FROM sharktank WHERE Season_Number = season AND Amit_Investment_Amount_in_lakhs > 0
			GROUP BY Industry;
			
		ELSE
		SELECT "Enter a valid Input";
		
    END CASE;
    
END
DELIMITER ; 

call season_info(1, "Ashneer");

-- Query 9: In the realm of venture capital, we're exploring which shark possesses the most diversified investment portfolio across various industries. 
-- 			By examining their investment patterns and preferences, we aim to uncover any discernible trends or strategies that may shed light on their decision-making processes and investment philosophies.
SELECT 
    sharkname, 
    COUNT(DISTINCT industry) AS Unique_Industry,
    COUNT(DISTINCT CONCAT(pitchers_city, ', ', pitchers_state)) AS unique_locations
FROM (
    SELECT Industry, Pitchers_City, Pitchers_State, 'Namita' AS sharkname
    FROM sharktank WHERE Namita_Investment_Amount_in_lakhs > 0

    UNION ALL

    SELECT Industry, Pitchers_City, Pitchers_State, 'Vineeta' AS sharkname
    FROM sharktank WHERE Vineeta_Investment_Amount_in_lakhs > 0

    UNION ALL

    SELECT Industry, Pitchers_City, Pitchers_State, 'Anupam' AS sharkname
    FROM sharktank WHERE Anupam_Investment_Amount_in_lakhs > 0

    UNION ALL

    SELECT Industry, Pitchers_City, Pitchers_State, 'Aman' AS sharkname
    FROM sharktank WHERE Aman_Investment_Amount_in_lakhs > 0

    UNION ALL

    SELECT Industry, Pitchers_City, Pitchers_State, 'Peyush' AS sharkname
    FROM sharktank WHERE Peyush_Investment_Amount__in_lakhs > 0

    UNION ALL

    SELECT Industry, Pitchers_City, Pitchers_State, 'Amit' AS sharkname
    FROM sharktank WHERE Amit_Investment_Amount_in_lakhs > 0

    UNION ALL

    SELECT Industry, Pitchers_City, Pitchers_State, 'Ashneer' AS sharkname
    FROM sharktank WHERE Ashneer_Investment_Amount > 0
) AS table1
GROUP BY sharkname 
ORDER BY Unique_Industry DESC, Unique_Locations DESC;


