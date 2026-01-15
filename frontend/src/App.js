import { useState, useEffect } from "react";
import { addProduct, getProducts, deleteProduct } from "./api"; // <- import poprawny

function App() {
  const [url, setUrl] = useState("");
  const [targetPrice, setTargetPrice] = useState("");
  const [email, setEmail] = useState("");
  const [products, setProducts] = useState([]);

  const fetchProducts = async () => {
    const data = await getProducts(); // <- korzysta z poprawnego BASE_URLS.getProducts
    setProducts(data);
  };

  const handleAdd = async () => {
    await addProduct(url, parseFloat(targetPrice), email); // <- poprawny URL Gen2
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
      <table style={{ width: "100%", borderCollapse: "collapse", marginTop: "1rem" }}>
        <thead>
          <tr style={{ borderBottom: "2px solid #333" }}>
            <th style={{ textAlign: "left", padding: "0.5rem", maxWidth: "300px" }}>URL</th>
            <th style={{ textAlign: "right", padding: "0.5rem" }}>Target Price</th>
            <th style={{ textAlign: "left", padding: "0.5rem" }}>Email</th>
            <th style={{ textAlign: "right", padding: "0.5rem" }}>Last Price</th>
            <th style={{ textAlign: "left", padding: "0.5rem" }}>Checked At</th>
            <th style={{ textAlign: "left", padding: "0.5rem" }}>Stop Observing</th>
          </tr>
        </thead>
        <tbody>
          {products.map(p => {
            const isBelow = p.last_price !== null && p.last_price <= p.target_price;
            return (
              <tr key={p.id} style={{ backgroundColor: isBelow ? "#d4edda" : "transparent" }}>
                <td style={{ padding: "0.5rem", wordBreak: "break-word" }}>{p.url}</td>
                <td style={{ padding: "0.5rem", textAlign: "right" }}>{p.target_price}</td>
                <td style={{ padding: "0.5rem" }}>{p.email}</td>
                <td style={{ padding: "0.5rem", textAlign: "right" }}>{p.last_price ?? "-"}</td>
                <td style={{ padding: "0.5rem" }}>{p.checked_at ?? "-"}</td>
                <td style={{ padding: "0.5rem" }}>
                  <button
                    style={{ padding: "0.25rem 0.5rem", cursor: "pointer" }}
                    onClick={async () => {
                      try {
                        await deleteProduct(p.id); // <- używa poprawnego API Gen2
                        fetchProducts(); // odśwież tabelkę
                      } catch (err) {
                        console.error("Delete failed", err);
                      }
                    }}
                  >
                    Delete
                  </button>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

export default App;
