import streamlit as st
import requests
import base64
import io
import time
from PIL import Image

API_URL = "http://localhost:8000"

VIOLATION_LABELS = {
    "prekrsaj_invalidsko":   "Parkiranje na invalidskom mjestu",
    "prekrsaj_nije_parking": "Parkiranje izvan označenog mjesta",
    "prekrsaj_van_okvira":   "Vozilo van parkirnog okvira",
}

st.set_page_config(page_title="ParkSmart AI", layout="wide")

st.markdown("""
<style>
@import url('https://fonts.googleapis.com/css2?family=DM+Mono:wght@400;500&family=DM+Sans:wght@400;500;600&display=swap');

* { font-family: 'DM Sans', sans-serif; }
footer { display: none; }
#MainMenu { display: none; }
[data-testid="stHeader"] { display: none; }

.block-container {
    padding-top: 1.2rem !important;
    padding-bottom: 0 !important;
    max-width: 1400px;
}

div[data-testid="stImage"] img {
    max-height: 65vh;
    object-fit: contain;
    border-radius: 10px;
}

/* Info badge */
.info-badge {
    display: inline-flex;
    gap: 16px;
    background: #111;
    border: 1px solid #222;
    border-radius: 8px;
    padding: 6px 14px;
    margin-bottom: 12px;
    font-family: 'DM Mono', monospace;
    font-size: 0.78rem;
    color: #666;
}

.info-badge span { color: #4ade80; }

/* Result card */
.result-card {
    background: #111;
    border: 1px solid #1e1e1e;
    border-radius: 10px;
    padding: 14px 16px;
    margin-bottom: 10px;
}

.tablica-text {
    font-family: 'DM Mono', monospace;
    font-size: 1.1rem;
    color: #fff;
    letter-spacing: 1px;
}

.ok-badge {
    display: inline-block;
    background: #052e16;
    color: #4ade80;
    border: 1px solid #166534;
    border-radius: 6px;
    padding: 3px 10px;
    font-size: 0.78rem;
    margin-top: 6px;
}

.err-badge {
    display: inline-block;
    background: #2d0a0a;
    color: #f87171;
    border: 1px solid #7f1d1d;
    border-radius: 6px;
    padding: 3px 10px;
    font-size: 0.78rem;
    margin-top: 6px;
    margin-right: 4px;
}

/* Placeholder */
.placeholder-box {
    background: #0d0d0d;
    border: 1px dashed #222;
    border-radius: 10px;
    height: 300px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #333;
    font-family: 'DM Mono', monospace;
    font-size: 0.85rem;
}

/* Dark background */
[data-testid="stAppViewContainer"] { background: #0a0a0a; }
[data-testid="stHeader"] { background: #0a0a0a; }

/* File uploader */
[data-testid="stFileUploader"] {
    border: 1px dashed #222 !important;
    border-radius: 10px !important;
    background: #0d0d0d !important;
}

/* Checkbox */
div[data-testid="stCheckbox"] label { color: #666 !important; font-size: 0.85rem; }

/* Buttons — active = white/black, inactive = outlined */
.stButton > button[kind="primary"] {
    background: #ffffff !important;
    color: #0a0a0a !important;
    border: 2px solid #ffffff !important;
    border-radius: 10px !important;
    font-weight: 600 !important;
    font-family: 'DM Sans', sans-serif !important;
}

.stButton > button[kind="secondary"] {
    background: transparent !important;
    color: #666 !important;
    border: 2px solid #2d2d2d !important;
    border-radius: 10px !important;
    font-weight: 500 !important;
    font-family: 'DM Sans', sans-serif !important;
}

.stButton > button[kind="secondary"]:hover {
    border-color: #fff !important;
    color: #fff !important;
}

p, label, .stMarkdown { color: #aaa; }
h1, h2, h3 { color: #fff; }
</style>
""", unsafe_allow_html=True)

# ── Tab state ─────────────────────────────────────────────────────────────────
if "active_tab" not in st.session_state:
    st.session_state.active_tab = "kamera_upload"

tabs_config = [
    ("kamera_upload", "Kamera · Upload"),
    ("kamera_live",   "Kamera · Live"),
    ("drone_upload",  "Drone · Upload"),
    ("drone_live",    "Drone · Live"),
]

cols = st.columns(len(tabs_config))
for col, (key, label) in zip(cols, tabs_config):
    with col:
        is_active = st.session_state.active_tab == key
        if st.button(
            label,
            key=f"tabbtn_{key}",
            use_container_width=True,
            type="primary" if is_active else "secondary"
        ):
            st.session_state.active_tab = key
            st.rerun()

st.markdown("<hr style='border-color:#1a1a1a; margin: 0.5rem 0 1.5rem'>", unsafe_allow_html=True)

active = st.session_state.active_tab


# ── Helper funkcije ───────────────────────────────────────────────────────────
def analiziraj(pil_img, lot, tip, cam_id):
    # Smanji sliku ako je prevelika
    pil_img.thumbnail((1280, 1280))
    buf = io.BytesIO()
    pil_img.save(buf, format="JPEG", quality=85)
    buf.seek(0)
    r = requests.post(
        f"{API_URL}/analyze",
        files={"file": ("img.jpg", buf, "image/jpeg")},
        data={"lot": lot, "camera_type": tip, "camera_id": cam_id},
        timeout=60
    )
    return r.json()


