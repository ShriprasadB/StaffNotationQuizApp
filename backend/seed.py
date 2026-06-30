#!/usr/bin/env python3
"""
Seed Firebase from backend/Photos.

For every <clef>_<note><octave>.png it:
  1. uploads the image to Storage at notations/<filename> (with a public
     download token),
  2. creates a Firestore document in `questions` with imageUrl + correctAnswer.

Usage:
  pip install firebase-admin
  export FIREBASE_SA="/path/to/serviceAccount.json"
  export FIREBASE_BUCKET="your-project.appspot.com"   # or .firebasestorage.app
  python3 backend/seed.py
"""
import os
import glob
import uuid
import urllib.parse

import firebase_admin
from firebase_admin import credentials, firestore, storage

SA_PATH = os.environ["FIREBASE_SA"]
BUCKET = os.environ["FIREBASE_BUCKET"]
PHOTOS_DIR = os.path.join(os.path.dirname(__file__), "Photos")
VALID_NOTES = set("CDEFGAB")


def parse_filename(filename: str):
    """treble_C4.png -> (clef='treble', answer='C')."""
    base = os.path.splitext(filename)[0]      # treble_C4
    clef, note = base.split("_", 1)           # treble, C4
    answer = note[0].upper()
    if answer not in VALID_NOTES:
        raise ValueError(f"Unexpected note letter in {filename!r}")
    return clef, answer


def download_url(filename: str, token: str) -> str:
    path = urllib.parse.quote(f"notations/{filename}", safe="")
    return (
        f"https://firebasestorage.googleapis.com/v0/b/{BUCKET}"
        f"/o/{path}?alt=media&token={token}"
    )


def main():
    cred = credentials.Certificate(SA_PATH)
    firebase_admin.initialize_app(cred, {"storageBucket": BUCKET})
    db = firestore.client()
    bucket = storage.bucket()

    # Clear any existing questions so re-running is idempotent.
    existing = list(db.collection("questions").stream())
    for doc in existing:
        doc.reference.delete()
    if existing:
        print(f"cleared {len(existing)} existing questions")

    files = sorted(glob.glob(os.path.join(PHOTOS_DIR, "*.png")))
    if not files:
        raise SystemExit(f"No PNGs found in {PHOTOS_DIR}")

    count = 0
    for path in files:
        filename = os.path.basename(path)
        clef, answer = parse_filename(filename)

        token = str(uuid.uuid4())
        blob = bucket.blob(f"notations/{filename}")
        blob.metadata = {"firebaseStorageDownloadTokens": token}
        blob.upload_from_filename(path, content_type="image/png")

        db.collection("questions").add({
            "clef": clef,
            "correctAnswer": answer,
            "imageUrl": download_url(filename, token),
        })
        count += 1
        print(f"  {filename:<16} -> {answer}")

    print(f"\nDone: seeded {count} questions.")


if __name__ == "__main__":
    main()
