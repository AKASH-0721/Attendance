from flask import Flask, request, jsonify
import cv2
import os
import re
import numpy as np
import pickle
import hashlib
import csv
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

os.makedirs(EXTRACTED, exist_ok=True)

# ------------------------------
# INIT MODEL - IMPROVED FOR BETTER DETECTION
# ------------------------------
print("🔄 Loading Buffalo model...")
face_app = FaceAnalysis(name="buffalo_l")
face_app.prepare(ctx_id=-1, det_size=(640, 640))

# Initialize additional scales with error handling
face_app_small = None
face_app_large = None

try:
    face_app_small = FaceAnalysis(name="buffalo_l")
    face_app_small.prepare(ctx_id=-1, det_size=(320, 320))
    print("✅ Small scale model loaded")
except Exception as e:
    print(f"⚠️ Small scale model failed to load: {e}")

try:
    face_app_large = FaceAnalysis(name="buffalo_l")
    face_app_large.prepare(ctx_id=-1, det_size=(1280, 1280))
    print("✅ Large scale model loaded")
except Exception as e:
    print(f"⚠️ Large scale model failed to load: {e}")

print("✅ Model loading complete")

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
        except:
            return {}, {}
    return {}, {}

def save_db(embeddings_db, signatures):
    with open(EMB_FILE, "wb") as f:
        pickle.dump({"embeddings": embeddings_db, "signatures": signatures}, f)

def is_valid_face(face, img_shape):
    """Check if detected face meets quality criteria"""
    x1, y1, x2, y2 = map(int, face.bbox)
    
    # Face size validation
    face_width = x2 - x1
    face_height = y2 - y1
    face_area = face_width * face_height
    img_area = img_shape[0] * img_shape[1]
    
    # More lenient face size validation for crowded photos
    # Face should be at least 0.05% of image area but not more than 60%
    if face_area < img_area * 0.0005 or face_area > img_area * 0.6:
        return False
    
    # Face should be roughly square (aspect ratio check)
    aspect_ratio = face_width / max(face_height, 1)
    if aspect_ratio < 0.5 or aspect_ratio > 2.0:
        return False
    
    # Check if face is within image boundaries
    if x1 < 0 or y1 < 0 or x2 >= img_shape[1] or y2 >= img_shape[0]:
        return False
    
    # Check face detection confidence if available
    if hasattr(face, 'det_score') and face.det_score < 0.5:
        return False
    
    return True

def recognize_face(embedding, embeddings_db, adaptive_threshold=True):
    """Improved face recognition with adaptive thresholding"""
    best_id, best_score = "Unknown", -1
    embedding = embedding / np.linalg.norm(embedding)
    
    scores = []
    for sid, ref_emb_list in embeddings_db.items():
        if not isinstance(ref_emb_list, list):
            ref_emb_list = [ref_emb_list]
        
        max_sim_for_person = -1
        for ref_emb in ref_emb_list:
            ref_emb = ref_emb / np.linalg.norm(ref_emb)
            sim = float(np.dot(embedding, ref_emb))
            max_sim_for_person = max(max_sim_for_person, sim)
        
        scores.append(max_sim_for_person)
        if max_sim_for_person > best_score:
            best_score = max_sim_for_person
            best_id = sid
    
    # Adaptive threshold based on score distribution
    if adaptive_threshold and scores:
        mean_score = np.mean(scores)
        std_score = np.std(scores)
        # More lenient threshold for crowded photos
        adaptive_thresh = max(0.20, mean_score + 1.0 * std_score)
        threshold = min(0.35, adaptive_thresh)
    else:
        threshold = 0.25  # Lower base threshold for better recognition
    
    return (best_id if best_score >= threshold else "Unknown", best_score, threshold)

def detect_faces_multi_scale(img):
    """Detect faces using multiple scales and combine results"""
    all_faces = []
    
    # Build list of available detection apps
    detection_apps = []
    
    if face_app_large is not None:
        detection_apps.append((face_app_large, "large"))
    
    # Always include the main app
    detection_apps.append((face_app, "medium"))
    
    if face_app_small is not None:
        detection_apps.append((face_app_small, "small"))
    
    print(f"🔍 Using {len(detection_apps)} detection scales")
    
    for app, scale_name in detection_apps:
        try:
            faces = app.get(img)
            valid_faces = []
            for face in faces:
                if is_valid_face(face, img.shape):
                    # Add scale info to face
                    face.scale = scale_name
                    valid_faces.append(face)
            
            print(f"   🔸 {scale_name} scale: {len(faces)} detected, {len(valid_faces)} valid")
            all_faces.extend(valid_faces)
            
        except Exception as e:
            print(f"❌ Error in {scale_name} scale detection: {e}")
            continue
    
    print(f"   📊 Total faces before duplicate removal: {len(all_faces)}")
    
    # Remove duplicate faces (same person detected at multiple scales)
    if len(all_faces) > 0:
        filtered_faces = remove_duplicate_faces(all_faces)
        print(f"   🎯 Final faces after duplicate removal: {len(filtered_faces)}")
        return filtered_faces
    else:
        print("   ⚠️ No valid faces detected")
        return []

