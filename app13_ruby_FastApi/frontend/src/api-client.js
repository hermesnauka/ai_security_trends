// Thin fetch() wrapper — matches PLAN.md §7's API contract exactly. Every
// query-param key here is camelCase to match what the Grape backend expects
// (`frameworkCode`, not `framework_code`) — the wire format, not Ruby's own
// snake_case convention.

const BASE_URL = ""; // same-origin in dev (Nginx proxies /api/*) and in prod

const TOKEN_KEY = "rubyguard.token";

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token) {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

async function request(path, { method = "GET", params, body } = {}) {
  const url = new URL(BASE_URL + path, window.location.origin);
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== "") url.searchParams.set(key, value);
    });
  }

  const headers = { "Content-Type": "application/json" };
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  const response = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined
  });

  if (!response.ok) {
    const problem = await response.json().catch(() => ({ message: response.statusText }));
    throw new Error(problem.message || `Request to ${path} failed with ${response.status}`);
  }

  const contentType = response.headers.get("content-type") || "";
  return contentType.includes("application/json") ? response.json() : response.text();
}

export const api = {
  login: (username, password) => request("/api/v1/auth/login", { method: "POST", body: { username, password } }),
  frameworks: () => request("/api/v1/frameworks"),
  framework: (code) => request(`/api/v1/frameworks/${encodeURIComponent(code)}`),
  threats: (params) => request("/api/v1/threats", { params }),
  threat: (code) => request(`/api/v1/threats/${encodeURIComponent(code)}`),
  cards: (params) => request("/api/v1/cards", { params }),
  card: (cardId) => request(`/api/v1/cards/${encodeURIComponent(cardId)}`),
  mitigationsForThreat: (threatCode) => request(`/api/v1/mitigations/${encodeURIComponent(threatCode)}`),
  llmMatrix: () => request("/api/v1/matrix/llm"),
  strideHeatmap: () => request("/api/v1/matrix/stride-heatmap"),
  search: (q, locale) => request("/api/v1/search", { params: { q, locale } }),
  exportCsvUrl: (params) => {
    const url = new URL("/api/v1/export/csv", window.location.origin);
    Object.entries(params || {}).forEach(([key, value]) => value && url.searchParams.set(key, value));
    return url.toString();
  }
};
