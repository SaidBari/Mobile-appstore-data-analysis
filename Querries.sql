/*
**THE PROBLEM WE ARE TRYING TO SOLVE**
Problem:
Developers and stakeholders in the mobile app industry face challenges in understanding factors 
that contribute to the success or failure of an app. This includes making decisions on pricing strategies,
languages, the impact of app descriptions, and identifying opportunities in less competitive genres.

GOAL:
This analysis aims to provide actionable insights for app developers and stakeholders,
helping them make informed decisions regarding app development, marketing,
and strategy in a highly competitive mobile app market.
*/
/*
**DATASET CONTENT DESCRIPTION**

- appleStore.csv

"id" : App ID
"track_name": App Name
"size_bytes": Size (in Bytes)
"currency": Currency Type
"price": Price amount
"rating_count_tot": User Rating counts (for all version)
"rating_count_ver": User Rating counts (for current version)
"user_rating" : Average User Rating value (for all version)
"user_rating_ver": Average User Rating value (for current version)
"ver" : Latest version code
"cont_rating": Content Rating
"prime_genre": Primary Genre
"sup_devices.num": Number of supporting devices
"ipadSc_urls.num": Number of screenshots showed for display
"lang.num": Number of supported languages
"vpp_lic": Vpp Device Based Licensing Enabled 

- appleStore_description.csv

"id" : App ID
"track_name": Application name
"size_bytes": Memory size (in Bytes)
"app_desc": Application description
DATASET SOURCE : https://www.kaggle.com/datasets/ramamet4/app-store-apple-data-set-10k-apps
*/

/*COMBINING THE DESCRIPTION TABLES INTO ONE TABLE*/

CREATE TABLE appleStore_description_combined AS
SELECT*From appleStore_description1
UNION ALL 
SELECT*From appleStore_description2
UNION ALL 
SELECT*From appleStore_description3
UNION ALL 
SELECT*From appleStore_description4

/*EXPLORATORY DATA ANALYSIS*/
-- checking the count of unique apps in both tables to unsure the inexistence of missing data

SELECT COUNT(DISTINCT id) as apps_countt1
FROM AppleStore
/* result : apps_countt1 7197 */

SELECT COUNT(DISTINCT id) as apps_countt2
FROM appleStore_description_combined
/* result : apps_countt2 7197 */

checking for any missing values in key fields 

--for AppleStore table:
SELECT count(*) as missing_values
FROM AppleStore 
where track_name ISNULL or price ISNULL or user_rating ISNULL or prime_genre ISNULL or lang_num ISNULL or sup_devices_num is NULL or size_bytes ISNULL
--result : 0 missing_values

--for appleStore_description_combined table:

SELECT COUNT(*) as missing_value
FROM appleStore_description_combined
where track_name ISNULL or app_desc ISNULL
--result : 0 missing_values

--APPS COUNT PER GENRE (to get an idea on the competition in each genre)
SELECT prime_genre,count(DISTINCT id) as apps_count FROM AppleStore
GROUP BY prime_genre
ORDER BY apps_count DESC
/* result: Games 3862, Entertainment 535, Education 453, .......... , Business 57, Navigation 46, Medical 23, Catalogs 10
The genre distribution provides insights into the app market composition.
The dominance of certain genres, such as Games and Entertainment, suggests a high level of competition,
while less populated genres may present niche opportunities.
*/

--OVERVIEW OF THE USER_RATING :

SELECT Min(user_rating) as min_rating,
               Max(user_rating) as max_rating,
               avg(user_rating) as avg_rating
from AppleStore
--results: min_rating 0, max_rating 5, avg_rating 3,52
SELECT
  (
    (SELECT MAX(user_rating) FROM (SELECT user_rating FROM AppleStore ORDER BY user_rating LIMIT (SELECT COUNT(*) FROM AppleStore) / 2) AS A)
    +
    (SELECT MIN(user_rating) FROM (SELECT user_rating FROM AppleStore ORDER BY user_rating DESC LIMIT (SELECT COUNT(*) FROM AppleStore) / 2) AS B)
  ) / 2 AS median,


--results: median 4 ( the median might better represent the "typical" positive user experience compared to the average,
--which could be influenced by a few lower ratings such as apps rated 0 )

** DATA ANALYSIS ** 
-- APP PRICE OVERVIEW :
SELECT case 
               when price > 0 then 'paid'
               when price = 0 then 'free'
               end as app_type,
               avg(user_rating) as avg_rating
from AppleStore
group by app_type
/*
results: avg_rating of free apps = 3.37 and avg_rating for paid apps = 3.72 , this indicates that paid apps receive higher average ratings,
however we have to explore additional factors to avoid any missinterpretation.
*/

