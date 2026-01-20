import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify
from datetime import datetime
from price_service import get_price
import base64
import json
from google.cloud import pubsub_v1
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from base64 import b64decode
from google.cloud import pubsub_v1

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
    project_id = os.environ.get("PROJECT_ID")
    if not project_id:
        project_id = os.environ.get("GOOGLE_CLOUD_PROJECT")

    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, "send-email")
    payload = request.get_json(silent=True) or {}

    print("Scheduler payload:", payload)

    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(os.environ["PROJECT_ID"], "send-email")

    products = db.collection("products").where("is_active", "==", True).stream()

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

            if price <= target:
                message = {
                    "to": data['email'],
                    "subject": f"Cena spadła dla {data['url']}",
                    "body": f"Cena spadła do {price} zł"
                }
                publisher.publish(topic_path, json.dumps(message).encode("utf-8"))

        except Exception as e:
            print(f"{data['url']} → {e}")

    return "OK", 200

def delete_product(request):
    product_id = request.args.get("id")
    if not product_id:
        return {"error": "Missing id"}, 400

    ref = db.collection("products").document(product_id)
    if not ref.get().exists:
        return {"error": "Not found"}, 404

    ref.delete()
    return {"status": "deleted"}, 200

def send_email(event, context):
    data = json.loads(b64decode(event['data']).decode('utf-8'))

    to_email = data['to']
    subject = data['subject']
    body = data['body']

    gmail_user = os.environ.get("GMAIL_USER")
    gmail_password = os.environ.get("GMAIL_APP_PASSWORD")

    msg = MIMEMultipart()
    msg['From'] = gmail_user
    msg['To'] = to_email
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as server:
        server.login(gmail_user, gmail_password)
        server.send_message(msg)
    
    print(f"Sent email to {to_email}")