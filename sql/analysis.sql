-- Delay rate by airline: what percentage of each carrier's flights arrived 15+ minutes late
SELECT a.airline_code, COUNT(*) AS total_flights, 
       SUM(CASE WHEN f.arr_del15 THEN 1 ELSE 0 END) AS delayed_flights,
       ROUND(100.0 * SUM(CASE WHEN f.arr_del15 THEN 1 ELSE 0 END) / COUNT(*), 2) AS delay_pct
FROM flights f
JOIN airlines a ON f.airline_code = a.airline_code
GROUP BY a.airline_code
ORDER BY delay_pct DESC;

-- Rolling 7-day average delay rate across all carriers, to smooth day-to-day noise
-- Note: first 6 days have a partial window since the dataset starts January 1
SELECT flight_date,
       COUNT(*) AS daily_flights,
       ROUND(100.0 * SUM(CASE WHEN arr_del15 THEN 1 ELSE 0 END) / COUNT(*), 2) AS daily_delay_pct,
       ROUND(AVG(100.0 * SUM(CASE WHEN arr_del15 THEN 1 ELSE 0 END) / COUNT(*)) OVER (
           ORDER BY flight_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ), 2) AS rolling_7day_avg
FROM flights
GROUP BY flight_date
ORDER BY flight_date;

-- Delay rate by origin airport, limited to airports with meaningful flight volume
SELECT ap.airport_code, COUNT(*) AS total_flights,
       ROUND(100.0 * SUM(CASE WHEN f.arr_del15 THEN 1 ELSE 0 END) / COUNT(*), 2) AS delay_pct
FROM flights f
JOIN airports ap ON f.origin_airport_id = ap.airport_id
GROUP BY ap.airport_code
HAVING COUNT(*) >= 1000
ORDER BY delay_pct DESC
LIMIT 15;

-- Joins flights with weather to test whether the January delay climb tracks with weather.
-- Finding: two distinct patterns emerge. Jan 9 shows a clear precipitation spike (0.887) 
-- aligning with a delay spike (41.48%). Jan 15-17 shows delays staying high (26-46%) while 
-- precipitation is low, but temperatures drop to near-freezing (31-33°F), suggesting 
-- cold-related delays (de-icing, ground ops) rather than rain-driven ones on those days.