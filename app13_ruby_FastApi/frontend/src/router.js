// A ~30-line History-API router — the entire "framework" this frontend has
// (PLAN.md D-08). Each route maps a path pattern to a view module exposing
// one `render(container, params)` function; that's the whole convention.

const routes = [];

export function route(pattern, viewModule) {
  const paramNames = [];
  const regex = new RegExp(
    "^" +
      pattern.replace(/:[^/]+/g, (match) => {
        paramNames.push(match.slice(1));
        return "([^/]+)";
      }) +
      "$"
  );
  routes.push({ regex, paramNames, viewModule });
}

export function navigate(path) {
  window.history.pushState({}, "", path);
  render();
}

export async function render() {
  const path = window.location.pathname;
  const container = document.getElementById("app");
  const match = routes.find((r) => r.regex.test(path));

  if (!match) {
    container.innerHTML = "<p>404</p>";
    return;
  }

  const values = match.regex.exec(path).slice(1);
  const params = Object.fromEntries(match.paramNames.map((name, i) => [name, values[i]]));
  await match.viewModule.render(container, params);
}

export function initRouter() {
  window.addEventListener("popstate", render);
  document.addEventListener("click", (event) => {
    const link = event.target.closest("a[data-nav]");
    if (!link) return;
    event.preventDefault();
    navigate(link.getAttribute("href"));
  });
}
