"""
Smart Attendance Flask app (single-file ready-to-run)
- Adds /upload alias for compatibility
- Uses CPU fallback if no GPU available (auto-detect)
- Limits request size via MAX_CONTENT_LENGTH
- Improved logging and error handling
- Saves extracted faces and attendance CSV

Run (development):
    python smart_attendance_app.py

Run (production with gunicorn):
    gunicorn -w 2 -b 0.0.0.0:5000 smart_attendance_app:app --timeout 120

Make sure you have required packages installed (opencv-python, flask, insightface, numpy, werkzeug)
"""

from flask import Flask, request, jsonify
import cv2
import os
import re
import numpy as np
import pickle
import hashlib
import csv
import logging
from insightface.app import FaceAnalysis
from werkzeug.utils import secure_filename

# ------------------------------
# CONFIG
# ------------------------------
DB_FOLDER = "train"
EXTRACTED = "extracted_faces"
EMB_FILE = "embeddings_db.pkl"
SECTION = "ALL"  # change to A / B / C / ALL
ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png'}
ATTENDANCE_CSV = "attendance.csv"
MAX_UPLOAD_MB = 200  # request size limit

os.makedirs(EXTRACTED, exist_ok=True)

# ------------------------------
# LOGGING
# ------------------------------
logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# ------------------------------
# INIT MODEL (with CPU fallback)
# ------------------------------
def init_face_app():
    logger.info("🔄 Loading Buffalo model (FaceAnalysis)")
    try:
        face_app_local = FaceAnalysis(name="buffalo_l")
        # try GPU first, fall back to CPU
        try:
            face_app_local.prepare(ctx_id=0, det_size=(640, 640))
            logger.info("✅ Model loaded on GPU (ctx_id=0)")
        except Exception:
            face_app_local.prepare(ctx_id=-1, det_size=(640, 640))
            logger.info("✅ Model loaded on CPU (ctx_id=-1)")
        return face_app_local
    except Exception:
        logger.exception("Failed to initialize FaceAnalysis model. Make sure insightface and dependencies are installed.")
        raise

face_app = init_face_app()

# ------------------------------
# HELPERS
# ------------------------------

def parse_ad_number(folder_name: str):
    if folder_name.strip().upper() == "NA":
        return "NA"
    m = re.search(r'AD\s*0*([0-9]+)', folder_name, flags=re.IGNORECASE)
    if not m:
        return None
    return int(m.group(1))


def is_valid_folder(folder_name: str, choice: str) -> bool:
    tag = parse_ad_number(folder_name)
    if tag == "NA":
        return True
    if tag is None:
        return False
    if choice == "ALL":
        return True
    if choice == "A":
        return 1 <= tag <= 64
    if choice == "B":
        return 65 <= tag <= 127
    if choice == "C":
        return tag >= 128
    return False


def compute_folder_signature(folder_path: str) -> str:
    sig = hashlib.sha1()
    for fname in sorted(os.listdir(folder_path)):
        fpath = os.path.join(folder_path, fname)
        if os.path.isfile(fpath):
            stat = os.stat(fpath)
            sig.update(fname.encode())
            sig.update(str(stat.st_mtime).encode())
    return sig.hexdigest()


def load_db():
    if os.path.exists(EMB_FILE):
        try:
            with open(EMB_FILE, "rb") as f:
                db_data = pickle.load(f)
            embeddings_db = db_data.get("embeddings", {}) or {}
            signatures = db_data.get("signatures", {}) or {}
            return embeddings_db, signatures
        except Exception:
            logger.exception("Failed to load embeddings DB; starting fresh.")
            return {}, {}
    return {}, {}


def save_db(embeddings_db, signatures):
    try:
        with open(EMB_FILE, "wb") as f:
            pickle.dump({"embeddings": embeddings_db, "signatures": signatures}, f)
    except Exception:
        logger.exception("Failed to save embeddings DB")


