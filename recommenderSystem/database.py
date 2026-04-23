import pandas as pd
import os
from sqlalchemy import create_engine, text


# Connection string za SQL Server

connection_string = os.getenv("DB_CONNECTION",
    "mssql+pyodbc://localhost/IB220199_Parking?driver=ODBC+Driver+17+for+SQL+Server&Trusted_Connection=yes"
)
engine = create_engine(connection_string)


def get_user_parking_history(user_id: str):
    query = text("""
        SELECT 
            t.Id,
            t.UserId,
            t.LicensePlate,
            t.EntryTime,
            t.ExitTime,
            t.TotalPrice,
            s.LotId,
            l.Name as LotName,
            l.RatePerMinute
        FROM ParkingTickets t
        JOIN ParkingSpots s ON t.SpotId = s.Id
        JOIN ParkingLots l ON s.LotId = l.Id
        WHERE t.UserId = :user_id
        AND t.Status IN (2, 4)
    """)

    with engine.connect() as conn:
        result = conn.execute(query, {"user_id": user_id})
        rows = result.fetchall()

    if not rows:
        return []

    return [
        {
            "lot_id": str(row.LotId),
            "lot_name": row.LotName,
            "entry_time": row.EntryTime,
            "exit_time": row.ExitTime,
            "total_price": float(row.TotalPrice) if row.TotalPrice else 0,
            "rate_per_minute": float(row.RatePerMinute),
            "duration_minutes": (
                (row.ExitTime - row.EntryTime).total_seconds() / 60
                if row.ExitTime else 0
            ),
            "hour_of_day": row.EntryTime.hour
        }
        for row in rows
    ]


def get_available_lots():
    query = text("""
        SELECT 
            l.Id,
            l.Name,
            l.RatePerMinute,
            l.TotalSpots,
            l.Type,
            COUNT(CASE WHEN s.Status = 0 THEN 1 END) as AvailableSpots
        FROM ParkingLots l
        JOIN ParkingSpots s ON l.Id = s.LotId
        WHERE l.IsActive = 1
        AND s.IsDeleted = 0
        GROUP BY l.Id, l.Name, l.RatePerMinute, l.TotalSpots, l.Type
    """)

    with engine.connect() as conn:
        result = conn.execute(query)
        rows = result.fetchall()

    return [
        {
            "lot_id": str(row.Id),
            "lot_name": row.Name,
            "rate_per_minute": float(row.RatePerMinute),
            "total_spots": row.TotalSpots,
            "available_spots": row.AvailableSpots,
            "type": row.Type,
            "occupancy_rate": (
                (row.TotalSpots - row.AvailableSpots) / row.TotalSpots
                if row.TotalSpots > 0 else 0
            )
        }
        for row in rows
    ]