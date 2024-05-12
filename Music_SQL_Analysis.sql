-- MUSIC STORE DATA ANALYSIS 

									/*SET 1 EASY QUESTIONS*/ 

-- 1) Who is the senior most employee based on job title?
select * from employee   -- first lets view the employee table
order by levels desc
limit 1;

-- 2) Which countries have the most Invoices?
select COUNT (*) as billing_count, billing_country 
from invoice
group by billing_country
order by billing_count desc;

-- 3) What are top 3 values of total invoice?
select total from invoice
order by total desc
limit 3;

-- 4) Which city has the best customers? We would like to throw a promotional Music Festival 
--in the city we made the most money. Write a query that returns one city that has the highest 
--sum of invoice totals. Return both the city name & sum of all invoice totals

select SUM(total) as invoice_total,billing_city 
from invoice
group by billing_city
order by invoice_total desc
limit 3;
-- hence, Prague has the maximum no. of customers purchasing the maximum no.of albums.


--5) Who is the best customer? The customer who has spent the most money will be declared the 
--best customer. Write a query that returns the person who has spent the most money
Select customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) as total
from customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total desc
Limit 1;


								  /*SET 2 MODERATE QUESTIONS*/

--1) Write query to return the email, first name, last name, & Genre of all Rock Music listeners.
--Return your list ordered alphabetically by email starting with A
Select DISTINCT email, first_name, last_name 
from customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id =invoice_line.invoice_id
WHERE track_id IN(
	Select track_id from track
	JOIN genre on track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;


--2) Let's invite the artists who have written the most rock music in our dataset. 
--Write a query that returns the Artist name and total track count of the top 10 rock bands.
Select artist.artist_id, artist.name, COUNT (artist.artist_id) AS number_of_songs
from track
JOIN album on album.album_id = track.album_id
JOIN artist on artist.artist_id = album.artist_id
JOIN genre on genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs desc
LIMIT 10;

-- 3) Return all the track names that have a song length longer than the average song length. 
--Return the Name and Milliseconds for each track. Order by the song length with the longest 
--songs listed first

select name, milliseconds from track
WHERE milliseconds >
( 
	SELECT AVG(milliseconds) as avg_track_length
	From track
)
ORDER BY milliseconds desc;


								/*SET 3 ADVANCE QUESTIONS*/
-- 1) Find how much amount spent by each customer on artists? Write a query to return customer 
--name, artist name and total spent.
WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name,
	SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 desc
	LIMIT 1
)
SELECT customer.customer_id, customer.first_name, customer.last_name, best_selling_artist.artist_name, 
	SUM(invoice_line.unit_price*invoice_line.quantity) AS amount_spent
FROM invoice
JOIN customer ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN best_selling_artist ON best_selling_artist.artist_id = album.artist_id
GROUP BY customer.customer_id,customer.first_name,customer.last_name,best_selling_artist.artist_name
ORDER BY 5 DESC;


--2) We want to find out the most popular music Genre for each country. We determine the most 
--popular genre as the genre with the highest amount of purchases. Write a query that returns 
--each country along with the top Genre. For countries where the maximum number of purchases is 
--shared return all Genres

WITH popular_genre AS 
(
	SELECT COUNT (invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id,
      ROW_NUMBER() OVER (PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity)DESC) 
	  AS Row_No
	FROM invoice_line
	JOIN invoice on invoice.invoice_id = invoice_line.invoice_id
	JOIN customer on customer.customer_id = invoice.customer_id
	JOIN track on track.track_id = invoice_line.track_id
	JOIN genre on genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
	)
SELECT * from popular_genre WHERE Row_No<=1;

--Method 2: Recursive method
WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


--3) Write a query that determines the customer that has spent the most on music for each country. 
--Write a query that returns the country along with the top customer and how much they spent. 
--For countries where the top amount spent is shared, provide all customers who spent this amount

WITH Customer_with_country AS (
	SELECT customer.customer_id,first_name,last_name,billing_country, SUM(total) AS amount_spent,
	ROW_NUMBER() OVER (PARTITION BY billing_country ORDER BY SUM(total) DESC) AS Row_no
	FROM invoice
	JOIN customer on customer.customer_id = invoice.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 4 ASC, 5 DESC
)
SELECT * FROM Customer_with_country WHERE Row_no<=1;

/* Method 2: Using Recursive */

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;




