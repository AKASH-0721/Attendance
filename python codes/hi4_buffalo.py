import cv2
import os
import re
import numpy as np
import csv
import pickle
import hashlib
from insightface.app import FaceAnalysis

# ------------------------------
# 1) Init InsightFace
# ------------------------------
face_app = FaceAnalysis(name="buffalo_l")
face_app.prepare(ctx_id=0, det_size=(256, 256))  # CPU ok with ctx_id=0

DB_FOLDER = "train"
EMB_FILE = "embeddings_db.pkl"

# ------------------------------
# 2) User choice (A/B/C/ALL)
# ------------------------------
choice = input("Select dataset group (A / B / C / ALL): ").strip().upper()
if choice not in {"A", "B", "C", "ALL"}:
    print("Invalid choice. Using ALL.")
    choice = "ALL"

# ------------------------------
# 3) Helpers
# ------------------------------
def parse_ad_number(folder_name: str):
    """Return int AD number or 'NA' or None if not AD/NA."""
    if folder_name.strip().upper() == "NA":
        return "NA"
    m = re.search(r'AD\s*0*([0-9]+)', folder_name, flags=re.IGNORECASE)
    if not m:
        return None
    return int(m.group(1))

def is_valid_folder(folder_name: str, choice: str) -> bool:
    """Allow NA always; AD based on group; ALL includes all AD."""
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
    """Hash of filenames + last modified times."""
    sig = hashlib.sha1()
    for fname in sorted(os.listdir(folder_path)):
        fpath = os.path.join(folder_path, fname)
        if os.path.isfile(fpath):
            stat = os.stat(fpath)
            sig.update(fname.encode())
            sig.update(str(stat.st_mtime).encode())
    return sig.hexdigest()

def pick_main_face(faces):
    """Pick face with best combination of detection score and area."""
    if not faces:
        return None
    def score(f):
        x1, y1, x2, y2 = f.bbox
        area = max(0, (x2-x1)) * max(0, (y2-y1))
        return (getattr(f, "det_score", 0.0), area)
    return max(faces, key=score)

# ------------------------------
# 4) Load or init DB (backward compatible)
# ------------------------------
embeddings_db = {}
signatures = {}

if os.path.exists(EMB_FILE):
    try:
        with open(EMB_FILE, "rb") as f:
            db_data = pickle.load(f)
        if isinstance(db_data, dict) and "embeddings" in db_data:
            embeddings_db = db_data["embeddings"] or {}
            signatures = db_data.get("signatures", {}) or {}
        elif isinstance(db_data, dict):
            embeddings_db = db_data
            signatures = {}
        else:
            embeddings_db, signatures = {}, {}
        print("✅ Loaded saved embeddings database.")
    except Exception as e:
        print(f"⚠️ Could not load {EMB_FILE} ({e}). Starting fresh.")
        embeddings_db, signatures = {}, {}
else:
    print("⚠️ No saved database found. Building new one...")

# ------------------------------
# 5) Scan train/ and (re)compute as needed
# ------------------------------
updated, skipped_no_face = 0, 0
included_folders = []

for student_id in sorted(os.listdir(DB_FOLDER)):
    student_path = os.path.join(DB_FOLDER, student_id)
    if not os.path.isdir(student_path):
        continue
    if not is_valid_folder(student_id, choice):
        continue

    included_folders.append(student_id)

    current_sig = compute_folder_signature(student_path)
    prev_sig = signatures.get(student_id)

    # Skip only if already present and unchanged
    if prev_sig == current_sig and student_id in embeddings_db:
        continue

    print(f"🔄 Processing {student_id} ...")

    # Compute embeddings for this student
    student_embeddings = []
    for img_name in sorted(os.listdir(student_path)):
        img_path = os.path.join(student_path, img_name)
        if not os.path.isfile(img_path):
            continue
        img = cv2.imread(img_path)
        if img is None:
            continue

        faces = face_app.get(img)
        face = pick_main_face(faces)
        if face is None:
            continue

        emb = face.embedding
        emb = emb / np.linalg.norm(emb)
        student_embeddings.append(emb)

    if student_embeddings:
        mean_emb = np.mean(student_embeddings, axis=0)
        mean_emb = mean_emb / np.linalg.norm(mean_emb)
        embeddings_db[student_id] = mean_emb
        signatures[student_id] = current_sig
        updated += 1
        print(f"✅ Updated {student_id} with {len(student_embeddings)} images")
    else:
        # If no faces now, ensure we don't keep stale entries
        if student_id in embeddings_db:
            del embeddings_db[student_id]
        if student_id in signatures:
            del signatures[student_id]
        skipped_no_face += 1
        print(f"⚠️ No valid embeddings for {student_id} (removed if existed)")

# Save DB
with open(EMB_FILE, "wb") as f:
    pickle.dump({"embeddings": embeddings_db, "signatures": signatures}, f)

# ------------------------------
# 5b) Filter embeddings DB for chosen section
# ------------------------------
filtered_db = {}
for student_id, emb in embeddings_db.items():
    if is_valid_folder(student_id, choice):
        filtered_db[student_id] = emb

embeddings_db = filtered_db
print(f"✅ Using {len(embeddings_db)} students for section {choice}")


# ------------------------------
# 6) Recognition
# ------------------------------
def recognize_face(embedding, threshold=0.30):  # slightly lower threshold
    embedding = embedding / np.linalg.norm(embedding)
    best_match, best_score = "Unknown", -1.0
    for student_id, db_emb in embeddings_db.items():
        sim = np.dot(db_emb, embedding)
        if sim > best_score:
            best_score, best_match = sim, student_id
    if best_score >= threshold:
        return best_match, best_score
    return "Unknown", best_score

EXTRACTED = "extracted_faces"
results = []

for img_name in sorted(os.listdir(EXTRACTED)):
    img_path = os.path.join(EXTRACTED, img_name)
    if not os.path.isfile(img_path):
        continue
    img = cv2.imread(img_path)
    if img is None:
        print(f"⚠️ Could not read {img_name}")
        continue

    faces = face_app.get(img)
    face = pick_main_face(faces)
    if face is None:
        print(f"❌ No face detected in {img_name}")
        continue

    emb = face.embedding
    student, score = recognize_face(emb)

    print(f"📷 {img_name} → {student} (similarity={score:.3f})")
    results.append([img_name, student, round(score, 3)])

# ------------------------------
# 7) Results CSV
# ------------------------------
csv_file = "recognized_faces.csv"
with open(csv_file, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["img_name", "assigned_label", "similarity"])
    writer.writerows(results)

print(f"\n✅ Results saved to {csv_file}")
