from fastapi import FastAPI
from recommender import get_recommendations
from database import get_user_parking_history, get_available_lots

app = FastAPI()

@app.get("/recommend/{user_id}")
def recommend(user_id: str, lat: float = None, lng: float = None):
    history = get_user_parking_history(user_id)
    available_lots = get_available_lots()

    recommendations = get_recommendations(history, available_lots, lat, lng)
    return {"recommendations": recommendations}