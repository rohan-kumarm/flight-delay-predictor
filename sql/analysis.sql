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