--IMPACT OF SUPPORTED LANGUAGES COUNT ON APP RATING:
SELECT CASE
When lang_num < 10 then '< 10'
when lang_num BETWEEN 10 and 15 tHEN '10-15'
when lang_num BETWEEN 15 and 30 THEN '15-30'
when lang_num > 30 then '> 30'
end as lang_segment,
avg(user_rating) as avg_rating
from AppleStore
group by lang_segment
ORDER by avg_rating

/*
Result: 
lang_segment	avg_rating
"< 10"	               "3.368327402135231"
"> 30"	               "3.7777777777777777"
"15-30"	              "4.052254098360656"
"10-15"	              "4.172113289760349"

Concluding that a range of 10-15 supported languages is the best to aim at while creating an app,
starting from the most popular language to the least popular.
*/

--IMPACT OF APP SCREEN SHOTS ON APP RATING:
SELECT CASE
When ipadsc_urls_num = 0 then '0'
when ipadsc_urls_num BETWEEN 1 and 3 tHEN '1-3'
when ipadsc_urls_num = 4 THEN '4'
when ipadsc_urls_num = 5 THEN '5'
end as screenshots_count,
avg(user_rating) as avg_rating
from AppleStore
group by screenshots_count
ORDER by avg_rating
/* 
Result:
screenshots_count	avg_rating
"0"	                            "2.785147801009373"
"1-3"	                       "3.1867671691792294"
"4"	                            "3.4408450704225353"
"5"	                            "3.814123917388408"

5 screenshots would be the optimal number of screenshots to showcase an app, it probably is the maximum seeing 
that the dataset doesn't have a higher value of 5 in screenshot count.
*/

--DEFINING GENRES WITH LOW RATING (to spot opportunities)
SELECT prime_genre, avg(user_rating) as avg_rating, count(DISTINCT id) as Competitor_count FROM AppleStore
GROUP BY prime_genre
ORDER BY avg_rating asc
/*
Result:
prime_genre	           avg_rating	          Competitor_count
"Catalogs"	"2.1"	"10"
"Finance"	"2.4326923076923075"	"104"
"Book"	"2.4776785714285716"	"112"
"Navigation"	"2.6847826086956523"	"46"
.. 
.. 
..
"Photo & Video"	"3.8008595988538683"	"349"
"Music"	"3.9782608695652173"	"138"
"Productivity"	"4.00561797752809"	"178"

Identifying genres with lower average ratings reveals potential opportunities for developers
to explore less competitive niches where there may be room for improvement and innovation.
*/

--IMPACT OF DESCRIPTION LENGTH ON USER RATING:
--checking max and min description lengths:
Select max(length(app_desc)) as maxlength , min(length(app_desc))as minlength from appleStore_description_combined
/* Result:
maxlength 4000	minlength 6
*/
--Chekking the distribution:
Select CASE
When length(D.app_desc)<500 then 'short'
when length(D.app_desc) between 500 and 1500 then 'lowermedium'
when length(D.app_desc) between 1501 and 2500 then 'medium'
when length(D.app_desc) between 2501 and 3500 then 'uppermedium'
else  'long'
end as desc_length,
avg(A.user_rating) as avg_rating
from appleStore_description_combined as D
join AppleStore as A
on A.id=D.id
group by desc_length
Order by Avg_rating Desc
/* Result:
desc_length	          avg_rating
"long"	                   "4.0131578947368425"  
"medium"	          "3.9146216768916156"
"uppermedium"	 "3.911730545876887"
"lowermedium"	  "3.4402383456011214"
"short"                 	"2.533613445378151"

We see that app with descriptions of over 3500 letter has the highest rating, followed by apps with 1500-3500 letters descriptions.
Going for a 1500 to 4000 letter would be the wisest decision based on the data.
*/

-- TOP APPS	 IN EACH GENRE:
/* Analyzing the top three apps in each genre could allow new developers to benchmark
against successful apps and understand common traits among top performers in various categories.*/

SELECT prime_genre, track_name, user_rating 
from (
            SELECT
            prime_genre,
            track_name,
            user_rating ,
            RANK() OVER(PARTITION by prime_genre ORDER BY user_rating DESC, rating_count_tot DESC) as rank
            from AppleStore
            ) as A