def decode_img(b64):
    return Image.open(io.BytesIO(base64.b64decode(b64)))


def dohvati_live(endpoint):
    try:
        r = requests.get(f"{API_URL}{endpoint}", timeout=10)
        d = r.json()
        if d.get("available"):
            return decode_img(d["annotated_image"]), d
        return None, None
    except:
        return None, None


def prikazi_rezultate(rezultat):
    auti = rezultat.get("rezultati", [])
    if not auti:
        st.markdown('<div class="result-card"><span style="color:#444;font-family:\'DM Mono\',monospace;font-size:0.85rem">Nema detektovanih vozila</span></div>', unsafe_allow_html=True)
        return
    for a in auti:
        tablica = a.get("tablica") or "N/A"
        v = a.get("violation_id")
        opis = VIOLATION_LABELS.get(v, v) if v else None
        if v:
            badge = f'<div class="err-badge">⚠ {opis}</div><div class="err-badge">Prijava kreirana</div>'
        else:
            badge = '<div class="ok-badge">✓ Pravilno parkiran</div>'
        st.markdown(f"""
        <div class="result-card">
            <div class="tablica-text">{tablica}</div>
            {badge}
        </div>
        """, unsafe_allow_html=True)


def upload_tab(key_prefix, tip_kamere, cam_id, label):
    col_l, col_r = st.columns([6, 4])
    with col_l:
        st.markdown(f'<div class="info-badge">zona: <span>Zona A</span> &nbsp;·&nbsp; uređaj: <span>{label}</span> &nbsp;·&nbsp; id: <span>{cam_id}</span></div>', unsafe_allow_html=True)
        uploaded = st.file_uploader(
            "Odaberi sliku", type=["jpg", "jpeg", "png"],
            label_visibility="collapsed", key=f"uploader_{key_prefix}"
        )
        img_ph = st.empty()

        if uploaded:
            uploaded.seek(0)
            img = Image.open(uploaded)
            st.session_state[f"{key_prefix}_img"] = img
            img_ph.image(img, use_container_width=True)
        elif f"{key_prefix}_img" in st.session_state:
            img_ph.image(st.session_state[f"{key_prefix}_img"], use_container_width=True)
        else:
            img_ph.markdown('<div class="placeholder-box">Uploadaj sliku</div>', unsafe_allow_html=True)

        if st.button("Analiziraj", key=f"btn_{key_prefix}", use_container_width=True, type="primary"):
            if f"{key_prefix}_img" not in st.session_state:
                st.warning("Uploadaj sliku prvo.")
            else:
                with st.spinner("Analiziram..."):
                    try:
                        rez = analiziraj(st.session_state[f"{key_prefix}_img"], "Zona A", tip_kamere, cam_id)
                        if "annotated_image" in rez:
                            img_ph.image(decode_img(rez["annotated_image"]), use_container_width=True)
                        st.session_state[f"{key_prefix}_rez"] = rez
                    except Exception as e:
                        st.error(f"Greška: {e}")

    with col_r:
        st.markdown("**Detektovano**")
        if f"{key_prefix}_rez" in st.session_state:
            prikazi_rezultate(st.session_state[f"{key_prefix}_rez"])
        else:
            st.caption("Uploadaj sliku i klikni Analiziraj.")


# ── Tabovi ────────────────────────────────────────────────────────────────────
if active == "kamera_upload":
    upload_tab("kamera", "entry", "cam_01", "kamera")

elif active == "kamera_live":
    col_l, col_r = st.columns([6, 4])
    with col_l:
        st.markdown('<div class="info-badge">zona: <span>Zona A</span> &nbsp;·&nbsp; uređaj: <span>kamera</span> &nbsp;·&nbsp; id: <span>cam_01</span></div>', unsafe_allow_html=True)
        auto_k = st.checkbox("Auto osvježavanje (3s)", key="auto_kamera")
        cam_img_ph = st.empty()
    with col_r:
        st.markdown("**Detektovano**")
        cam_rez_ph = st.empty()

    img, data = dohvati_live("/latest")
    if img:
        cam_img_ph.image(img, use_container_width=True)
        with cam_rez_ph.container():
            prikazi_rezultate(data)
    else:
        cam_img_ph.markdown('<div class="placeholder-box">Čekam sliku sa kamere...</div>', unsafe_allow_html=True)

    if auto_k:
        time.sleep(3)
        st.rerun()

elif active == "drone_upload":
    upload_tab("drone", "drone", "drone_01", "drone")

elif active == "drone_live":
    col_l, col_r = st.columns([6, 4])
    with col_l:
        st.markdown('<div class="info-badge">zona: <span>Zona A</span> &nbsp;·&nbsp; uređaj: <span>drone</span> &nbsp;·&nbsp; id: <span>drone_01</span></div>', unsafe_allow_html=True)
        st.image("http://localhost:8000/stream/drone", use_container_width=True)
    with col_r:
        st.markdown("**Detektovano**")
        st.caption("Live stream aktivan.")