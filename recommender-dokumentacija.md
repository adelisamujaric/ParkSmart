# Recommender System – Dokumentacija

*Opis implementacije i tehnička dokumentacija*

---

## 1. Uvod i svrha sistema

Recommender system je implementiran kao zasebni Python mikroservis koji analizira historiju parkiranja korisnika i predlaže optimalne parking lokacije. Servis je integrisan u postojeću parking aplikaciju i dostupan putem REST API-ja koji konzumira Flutter mobilna aplikacija.

Implementirani sistem koristi **content-based filtering** pristup gdje se preporuke generišu isključivo na osnovu historije i preferencija jednog korisnika, bez poređenja sa drugim korisnicima.

Cilj sistema je personalizovati iskustvo parkiranja tako što korisniku prikazuje parking lotove rangirane prema njegovim navikama, preferencijama, trenutnoj dostupnosti mjesta i geografskoj blizini. Na početnom ekranu (Home) prikazuje se top preporuka, tj. parking lot sa najvišim izračunatim scoreom.

---

## 2. Arhitektura sistema

### 2.1 Komponente

| Komponenta | Opis |
|---|---|
| **main.py** | FastAPI REST endpoint – prima user_id i opciono koordinate, orkestrira pozive ka ostalim modulima |
| **database.py** | Dohvata historiju parkiranja korisnika i listu dostupnih parking lotova iz SQL Server baze |
| **recommender.py** | Sadrži glavnu logiku – izračun scoreva, sortiranje i generisanje preporuka |
| **RecommenderService (Flutter)** | Dart servis koji poziva /recommend/{user_id} endpoint i mapira JSON odgovor u model |
| **mobile_home_screen.dart** | Flutter ekran koji prikazuje top preporuku korisniku |

### 2.2 Tok podataka

1. Flutter app šalje GET zahtjev na `/recommend/{user_id}` putem RecommenderService, opciono sa `lat` i `lng` parametrima
2. `main.py` dohvata historiju korisnika iz baze (ParkingTickets JOIN ParkingSpots JOIN ParkingLots)
3. `main.py` dohvata listu aktivnih parking lotova sa brojem slobodnih mjesta i koordinatama
4. `recommender.py` prima obje liste i izračunava score za svaki dostupni lot koristeći 6 faktora
5. Vraća se sortirana lista preporuka kao JSON response
6. Flutter uzima prvi element liste (top preporuku) i prikazuje je na Home screenu

---

## 3. Algoritam preporuke

### 3.1 Scoring formula

Svaki dostupni parking lot dobija score koji se računa kombinacijom **šest faktora** sa različitim težinskim koeficijentima:

| Faktor | Težina | Opis |
|---|---|---|
| Visit score (historija posjeta) | **40%** | Normalizovani broj posjeta korisnika na ovom lotu (MinMaxScaler) |
| Podudaranje sata | **15%** | Koliko se trenutni sat podudara s prosječnim satom korisnikovog parkiranja na ovom lotu |
| Preferencija cijene iz historije | **10%** | Na osnovu prosječne cijene koju je korisnik plaćao ranije – niža prosječna cijena = veći score |
| Dostupnost mjesta | **20%** | Omjer slobodnih i ukupnih mjesta (available_spots / total_spots) |
| Trenutna cijena parkiranja | **10%** | Niži RatePerMinute daje veći score (inverzna proporcionalnost) |
| Blizina korisnika | **5%** | Izračunata Haversine distanca između korisnikove lokacije i parking lota – manji distance = veći score (max korisna distanca: 10 km) |

**Napomena:** Faktor blizine (lat/lng) se primjenjuje samo ako su koordinate proslijeđene u zahtjevu. Ako koordinate nisu dostupne, preostalih 5% se ne računa.

### 3.2 Haversine formula

Za izračun geografske udaljenosti koristi se Haversine formula:

```
R = 6371 km
d_lat = radians(lat2 - lat1)
d_lng = radians(lng2 - lng1)
a = sin(d_lat/2)² + cos(lat1) * cos(lat2) * sin(d_lng/2)²
c = 2 * atan2(√a, √(1-a))
distance = R * c
```

### 3.3 Cold start situacija

Kada korisnik nema historiju parkiranja (novi korisnik ili nema završenih tiketa sa statusom 2 ili 4), sistem primjenjuje cold start strategiju:

- **Ako su dostupne koordinate:** sortira po kombinaciji dostupnosti (60%) i blizine (40%)
- **Ako koordinate nisu dostupne:** sortira isključivo po broju slobodnih mjesta, silazno

Score se postavlja na `0.0` u cold start scenariju.

### 3.4 Razlog preporuke (reason)

