import { api, setToken } from "../api-client.js";
import { navigate } from "../router.js";

export function render(container) {
  container.innerHTML = `
    <h1>Login</h1>
    <form id="login-form">
      <label>Username <input type="text" name="username" data-testid="login-username" required /></label>
      <label>Password <input type="password" name="password" data-testid="login-password" required /></label>
      <button type="submit" data-testid="login-submit">Log in</button>
      <p class="error" id="login-error" hidden></p>
    </form>`;

  const form = container.querySelector("#login-form");
  const errorEl = container.querySelector("#login-error");

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const formData = new FormData(form);
    try {
      const result = await api.login(formData.get("username"), formData.get("password"));
      setToken(result.token);
      navigate("/");
    } catch (err) {
      errorEl.textContent = err.message;
      errorEl.hidden = false;
    }
  });
}
