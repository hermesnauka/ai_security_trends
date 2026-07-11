import { describe, it, expect, beforeEach, vi } from "vitest";
import { api, getToken, setToken, clearToken } from "../api-client.js";

function jsonResponse(body, { ok = true, status = 200, statusText = "OK" } = {}) {
  return {
    ok,
    status,
    statusText,
    headers: new Map([["content-type", "application/json"]]),
    json: async () => body,
    text: async () => JSON.stringify(body)
  };
}

describe("token storage", () => {
  beforeEach(() => localStorage.clear());

  it("has no token by default", () => {
    expect(getToken()).toBeNull();
  });

  it("stores and retrieves a token", () => {
    setToken("abc.def.ghi");
    expect(getToken()).toBe("abc.def.ghi");
  });

  it("clears a stored token", () => {
    setToken("abc.def.ghi");
    clearToken();
    expect(getToken()).toBeNull();
  });
});

describe("api request wrapper", () => {
  beforeEach(() => {
    localStorage.clear();
    vi.stubGlobal("fetch", vi.fn());
  });

  it("POSTs login with a JSON body and no Authorization header when unauthenticated", async () => {
    global.fetch.mockResolvedValueOnce(jsonResponse({ token: "t", tokenType: "Bearer", role: "ADMIN" }));

    await api.login("admin", "secret");

    const [url, options] = global.fetch.mock.calls[0];
    expect(url.pathname).toBe("/api/v1/auth/login");
    expect(options.method).toBe("POST");
    expect(JSON.parse(options.body)).toEqual({ username: "admin", password: "secret" });
    expect(options.headers.Authorization).toBeUndefined();
  });

  it("attaches a Bearer Authorization header once a token is stored", async () => {
    setToken("stored-token");
    global.fetch.mockResolvedValueOnce(jsonResponse([]));

    await api.frameworks();

    const [, options] = global.fetch.mock.calls[0];
    expect(options.headers.Authorization).toBe("Bearer stored-token");
  });

  it("drops undefined, null, and empty-string params instead of sending them", async () => {
    global.fetch.mockResolvedValueOnce(jsonResponse({ content: [] }));

    await api.threats({ frameworkCode: "OWASP_WEB", severity: undefined, stride: null, q: "" });

    const [url] = global.fetch.mock.calls[0];
    expect(url.searchParams.get("frameworkCode")).toBe("OWASP_WEB");
    expect(url.searchParams.has("severity")).toBe(false);
    expect(url.searchParams.has("stride")).toBe(false);
    expect(url.searchParams.has("q")).toBe(false);
  });

  it("URL-encodes path segments (e.g. a threat code containing a colon)", async () => {
    global.fetch.mockResolvedValueOnce(jsonResponse({}));

    await api.threat("A01:2021");

    const [url] = global.fetch.mock.calls[0];
    expect(url.pathname).toBe("/api/v1/threats/A01%3A2021");
  });

  it("throws an Error using the response's problem-detail message on a non-2xx status", async () => {
    global.fetch.mockResolvedValueOnce(
      jsonResponse({ message: "Invalid credentials" }, { ok: false, status: 401, statusText: "Unauthorized" })
    );

    await expect(api.login("admin", "wrong")).rejects.toThrow("Invalid credentials");
  });

  it("falls back to statusText when the error body isn't valid JSON", async () => {
    global.fetch.mockResolvedValueOnce({
      ok: false,
      status: 500,
      statusText: "Internal Server Error",
      headers: new Map([["content-type", "text/plain"]]),
      json: async () => {
        throw new SyntaxError("not json");
      },
      text: async () => "oops"
    });

    await expect(api.frameworks()).rejects.toThrow("Internal Server Error");
  });

  it("returns raw text for a non-JSON success response", async () => {
    global.fetch.mockResolvedValueOnce({
      ok: true,
      status: 200,
      statusText: "OK",
      headers: new Map([["content-type", "text/csv"]]),
      json: async () => {
        throw new Error("should not be called");
      },
      text: async () => "code,title\nA01:2021,Broken Access Control"
    });

    const result = await api.threats();
    expect(result).toBe("code,title\nA01:2021,Broken Access Control");
  });
});

describe("exportCsvUrl", () => {
  it("only includes truthy params in the query string", () => {
    const url = api.exportCsvUrl({ frameworkCode: "OWASP_WEB", severity: "", stride: undefined });
    const parsed = new URL(url);
    expect(parsed.pathname).toBe("/api/v1/export/csv");
    expect(parsed.searchParams.get("frameworkCode")).toBe("OWASP_WEB");
    expect(parsed.searchParams.has("severity")).toBe(false);
    expect(parsed.searchParams.has("stride")).toBe(false);
  });

  it("builds a bare path with no query string when no params are given", () => {
    const parsed = new URL(api.exportCsvUrl());
    expect([...parsed.searchParams.keys()]).toEqual([]);
  });
});