Svaka preporuka dolazi s detaljnim objašnjenjem koje kombinuje više faktora:

| Situacija | Primjer reason poruke |
|---|---|
| Korisnik ima historiju | `"You've parked here 3 time(s) before \| matches your usual parking time (~14h) \| avg stay 45 min \| avg cost 2.30 KM \| high availability \| 350m away"` |
| Korisnik nema historiju, ima koordinate | `"Most available spots \| 1.2km away"` |
| Cold start bez koordinata | `"Most available spots"` |
| Visoka dostupnost bez historije | `"high availability \| 800m away"` |

Komponente reason poruke:
- **Broj posjeta** – `"You've parked here N time(s) before"`
- **Podudaranje sata** – prikazuje se ako je razlika između trenutnog i preferiranog sata ≤ 2h
- **Prosječno trajanje** – `"avg stay X min"` iz historije korisnika
- **Prosječna cijena** – `"avg cost X.XX KM"` iz historije korisnika
- **Dostupnost** – `"high availability"` (< 30% popunjeno) ili `"good availability"`
- **Udaljenost** – prikazuje se u metrima (< 1 km) ili kilometrima

---

## 4. Podaci koji se prikupljaju i koriste

Sistem koristi sljedeće podatke iz baze koji se **stvarno upisuju tokom korištenja aplikacije**:

| Signal | Izvor | Korištenje u scoringu |
|---|---|---|
| `lot_id` | ParkingTickets tabela | Grupiranje po lotu, visit_count |
| `total_price` | ParkingTickets tabela | avg_price → price_preference_score (10%) |
| `duration_minutes` | ParkingTickets tabela | avg_duration → prikazano u reason |
| `hour_of_day` | Izvedeno iz EntryTime | preferred_hour → hour score (15%) |
| `available_spots` | ParkingSpots tabela | availability_score (20%) |
| `total_spots` | ParkingLots tabela | availability_score (20%) |
| `rate_per_minute` | ParkingLots tabela | price_score (10%) |
| `lat`, `lng` | Korisnikova lokacija (Flutter) | proximity_score (5%) |

**Svi signali koji se koriste u scoringu se stvarno prikupljaju i upisuju u aplikaciji.**

---

## 5. Tehnologije i biblioteke

| Tehnologija | Svrha |
|---|---|
| Python 3.x | Programski jezik servisa |
| FastAPI | REST API framework, automatski generiše Swagger dokumentaciju |
| pandas | Manipulacija podacima i grupiranje historije po lot_id |
| scikit-learn (MinMaxScaler) | Normalizacija visit_count i avg_price vrijednosti |
| math (Haversine) | Izračun geografske udaljenosti između korisnika i parking lota |
| SQLAlchemy + pyodbc | Konekcija na SQL Server bazu |
| SQL Server (MSSQL) | Ista baza kao i glavni parking mikroservis (IB220199_Parking) |

---

## 6. REST API endpoint

| Polje | Vrijednost |
|---|---|
| **Metoda** | GET |
| **Putanja** | `/recommend/{user_id}` |
| **Parametar: user_id** | UUID korisnika (obavezno) |
| **Parametar: lat** | Geografska širina korisnika (opcionalno) |
| **Parametar: lng** | Geografska dužina korisnika (opcionalno) |
| **Response** | JSON: `{ recommendations: [ { lot_id, lot_name, rate_per_minute, available_spots, total_spots, occupancy_rate, score, reason, type } ] }` |

### Primjer zahtjeva

```
GET /recommend/123e4567-e89b-12d3-a456-426614174000?lat=43.8563&lng=18.4131
```

### Primjer odgovora

```json
{
  "recommendations": [
    {
      "lot_id": "abc123",
      "lot_name": "Parking Centar",
      "rate_per_minute": 0.05,
      "available_spots": 12,
      "total_spots": 20,
      "occupancy_rate": 40.0,
      "score": 0.872,
      "reason": "You've parked here 5 time(s) before | matches your usual parking time (~10h) | avg stay 60 min | avg cost 3.00 KM | good availability | 250m away",
      "type": "Open"
    }
  ]
}
```

---

## 7. Putanje fajlova

| Fajl | Putanja |
|---|---|
| **API endpoint** | `recommenderSystem/main.py` |
| **Baza – upiti** | `recommenderSystem/database.py` |
| **Glavna logika** | `recommenderSystem/recommender.py` |
| **Flutter service** | `lib/features/recommendations/services/recommender_service.dart` |
| **Flutter model** | `lib/features/recommendations/models/` |
| **Flutter ekran (Home)** | `lib/features/auth/screens/mobile_home_screen.dart` |
