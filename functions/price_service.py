import re
import requests
from urllib.parse import urlparse
from bs4 import BeautifulSoup
from google.cloud import aiplatform
import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    firebase_admin.initialize_app(credentials.ApplicationDefault())

db = firestore.client()

# BeautifulSoup for selected domains
KNOWN_DOMAINS = {
    "amazon.pl",
    "mohito.com",
    "www.mohito.com",
    "jysk.pl",
    "www.jysk.pl"
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
}

PROJECT_ID = "priceping-480812"        
REGION = "europe-west1"   
aiplatform.init(project=PROJECT_ID, location=REGION)


def get_price(url):
    domain = urlparse(url).netloc.lower().replace("www.", "")
    print(f"[BS] known domain: {domain}")
    return get_price_bs(url, domain)
    
    # if domain in KNOWN_DOMAINS:
    #     print(f"[BS] known domain: {domain}")
    #     return get_price_bs(url, domain)
    # else:
    #     print(f"[AI] unknown domain: {domain}")
    #     return get_price_ai(url)
    
def extract_price(text):
    text = text.replace("\xa0", " ").replace(",", ".")
    match = re.search(r"\d+(\.\d+)?", text)
    if not match:
        raise ValueError("Cannot parse price")
    return float(match.group())

def get_price_bs(url, domain):
    response = requests.get(url, headers=HEADERS, timeout=10)
    response.raise_for_status()

    soup = BeautifulSoup(response.text, "lxml")

    # AMAZON
    if domain == "amazon.pl":
        el = soup.select_one(
            "#priceblock_ourprice, "
            "#priceblock_dealprice, "
            "span.a-price > span.a-offscreen"
        )

    # MOHITO
    elif domain == "mohito.com":
        el = soup.select_one(
            "span.price, "
            "span.current-price, "
            "div.product-price span"
        )

    # JYSK
    elif domain == "jysk.pl":
        el = soup.select_one(
            'span[data-testid="product-price"], '
            ".product-price, "
            ".price-value"
        )

    else:
        raise ValueError(f"No scraper for domain: {domain}")

    if not el:
        raise ValueError("Price not found")

    return extract_price(el.get_text(strip=True))

# def get_price_ai(url):
#     html = requests.get(url, headers=HEADERS, timeout=10).text[:12000]

#     prompt = f"""
# Extract the current product price from the HTML below.
# Return ONLY a number (float, no currency symbols).
# HTML:
# {html}
# """

#     model = "text-bison@001"  
#     response = aiplatform.TextGenerationModel(model_name=model).predict(
#         prompt,
#         temperature=0.0,
#         max_output_tokens=50
#     )

#     return float(response.text.strip())




