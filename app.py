import streamlit as st
import pandas as pd
from sqlalchemy import create_engine

st.set_page_config(layout="wide")
st.title("Flight Delay Dashboard")
st.caption("January 2024 · Top 20 U.S. airports by flight volume")

engine = create_engine("postgresql+psycopg2://localhost/flight_delay_db")

# --- Rolling 7-day delay trend ---
st.header("Delay Trend Over January")

trend_query = """
SELECT flight_date,
       ROUND(100.0 * SUM(CASE WHEN arr_del15 THEN 1 ELSE 0 END) / COUNT(*), 2) AS daily_delay_pct,
       ROUND(AVG(100.0 * SUM(CASE WHEN arr_del15 THEN 1 ELSE 0 END) / COUNT(*)) OVER (
           ORDER BY flight_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ), 2) AS rolling_7day_avg
FROM flights
GROUP BY flight_date
ORDER BY flight_date
"""
trend_df = pd.read_sql(trend_query, engine)
trend_df = trend_df.set_index("flight_date")
st.line_chart(trend_df)

# --- Delay rate by airline ---
st.header("Delay Rate by Airline")

airline_query = """
SELECT a.airline_code,
       ROUND(100.0 * SUM(CASE WHEN f.arr_del15 THEN 1 ELSE 0 END) / COUNT(*), 2) AS delay_pct
FROM flights f
JOIN airlines a ON f.airline_code = a.airline_code
GROUP BY a.airline_code
ORDER BY delay_pct DESC
"""
airline_df = pd.read_sql(airline_query, engine)
airline_df = airline_df.set_index("airline_code")
st.bar_chart(airline_df)

# --- Weather vs delay (Jan 9 precipitation spike, Jan 15-17 cold spike) ---
st.header("Delay Rate vs. Weather Conditions")

weather_query = """
SELECT f.flight_date,
       ROUND(100.0 * SUM(CASE WHEN f.arr_del15 THEN 1 ELSE 0 END) / COUNT(*), 2) AS delay_pct,
       ROUND(AVG(w.precipitation), 3) AS avg_precip,
       ROUND(AVG(w.avg_temp), 1) AS avg_temp
FROM flights f
JOIN weather w ON f.origin_airport_id = w.airport_id AND f.flight_date = w.weather_date
GROUP BY f.flight_date
ORDER BY f.flight_date
"""
weather_df = pd.read_sql(weather_query, engine)
weather_df = weather_df.set_index("flight_date")
st.line_chart(weather_df[["delay_pct", "avg_temp"]])
st.bar_chart(weather_df["avg_precip"])