import { useEffect, useState } from "react";

/** Empty = same origin (Ingress routes /api to backend). */
const apiBase = (import.meta.env.VITE_API_BASE_URL || "").replace(/\/$/, "");

export default function App() {
  const [health, setHealth] = useState(null);
  const [users, setUsers] = useState([]);
  const [error, setError] = useState("");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");

  const load = async () => {
    setError("");
    try {
      const h = await fetch(`${apiBase}/api/health`);
      setHealth(await h.json());
      const u = await fetch(`${apiBase}/api/users`);
      const data = await u.json();
      setUsers(data.users || []);
    } catch (e) {
      setError(String(e.message));
    }
  };

  useEffect(() => {
    load();
  }, []);

  const addUser = async (e) => {
    e.preventDefault();
    setError("");
    try {
      const res = await fetch(`${apiBase}/api/users`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, email }),
      });
      if (!res.ok) {
        const j = await res.json().catch(() => ({}));
        throw new Error(j.error || res.statusText);
      }
      setName("");
      setEmail("");
      await load();
    } catch (e) {
      setError(String(e.message));
    }
  };

  return (
    <div style={{ maxWidth: 720, margin: "0 auto", padding: "2.5rem 1.25rem" }}>
      <header style={{ marginBottom: "2rem" }}>
        <p style={{ color: "#94a3b8", margin: 0, fontSize: "0.85rem" }}>
          Kubernetes · Helm · CI/CD
        </p>
        <h1 style={{ margin: "0.25rem 0 0", fontSize: "1.85rem" }}>
          DevOps Demo App
        </h1>
      </header>

      <section
        style={{
          background: "rgba(15, 23, 42, 0.65)",
          border: "1px solid rgba(148, 163, 184, 0.2)",
          borderRadius: 12,
          padding: "1.25rem 1.5rem",
          marginBottom: "1.25rem",
        }}
      >
        <h2 style={{ margin: "0 0 0.75rem", fontSize: "1.1rem" }}>API health</h2>
        {health ? (
          <pre
            style={{
              margin: 0,
              overflow: "auto",
              fontSize: "0.85rem",
              color: "#cbd5e1",
            }}
          >
            {JSON.stringify(health, null, 2)}
          </pre>
        ) : (
          <p style={{ color: "#94a3b8" }}>Loading…</p>
        )}
      </section>

      <section
        style={{
          background: "rgba(15, 23, 42, 0.65)",
          border: "1px solid rgba(148, 163, 184, 0.2)",
          borderRadius: 12,
          padding: "1.25rem 1.5rem",
        }}
      >
        <h2 style={{ margin: "0 0 0.75rem", fontSize: "1.1rem" }}>Users</h2>
        <form
          onSubmit={addUser}
          style={{
            display: "grid",
            gap: "0.75rem",
            marginBottom: "1rem",
          }}
        >
          <input
            placeholder="Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
            style={{
              padding: "0.6rem 0.75rem",
              borderRadius: 8,
              border: "1px solid #334155",
              background: "#0f172a",
              color: "#f1f5f9",
            }}
          />
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            style={{
              padding: "0.6rem 0.75rem",
              borderRadius: 8,
              border: "1px solid #334155",
              background: "#0f172a",
              color: "#f1f5f9",
            }}
          />
          <button
            type="submit"
            style={{
              padding: "0.65rem 1rem",
              borderRadius: 8,
              border: "none",
              background: "#0ea5e9",
              color: "#0f172a",
              fontWeight: 600,
              cursor: "pointer",
            }}
          >
            Add user
          </button>
        </form>
        {error ? (
          <p style={{ color: "#f87171", marginTop: 0 }}>{error}</p>
        ) : null}
        <ul style={{ paddingLeft: "1.1rem", margin: 0, color: "#cbd5e1" }}>
          {users.map((u) => (
            <li key={u.id} style={{ marginBottom: "0.35rem" }}>
              {u.name} — {u.email}
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}
