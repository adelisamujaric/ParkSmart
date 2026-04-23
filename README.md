# ParkSmart

## Opis sistema

ParkSmart je sistem za upravljanje parking prostorima koji omogućava praćenje zauzetosti parking mjesta u realnom vremenu, automatsku naplatu, rezervacije, detekciju prekršaja i preporuke parking zona na osnovu historije korisnika.

---

## Napomena o hardveru

Sistem je dizajniran da radi sa fizičkim hardverom tj. dronovima za inspekciju parkinga i kamerama za prepoznavanje registarskih tablica na ulazu i izlazu parkinga. Kako ovaj hardver nije obavezan za predmet Razvoj softvera 2, sve funkcionalnosti vezane za hardver mogu se testirati putem simulacije koja je dostupna u admin panelu pod opcijom "Testna prijava". Sistem trenutno funkcioniše i bez fizičkih uređaja s tim da će uređaji biti razvijeni u nastavku za potrebe odbrane diplomskog rada.

---

## Arhitektura sistema

Sistem je izgrađen na mikroservisnoj arhitekturi i sastoji se od sljedećih komponenti:

**Backend (C# / .NET 8):**
- UserService — autentifikacija, korisnici, vozila (port 5072)
- ParkingService — parking lotovi, spotovi, tiketi, rezervacije, prekršaji (port 5148)
- PaymentService — plaćanje putem Stripe-a za tikete, rezervacije i prekršaje (port 5038)
- NotificationService — InApp notifikacije za tikete, rezervacije i prekršaje (port 5175)
- ReportingService — izvještaji i statistika (port 5113)
- DetectionService — kamera i drone detekcije (port 5164)

**Frontend (Flutter):**
- Desktop/Web aplikacija — admin panel
- Mobilna aplikacija — user panel

**Ostalo:**
- RecommenderSystem — Python/FastAPI — preporuke parking zona (port 8001)
- RabbitMQ — komunikacija između mikroservisa (port 5672, management panel 15672)
- SQL Server — baza podataka (port 1433)

---

## Pokretanje aplikacije

### Preduvjeti
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instaliran i pokrenut
- [Flutter SDK](https://flutter.dev/docs/get-started/install) instaliran

### Pokretanje backenda
Otvoriti Visual Studio, otvoriti solution `backend/ParkSmart_IB220199.sln` i kliknuti dugme **Docker Compose** u toolbaru.

Ili u terminalu:
```
cd backend
docker-compose up --build
```

## Build fajlovi

Build fajlovi dostupni su u GitHub Releases sekciji repozitorija.

ZIP arhiva sadrži:
- `app-release.apk` — Android mobilna aplikacija
- `Release/` — Windows desktop aplikacija (admin panel)

### Instalacija Android aplikacije
1. Preuzeti ZIP arhivu iz GitHub Releases
2. Izvući `app-release.apk`
3. Instalirati APK na Android uređaj ili emulator (AVD)
   - Na emulatoru: prevući `.apk` fajl u AVD prozor
   - API adresa za emulator je automatski postavljena na `10.0.2.2`

### Pokretanje Windows aplikacije
1. Preuzeti ZIP arhivu iz GitHub Releases
2. Izvući `Release/` folder
3. Pokrenuti `frontend.exe`
   - API adresa je automatski postavljena na `localhost`
   - Backend mora biti pokrenut putem Docker Compose-a

---

## Korisnički nalozi

| Kontekst | Korisničko ime | Lozinka |
|----------|----------------|---------|
| Desktop/Web verzija | admin@email.com | admin |
| Mobilna verzija | user@email.com | user |


Admin ima pristup desktop/web admin panelu gdje može upravljati parking zonama, korisnicima, pregledati tikete, prekršaje, statistike i simulirati rad kamere i drona.

User pristupa sistemu putem mobilne aplikacije gdje može pregledati parking zone, kupiti tiket, rezervisati mjesto, platiti parking i vidjeti preporuke na osnovu historije parkiranja.

---

## Testno plaćanje (Stripe)

Za testiranje plaćanja koristiti sljedeće podatke:
- Broj kartice: `4242 4242 4242 4242`
- Datum isteka: bilo koji budući datum (npr. `12/34`)
- CVV: bilo koja 3 cifre (npr. `123`)
- Poštanski broj: 12345

---

## RabbitMQ

Nakon pokretanja Dockera, RabbitMQ management panel dostupan je na adresi `http://localhost:15672` sa kredencijalima `guest/guest`. Ovdje se mogu pratiti poruke koje razmjenjuju mikroservisi.

---

## Funkcionalnosti

**Web aplikacija (admin panel):**
- Pregled i upravljanje parking zonama i mjestima
- Praćenje aktivnih tiketa i sesija parkiranja
- Upravljanje dronovima i kamerama
- Pregled i odobravanje prekršaja
- Statistike i izvještaji sa mogućnošću exporta u PDF
- Upravljanje korisnicima i vozilima

**Mobilna aplikacija (korisnici):**
- Pregled dostupnih parking zona
- Rezervacija parking mjesta
- Plaćanje putem Stripe-a
- Pregled historije parkiranja, rezervacija i prekršaja
- Preporuke parking zona na osnovu historije korisnika

**Simulacija hardvera (admin panel):**
Testiranje funkcionalnosti kamere i drona moguće je putem opcije "Testna prijava" u admin panelu, gdje se može simulirati ulaz i izlaz vozila kao i inspekcija dronom sa detekcijom prekršaja.