WHERE A.rank BETWEEN 1 and 3 
/* Result:
prime_genre	    track_name	   user_rating
"Book"	"Color Therapy Adult Coloring Book for Adults"	"5"
"Book"	"喜马拉雅FM（听书社区）电台有声小说相声英语"	"5"
"Book"	"快看漫画"	"5"
"Business"	"TurboScan™ Pro - document & receipt scanner: scan multiple pages and photos to PDF"	"5"
"Business"	"Tiny Scanner+ - PDF scanner to scan document, receipt & fax"	"5"
"Business"	"VPN Go - Safe Fast & Stable VPN Proxy"	"5"
"Catalogs"	"CPlus for Craigslist app - mobile classifieds"	"5"
"Catalogs"	"My Movies Pro - Movie & TV Collection Library"	"4.5"
"Catalogs"	"DRAGONS MODS FREE for Minecraft PC Game Edition"	"4"
"Education"	"Elevate - Brain Training and Games"	"5"
"Education"	"Memrise: learn languages"	"5"
"Education"	"Endless Alphabet"	"5"
"Entertainment"	"Bruh-Button"	"5"
"Entertainment"	"Pixel Color Ball Fell From The Sky"	"5"
"Entertainment"	"Atom – Movie Tickets and Showtimes"	"5"
"Finance"	"Credit Karma: Free Credit Scores, Reports & Alerts"	"5"
"Finance"	"家計簿マネーフォワード-自動連携で簡単 人気の家計簿"	"5"
"Finance"	"楽天カード"	"5"
"Food & Drink"	"Domino's Pizza USA"	"5"
"Food & Drink"	"Caveman Feast - 250 Paleo Recipes"	"5"
"Food & Drink"	"Fit Men Cook - Healthy Recipes"	"5"
"Games"	"Head Soccer"	"5"
"Games"	"Plants vs. Zombies"	"5"
"Games"	"Sniper 3D Assassin: Shoot to Kill Gun Game"	"5"
"Health & Fitness"	"Yoga Studio"	"5"
"Health & Fitness"	"Sworkit - Custom Workouts for Exercise & Fitness"	"5"
"Health & Fitness"	"Headspace"	"5"
"Lifestyle"	"ipsy - Makeup, subscription and beauty tips"	"5"
"Lifestyle"	"Five Minute Journal"	"5"
"Lifestyle"	"Louvre HD"	"5"
"Medical"	"Blink Health"	"5"
"Medical"	"Eye Training Cocololo-3dステレオグラム視力回復アプリ-"	"5"
"Medical"	"Baby Connect (Activity Log)"	"4.5"
"Music"	"Tenuto"	"5"
"Music"	"Patterning : Drum Machine"	"5"
"Music"	"Model 15"	"5"
"Navigation"	"parkOmator – for Apple Watch meter expiration timer, notifications & GPS navigator to car location"	"5"
"Navigation"	"Waze - GPS Navigation, Maps & Real-time Traffic"	"4.5"
"Navigation"	"Google Maps - Navigation & Transit"	"4.5"
"News"	"The Guardian"	"5"
"News"	"PS Deals+ - Games Price Alerts for PS4, PS3, Vita"	"5"
"News"	"Reddit Official App: All That's Trending and Viral"	"4.5"
"Photo & Video"	"Pic Collage - Picture Editor & Photo Collage Maker"	"5"
"Photo & Video"	"Google Photos - unlimited photo and video storage"	"5"
"Photo & Video"	"FotoRus -Camera & Photo Editor & Pic Collage Maker"	"5"
"Productivity"	"VPN Proxy Master - Unlimited WiFi security VPN"	"5"
"Productivity"	"CARROT To-Do - Talking Task List"	"5"
"Productivity"	"Rocket Video for Google Cast and Chromecast to TV"	"5"
"Reference"	"Sky Guide: View Stars Night or Day"	"5"
"Reference"	"e-Sword HD: Bible Study Made Easy"	"5"
"Reference"	"Knots 3D"	"5"
"Shopping"	"Zappos: shop shoes & clothes, fast free shipping"	"5"
"Shopping"	"Shopular Coupons, Weekly Deals for Target, Walmart"	"5"
"Shopping"	"Ebates: Cash Back, Coupons & Rebate Shopping App"	"5"
"Social Networking"	"We Heart It - Fashion, wallpapers, quotes, tattoos"	"5"
"Social Networking"	"CTFxCmoji"	"5"
"Social Networking"	"ひみつの出会い探しはバクアイ-無料の出会いチャットアプリで友達作り"	"5"
"Sports"	"J23 - Jordan Release Dates and History"	"5"
"Sports"	"GameDay Pro Football Radio - Live Games, Scores, Highlights, News, Stats, and Schedules"	"5"
"Sports"	"Boston GameDay Radio for Live New England Sports, News, and Music – Patriots and Celtics Edition"	"5"
"Travel"	"Urlaubspiraten"	"5"
"Travel"	"机票、火车票、汽车票预定助手 for 铁路12306"	"5"
"Travel"	"火车票Pro for 12306"	"5"
"Utilities"	"Flashlight Ⓞ"	"5"
"Utilities"	"Browser and File Manager for Documents"	"5"
"Utilities"	"Evolution Calculator - CP & XP - for Pokemon GO!"	"5"
"Weather"	"NOAA Hi-Def Radar Pro -  Storm Warnings, Hurricane Tracker & Weather Forecast"	"5"
"Weather"	"Deluxe Moon Pro - Moon Phases Calendar"	"5"
"Weather"	"MyRadar NOAA Weather Radar Forecast"	"4.5"
*/
