import pandas as pd
from sklearn.preprocessing import MinMaxScaler
from datetime import datetime
import math


def get_recommendations(history: list, available_lots: list, lat: float = None, lng: float = None):
    # Cold start — nema historije
    if not history:
        return get_default_recommendations(available_lots, lat, lng)

    # Pretvori u DataFrame
    history_df = pd.DataFrame(history)

    # Izračunaj korisnikove preferencije po lotu
    user_preferences = history_df.groupby("lot_id").agg(
        visit_count=("lot_id", "count"),
        avg_price=("total_price", "mean"),
        avg_duration=("duration_minutes", "mean"),
        preferred_hour=("hour_of_day", "mean")
    ).reset_index()

    # Normalizuj visit_count
    scaler = MinMaxScaler()
    user_preferences["visit_score"] = scaler.fit_transform(
        user_preferences[["visit_count"]]
    )

    # Normalizuj avg_price (manji avg_price = korisnik preferira jeftinije)
    if user_preferences["avg_price"].max() > 0:
        user_preferences["price_preference_score"] = 1 - scaler.fit_transform(
            user_preferences[["avg_price"]]
        )
    else:
        user_preferences["price_preference_score"] = 0.5

    # Trenutni sat
    current_hour = datetime.now().hour

    # Izračunaj score za svaki dostupni lot
    recommendations = []
    for lot in available_lots:
        if lot["available_spots"] == 0:
            continue

        score = calculate_score(lot, user_preferences, current_hour, lat, lng)
        reason = get_reason(lot, user_preferences, current_hour, lat, lng)

        recommendations.append({
            "lot_id": lot["lot_id"],
            "lot_name": lot["lot_name"],
            "rate_per_minute": lot["rate_per_minute"],
            "available_spots": lot["available_spots"],
            "total_spots": lot["total_spots"],
            "occupancy_rate": round(lot["occupancy_rate"] * 100, 1),
            "score": round(score, 3),
            "reason": reason,
            "type": lot["type"],
        })

    recommendations.sort(key=lambda x: x["score"], reverse=True)
    return recommendations


def calculate_score(lot: dict, user_preferences: pd.DataFrame, current_hour: int, lat: float = None, lng: float = None):
    score = 0.0

    # 1. Historija posjeta (40% težina)
    user_lot = user_preferences[user_preferences["lot_id"] == lot["lot_id"]]
    if not user_lot.empty:
        score += user_lot.iloc[0]["visit_score"] * 0.40

        # 2. Podudaranje sata (15% težina)
        preferred_hour = user_lot.iloc[0]["preferred_hour"]
        hour_diff = abs(current_hour - preferred_hour)
        hour_score = max(0, 1 - (hour_diff / 12))
        score += hour_score * 0.15

        # 3. Preferencija cijene iz historije (10% težina)
        price_pref = user_lot.iloc[0]["price_preference_score"]
        score += price_pref * 0.10

    # 4. Dostupnost spotova (20% težina)
    availability_score = lot["available_spots"] / lot["total_spots"]
    score += availability_score * 0.20

    # 5. Trenutna cijena lota (10% težina)
    max_rate = 1.0
    price_score = max(0, 1 - (lot["rate_per_minute"] / max_rate))
    score += price_score * 0.10

    # 6. Blizina korisnika (5% težina) — koristi lat/lng ako su dostupni
    if lat is not None and lng is not None and "lat" in lot and "lng" in lot:
        distance_km = haversine(lat, lng, lot["lat"], lot["lng"])
        # Manji distance = veći score, max korisna distanca = 10km
        proximity_score = max(0, 1 - (distance_km / 10))
        score += proximity_score * 0.05

    return score


def get_reason(lot: dict, user_preferences: pd.DataFrame, current_hour: int, lat: float = None, lng: float = None) -> str:
    user_lot = user_preferences[user_preferences["lot_id"] == lot["lot_id"]]
    reasons = []

    if not user_lot.empty:
        visits = int(user_lot.iloc[0]["visit_count"])
        preferred_hour = user_lot.iloc[0]["preferred_hour"]
        avg_duration = user_lot.iloc[0]["avg_duration"]
        avg_price = user_lot.iloc[0]["avg_price"]

        reasons.append(f"You've parked here {visits} time(s) before")

        hour_diff = abs(current_hour - preferred_hour)
        if hour_diff <= 2:
            reasons.append(f"matches your usual parking time (~{int(preferred_hour)}h)")

        if avg_duration > 0:
            reasons.append(f"avg stay {int(avg_duration)} min")

        if avg_price > 0:
            reasons.append(f"avg cost {avg_price:.2f} KM")

    # Dostupnost
    occupancy = lot["occupancy_rate"]
    if occupancy < 0.3:
        reasons.append("high availability")
    elif occupancy < 0.6:
        reasons.append("good availability")

    # Blizina
    if lat is not None and lng is not None and "lat" in lot and "lng" in lot:
        distance_km = haversine(lat, lng, lot["lat"], lot["lng"])
        if distance_km < 1.0:
            reasons.append(f"{int(distance_km * 1000)}m away")
        else:
            reasons.append(f"{distance_km:.1f}km away")

    return " | ".join(reasons) if reasons else "Available parking"


def haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Izračunaj distancu između dvije koordinate u kilometrima."""
    R = 6371  # Zemlja radijus u km
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = math.sin(d_lat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lng / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def get_default_recommendations(available_lots: list, lat: float = None, lng: float = None) -> list:
    """Cold start — sortiraj po dostupnosti i blizini ako su koordinate dostupne."""
    filtered = [l for l in available_lots if l["available_spots"] > 0]

    if lat is not None and lng is not None:
        # Sortiraj po kombinaciji dostupnosti i blizine
        for lot in filtered:
            if "lat" in lot and "lng" in lot:
                distance_km = haversine(lat, lng, lot["lat"], lot["lng"])
                proximity_score = max(0, 1 - (distance_km / 10))
                availability_score = lot["available_spots"] / lot["total_spots"]
                lot["_cold_score"] = (availability_score * 0.6) + (proximity_score * 0.4)
                lot["_distance"] = distance_km
            else:
                lot["_cold_score"] = lot["available_spots"] / lot["total_spots"]
                lot["_distance"] = None

        filtered.sort(key=lambda x: x["_cold_score"], reverse=True)
    else:
        filtered.sort(key=lambda x: x["available_spots"], reverse=True)

    result = []
    for lot in filtered:
        distance = lot.get("_distance")
        if distance is not None:
            if distance < 1.0:
                reason = f"Most available spots | {int(distance * 1000)}m away"
            else:
                reason = f"Most available spots | {distance:.1f}km away"
        else:
            reason = "Most available spots"

        result.append({
            "lot_id": lot["lot_id"],
            "lot_name": lot["lot_name"],
            "rate_per_minute": lot["rate_per_minute"],
            "available_spots": lot["available_spots"],
            "total_spots": lot["total_spots"],
            "occupancy_rate": round(lot["occupancy_rate"] * 100, 1),
            "score": 0.0,
            "reason": reason,
            "type": lot["type"],
        })

    return result