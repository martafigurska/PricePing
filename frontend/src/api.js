export const BASE_URLS = {
  addProduct: "https://add-product-b432xl5c5a-ew.a.run.app",
  getProducts: "https://get-products-b432xl5c5a-ew.a.run.app",
  checkPrices: "https://europe-west1-priceping-480812.cloudfunctions.net/check-prices",
  deleteProduct: "https://delete-product-b432xl5c5a-ew.a.run.app"
};

export async function addProduct(url, target_price, email) {
  const res = await fetch(BASE_URLS.addProduct, { 
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ url, target_price, email })
  });
  return res.json();
}

export async function getProducts() {
  const res = await fetch(BASE_URLS.getProducts); 
  return res.json();
}

export async function checkPrices() {
  const res = await fetch(BASE_URLS.checkPrices); // Gen1 
  return res.text(); 
}

export async function deleteProduct(id) {
  const res = await fetch(`${BASE_URLS.deleteProduct}?id=${id}`, { method: "DELETE" });
  return res.json();
}
