const BASE_URL = "https://europe-west1-priceping-480812.cloudfunctions.net"; 

export async function addProduct(url, target_price, email) {
  const res = await fetch(`${BASE_URL}/add_product`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ url, target_price, email })
  });
  return res.json();
}

export async function getProducts() {
  const res = await fetch(`${BASE_URL}/get_products`);
  return res.json();
}
