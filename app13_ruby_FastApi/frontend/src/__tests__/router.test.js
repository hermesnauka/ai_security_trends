import { describe, it, expect, beforeEach, vi } from "vitest";

// The router module holds its route table in module-level state (PLAN.md
// D-08's ~30-line router has no reset hook), so each test re-imports a fresh
// module instance rather than sharing routes across examples.
async function freshRouter() {
  vi.resetModules();
  return import("../router.js");
}

describe("router", () => {
  let container;

  beforeEach(() => {
    document.body.innerHTML = '<div id="app"></div>';
    container = document.getElementById("app");
    window.history.replaceState({}, "", "/");
  });

  it("matches a static route and renders it with an empty params object", async () => {
    const { route, navigate } = await freshRouter();
    const view = { render: vi.fn() };
    route("/threats", view);

    navigate("/threats");
    await Promise.resolve();

    expect(view.render).toHaveBeenCalledWith(container, {});
  });

  it("extracts named params from a dynamic segment", async () => {
    const { route, navigate } = await freshRouter();
    const view = { render: vi.fn() };
    route("/threats/:code", view);

    navigate("/threats/A01:2021");
    await Promise.resolve();

    expect(view.render).toHaveBeenCalledWith(container, { code: "A01:2021" });
  });

  it("renders a 404 for a path with no matching route", async () => {
    const { render } = await freshRouter();
    window.history.replaceState({}, "", "/does-not-exist");

    await render();

    expect(container.innerHTML).toContain("404");
  });

  it("navigate() pushes the new path onto history", async () => {
    const { route, navigate } = await freshRouter();
    route("/about", { render: vi.fn() });

    navigate("/about");

    expect(window.location.pathname).toBe("/about");
  });

  it("picks the first matching route when patterns could overlap", async () => {
    const { route, navigate } = await freshRouter();
    const first = { render: vi.fn() };
    const second = { render: vi.fn() };
    route("/threats/:code", first);
    route("/threats/:code", second);

    navigate("/threats/A01:2021");
    await Promise.resolve();

    expect(first.render).toHaveBeenCalled();
    expect(second.render).not.toHaveBeenCalled();
  });

  describe("initRouter", () => {
    it("intercepts a click on a data-nav link and navigates instead of following it", async () => {
      const { route, initRouter } = await freshRouter();
      const view = { render: vi.fn() };
      route("/about", view);
      initRouter();

      container.innerHTML = '<a href="/about" data-nav>About</a>';
      const link = container.querySelector("a");
      const event = new MouseEvent("click", { bubbles: true, cancelable: true });
      link.dispatchEvent(event);
      await Promise.resolve();

      expect(event.defaultPrevented).toBe(true);
      expect(window.location.pathname).toBe("/about");
    });

    it("ignores clicks on links without data-nav", async () => {
      const { route, initRouter } = await freshRouter();
      const view = { render: vi.fn() };
      route("/about", view);
      initRouter();

      container.innerHTML = '<a href="/about">About</a>';
      const link = container.querySelector("a");
      const event = new MouseEvent("click", { bubbles: true, cancelable: true });
      link.dispatchEvent(event);

      expect(event.defaultPrevented).toBe(false);
      expect(view.render).not.toHaveBeenCalled();
    });
  });
});
