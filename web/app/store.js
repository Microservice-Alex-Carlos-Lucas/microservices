
const API_BASE_URL = "http://localhost:8080";

// ── Cookie helpers ────────────────────────────────────────────────────────────

function setCookie(name, value, days = 1) {
    const expires = new Date(Date.now() + days * 864e5).toUTCString();
    document.cookie = `${name}=${encodeURIComponent(value)}; expires=${expires}; path=/; SameSite=Lax`;
}

function getCookie(name) {
    const match = document.cookie
        .split("; ")
        .find(row => row.startsWith(name + "="));
    return match ? decodeURIComponent(match.split("=")[1]) : null;
}

function deleteCookie(name) {
    document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/`;
}

function getToken() {
    return getCookie("token");
}

function logout() {
    deleteCookie("token");
    window.location.href = "login.html";
}

// ── Auth ──────────────────────────────────────────────────────────────────────

const login = async () => {
    const email    = document.getElementById("email").value.trim();
    const password = document.getElementById("password").value;

    if (!email || !password) {
        showError("Preencha email e senha.");
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/auth/login`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email, password })
        });

        if (response.ok) {
            const data = await response.json();
            setCookie("token", data.token);
            window.location.href = "index.html";
        } else {
            showError("Email ou senha incorretos.");
        }
    } catch (e) {
        showError("Erro de conexão: " + e.message);
    }
};

const register = async () => {
    const name     = document.getElementById("name").value.trim();
    const email    = document.getElementById("email").value.trim();
    const password = document.getElementById("password").value;

    if (!name || !email || !password) {
        showError("Preencha todos os campos.");
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/auth/register`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ name, email, password })
        });

        if (response.ok) {
            window.location.href = "login.html";
        } else {
            showError("Falha ao criar conta.");
        }
    } catch (e) {
        showError("Erro de conexão: " + e.message);
    }
};

// ── UI helper (used by login.html and register.html) ─────────────────────────

function showError(msg) {
    const el = document.getElementById("error-msg");
    if (el) {
        el.textContent = msg;
        el.style.display = "block";
    } else {
        alert(msg);
    }
}
