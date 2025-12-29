import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify
from datetime import datetime
from price_service import get_price

if not firebase_admin._apps:
    firebase_admin.initialize_app(credentials.ApplicationDefault())

db = firestore.client()

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
}

def handle_cors(request):
    if request.method == "OPTIONS":
        return ("", 204, CORS_HEADERS)
    return None

def add_product(request):
    cors = handle_cors(request)
    if cors:
        return cors

    data = request.get_json(silent=True) or {}

    url = data.get("url")
    email = data.get("email")
    target_price = data.get("target_price")

    if not url or not email or target_price is None:
        return jsonify({"error": "Missing fields"}), 400, CORS_HEADERS

    try:
        target_price = float(target_price)
    except ValueError:
        return jsonify({"error": "Target price must be a number"}), 400, CORS_HEADERS

    doc_ref = db.collection("products").add({
        "url": url,
        "email": email,
        "target_price": target_price,
        "last_price": None,
        "checked_at": firestore.SERVER_TIMESTAMP,
        "is_active": True
    })

    return jsonify({"id": doc_ref[1].id}), 200, CORS_HEADERS

def get_products(request):
    cors = handle_cors(request)
    if cors:
        return cors

    products = []
    for doc in db.collection("products").stream():
        item = doc.to_dict()
        item["id"] = doc.id
        # konwersja timestamp na datę
        if "checked_at" in item and isinstance(item["checked_at"], firestore.SERVER_TIMESTAMP.__class__):
            item["checked_at"] = item["checked_at"].isoformat()
        products.append(item)

    return jsonify(products), 200, CORS_HEADERS

def check_prices(request):
    products = db.collection("products") \
                 .where("is_active", "==", True) \
                 .stream()

    for doc in products:
        data = doc.to_dict()

        try:
            price = get_price(data["url"])
            target = data["target_price"]

            update = {
                "last_price": price,
                "checked_at": firestore.SERVER_TIMESTAMP,
                "price_below_target": price <= target
            }
            doc.reference.update(update)

        except Exception as e:
            print(f"{data['url']} → {e}")

    return "OK", 200

