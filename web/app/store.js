
const API_BASE_URL = "http://localhost:8080";

const register = async () => {
    const name = document.getElementById("name").value;
    const email = document.getElementById("email").value;
    const password = document.getElementById("password").value;

    const response = await fetch(`${API_BASE_URL}/api/accounts`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            name,
            email,
            password
        })
    });

    if (response.ok) {
        alert("Account created successfully!");
    } else {
        alert("Failed to create account.");
    }
}