def remove_duplicate_faces(faces):
    """Remove duplicate face detections based on bbox overlap"""
    if len(faces) <= 1:
        return faces
    
    # Sort by detection confidence (if available) or area
    faces.sort(key=lambda f: getattr(f, 'det_score', 0.5) * 
               ((f.bbox[2] - f.bbox[0]) * (f.bbox[3] - f.bbox[1])), reverse=True)
    
    filtered = []
    for face in faces:
        is_duplicate = False
        x1, y1, x2, y2 = face.bbox
        
        for existing_face in filtered:
            ex1, ey1, ex2, ey2 = existing_face.bbox
            
            # Calculate IoU (Intersection over Union)
            intersection_area = max(0, min(x2, ex2) - max(x1, ex1)) * max(0, min(y2, ey2) - max(y1, ey1))
            face_area = (x2 - x1) * (y2 - y1)
            existing_area = (ex2 - ex1) * (ey2 - ey1)
            union_area = face_area + existing_area - intersection_area
            
            if union_area > 0:
                iou = intersection_area / union_area
                # More strict overlap threshold for crowded photos
                if iou > 0.6:  # 60% overlap threshold - only remove if faces heavily overlap
                    is_duplicate = True
                    break
        
        if not is_duplicate:
            filtered.append(face)
    
    return filtered

def preprocess_image(img):
    """Preprocess image for better face detection"""
    # Convert to RGB if needed
    if len(img.shape) == 3 and img.shape[2] == 3:
        # Enhance contrast and brightness
        lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        
        # Apply CLAHE to L channel
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        l = clahe.apply(l)
        
        # Merge channels and convert back
        enhanced = cv2.merge([l, a, b])
        img = cv2.cvtColor(enhanced, cv2.COLOR_LAB2BGR)
    
    return img

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def save_attendance_csv(marked_rolls):
    with open(ATTENDANCE_CSV, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["roll_number", "present"])
        for roll in marked_rolls:
            writer.writerow([roll, "Yes"])

# ------------------------------
# FLASK APP
# ------------------------------
app = Flask(__name__)

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

            # Preprocess image for better detection
            img = preprocess_image(img)
            
            # Use multi-scale detection for training too
            faces = detect_faces_multi_scale(img)
            if not faces:
                continue

            for face in faces:
                emb = face.embedding / np.linalg.norm(face.embedding)
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

    # Preprocess image for better detection
    img = preprocess_image(img)
    
    embeddings_db, _ = load_db()
    
    # Use improved multi-scale face detection with fallback
    try:
        faces = detect_faces_multi_scale(img)
    except Exception as e:
        print(f"❌ Multi-scale detection failed: {e}")
        print("🔄 Falling back to single-scale detection...")
        try:
            faces = face_app.get(img)
            # Apply basic validation
            valid_faces = []
            for face in faces:
                if is_valid_face(face, img.shape):
                    face.scale = "medium_fallback"
                    valid_faces.append(face)
            faces = valid_faces
            print(f"✅ Fallback detection found {len(faces)} valid faces")
        except Exception as fallback_error:
            print(f"❌ Fallback detection also failed: {fallback_error}")
            return jsonify({"error": "Face detection system failed"}), 500
    
    results = []
    marked_ids = []
    recognition_details = []

    if not faces:
        return jsonify({
            "status": "ok", 
            "results": [], 
            "marked_ids": [],
            "message": "No faces detected in the image",
            "total_faces_detected": 0
        })

    print(f"🔍 Multi-scale detection complete:")
    print(f"   📊 Total faces detected: {len(faces)}")
    
    # Count faces by detection scale for debugging
    scale_counts = {}
    for face in faces:
        scale = getattr(face, 'scale', 'unknown')
        scale_counts[scale] = scale_counts.get(scale, 0) + 1
    
    for scale, count in scale_counts.items():
        print(f"   🔸 {scale} scale: {count} faces")
    
    print(f"   🎯 Processing {len(faces)} unique faces after duplicate removal")

    for i, face in enumerate(faces, 1):
        x1, y1, x2, y2 = map(int, face.bbox)
        crop = img[y1:y2, x1:x2]
        if crop.size == 0:
            continue
            
        crop_resized = cv2.resize(crop, (160, 160))
        face_file = f"{os.path.splitext(filename)[0]}_face{i}.jpg"
        cv2.imwrite(os.path.join(EXTRACTED, face_file), crop_resized)

        student, score, threshold = recognize_face(face.embedding, embeddings_db)
        
        recognition_details.append({
            "face_number": i,
            "student_id": student,
            "similarity_score": round(score, 3),
            "threshold_used": round(threshold, 3),
            "detection_scale": getattr(face, 'scale', 'unknown')
        })
        
        results.append({
            "face_file": face_file,
            "assigned_label": student,
            "similarity": round(score, 3),
            "threshold": round(threshold, 3)
        })

        if student != "Unknown":
            marked_ids.append(student)

    # Remove duplicates while preserving order
    unique_marked_ids = list(dict.fromkeys(marked_ids))
    
    # Save attendance CSV
    save_attendance_csv(unique_marked_ids)

    return jsonify({
        "status": "ok",
        "results": results,
        "marked_ids": unique_marked_ids,
        "total_faces_detected": len(faces),
        "recognized_faces": len(unique_marked_ids),
        "recognition_details": recognition_details,
        "message": f"{len(unique_marked_ids)} students marked present"
    })
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
    with open(ATTENDANCE_CSV, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["roll_number", "present"])
        for roll in rolls:
            writer.writerow([roll, "Yes"])

    return jsonify({
        "status": "ok",
        "message": f"{len(rolls)} students marked present manually"
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