def recognize_face(embedding, embeddings_db, threshold=0.35):
    best_id, best_score = "Unknown", -1
    emb_norm = embedding / (np.linalg.norm(embedding) + 1e-9)
    for sid, ref_emb_list in embeddings_db.items():
        if not isinstance(ref_emb_list, list):
            ref_emb_list = [ref_emb_list]
        for ref_emb in ref_emb_list:
            ref_norm = ref_emb / (np.linalg.norm(ref_emb) + 1e-9)
            sim = float(np.dot(emb_norm, ref_norm))
            if sim > best_score:
                best_score = sim
                best_id = sid
    return (best_id if best_score >= threshold else "Unknown", best_score)


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def save_attendance_csv(marked_rolls):
    try:
        with open(ATTENDANCE_CSV, "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["roll_number", "present"])
            for roll in marked_rolls:
                writer.writerow([roll, "Yes"])
    except Exception:
        logger.exception("Failed to write attendance CSV")

# ------------------------------
# FLASK APP
# ------------------------------
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = MAX_UPLOAD_MB * 1024 * 1024

@app.route("/train", methods=["POST"])
def train():
    embeddings_db, signatures = load_db()
    updated, skipped_no_face = 0, 0

    for student_id in sorted(os.listdir(DB_FOLDER)):
        student_path = os.path.join(DB_FOLDER, student_id)
        if not os.path.isdir(student_path):
            continue
        if not is_valid_folder(student_id, SECTION):
            continue

        current_sig = compute_folder_signature(student_path)
        prev_sig = signatures.get(student_id)
        if prev_sig == current_sig and student_id in embeddings_db:
            continue  # unchanged

        student_embeddings = []

        for img_name in sorted(os.listdir(student_path)):
            img_path = os.path.join(student_path, img_name)
            if not os.path.isfile(img_path):
                continue
            img = cv2.imread(img_path)
            if img is None:
                continue

            faces = face_app.get(img)
            if not faces:
                continue

            for face in faces:
                emb = face.embedding
                if emb is None:
                    continue
                emb = emb / (np.linalg.norm(emb) + 1e-9)
                student_embeddings.append(emb)

        if student_embeddings:
            embeddings_db[student_id] = student_embeddings
            signatures[student_id] = current_sig
            updated += 1
        else:
            embeddings_db.pop(student_id, None)
            signatures.pop(student_id, None)
            skipped_no_face += 1

    save_db(embeddings_db, signatures)
    return jsonify({
        "status": "ok",
        "updated": updated,
        "skipped_no_face": skipped_no_face,
        "total_students": len(embeddings_db)
    })


@app.route("/recognize", methods=["POST"])
def recognize():
    try:
        if "file" not in request.files:
            return jsonify({"error": "No file part"}), 400
        file = request.files["file"]
        if file.filename == "":
            return jsonify({"error": "No selected file"}), 400
        if not allowed_file(file.filename):
            return jsonify({"error": "File type not allowed"}), 400

        filename = secure_filename(file.filename)
        save_path = os.path.join(EXTRACTED, filename)
        file.save(save_path)

        img = cv2.imread(save_path)
        if img is None:
            return jsonify({"error": "Could not read image"}), 400

        embeddings_db, _ = load_db()
        faces = face_app.get(img)
        results = []
        marked_rolls = []

        if not faces:
            return jsonify({"status": "ok", "results": [], "marked_rolls": []})

        for i, face in enumerate(faces, 1):
            bbox = face.bbox
            x1, y1, x2, y2 = map(int, bbox)
            # clip bbox
            h, w = img.shape[:2]
            x1, x2 = max(0, min(x1, w-1)), max(0, min(x2, w-1))
            y1, y2 = max(0, min(y1, h-1)), max(0, min(y2, h-1))
            if x2 <= x1 or y2 <= y1:
                continue
            crop = img[y1:y2, x1:x2]
            if crop.size == 0:
                continue
            try:
                crop_resized = cv2.resize(crop, (160, 160))
            except Exception:
                logger.exception("Failed to resize crop")
                continue
            face_file = f"{os.path.splitext(filename)[0]}_face{i}.jpg"
            cv2.imwrite(os.path.join(EXTRACTED, face_file), crop_resized)

            student, score = recognize_face(face.embedding, embeddings_db)
            results.append({
                "face_file": face_file,
                "assigned_label": student,
                "similarity": round(score, 3)
            })

            # extract roll number
            m = re.search(r'AD0*([0-9]+)', str(student))
            if m:
                marked_rolls.append(int(m.group(1)))

        # Save attendance CSV
        save_attendance_csv(marked_rolls)

        return jsonify({
            "status": "ok",
            "results": results,
            "marked_rolls": marked_rolls,
            "message": f"{len(marked_rolls)} students marked present"
        })
    except Exception:
        logger.exception("Error during recognition")
        return jsonify({"error": "server error"}), 500


@app.route("/upload", methods=["POST"])
def upload_alias():
    # alias for backwards compatibility
    return recognize()


@app.route("/mark_manual", methods=["POST"])
def mark_manual():
    """
    Receives JSON: { "rolls": [6, 11, 22], "section": "A" }
    Saves the marked rolls to CSV, overwriting previous entries.
    """
    data = request.get_json()
    if not data or "rolls" not in data:
        return jsonify({"error": "No rolls provided"}), 400

    rolls = data["rolls"]
    section = data.get("section", "ALL")

    # Optional: filter rolls by section if needed
    if section == "A":
        rolls = [r for r in rolls if 1 <= r <= 64]
    elif section == "B":
        rolls = [r for r in rolls if 65 <= r <= 127]
    elif section == "C":
        rolls = [r for r in rolls if r >= 128]

    # Save CSV
    try:
        with open(ATTENDANCE_CSV, "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["roll_number", "present"])
            for roll in rolls:
                writer.writerow([roll, "Yes"])
    except Exception:
        logger.exception("Failed to save manual attendance CSV")
        return jsonify({"error": "server error"}), 500

    return jsonify({
        "status": "ok",
        "message": f"{len(rolls)} students marked present manually"
    })


@app.route("/", methods=["GET"])
def index():
    return """
    <html><body>
      <h3>Smart Attendance</h3>
      <p>Use the form below to test upload (POST /upload):</p>
      <form action=\"/upload\" method=\"post\" enctype=\"multipart/form-data\">
        <input type=\"file\" name=\"file\" accept=\"image/*\" required>
        <button type=\"submit\">Upload</button>
      </form>
      <p>Or POST to <code>/recognize</code> or <code>/train</code> (server-side).</p>
    </body></html>
    """, 200

if __name__ == "__main__":
    # For quick testing only. Use gunicorn for production.
    logger.info("Starting Flask dev server (threaded=True) on 0.0.0.0:5000")
    app.run(host="0.0.0.0", port=5000, threaded=True)
