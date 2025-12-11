import { useState, useEffect } from "react";
import { addProduct, getProducts } from "./api";

function App() {
  const [url, setUrl] = useState("");
  const [targetPrice, setTargetPrice] = useState("");
  const [email, setEmail] = useState("");
  const [products, setProducts] = useState([]);

  const fetchProducts = async () => {
    const data = await getProducts();
    setProducts(data);
  };

  const handleAdd = async () => {
    await addProduct(url, parseFloat(targetPrice), email);
    setUrl(""); setTargetPrice(""); setEmail("");
    fetchProducts();
  };

  useEffect(() => { fetchProducts(); }, []);

  return (
    <div style={{ padding: "2rem" }}>
      <h1>Price Ping</h1>
      <input placeholder="Product URL" value={url} onChange={e => setUrl(e.target.value)} />
      <input placeholder="Target Price" type="number" value={targetPrice} onChange={e => setTargetPrice(e.target.value)} />
      <input placeholder="Your Email" value={email} onChange={e => setEmail(e.target.value)} />
      <button onClick={handleAdd}>Add Product</button>

      <h2>Observed Products</h2>
      <ul>
        {products.map(p => (
          <li key={p.id}>{p.url} – target price: {p.target_price} – email: {p.email}</li>
        ))}
      </ul>
    </div>
  );
}

export default App;
