#include <drogon/drogon.h>
#include <spdlog/spdlog.h>
#include <json/json.h>

#include "config/Config.h"
#include "utils/Headers.h"

// Included to ensure controller translation units are linked (Drogon
// auto-registers controllers via static initializers on first use).
#include "controllers/FrameworkController.h"
#include "controllers/ThreatController.h"
#include "controllers/AuthController.h"

int main() {
    using namespace cppcitadel;
    using namespace drogon;

    const Config& cfg = Config::get();

    spdlog::set_level(spdlog::level::info);
    spdlog::info("CppCitadel starting on port {}", cfg.httpPort);

    // -----------------------------------------------------------------------
    // Database client — PostgreSQL async pool
    // -----------------------------------------------------------------------
    app().createDbClient(
        "postgresql",
        cfg.dbHost,
        static_cast<unsigned short>(cfg.dbPort),   // Drogon requires unsigned short
        cfg.dbName,
        cfg.dbUser,
        cfg.dbPassword,
        5,          // connection pool size
        "",         // unix socket path (unused for TCP)
        "default"   // client name used by getDbClient()
    );

    // -----------------------------------------------------------------------
    // Pre-send advice: attach security + CORS headers to every response
    // -----------------------------------------------------------------------
    app().registerPreSendingAdvice(
        [](const HttpRequestPtr& /*req*/, const HttpResponsePtr& resp) {
            addSecurityHeaders(resp);
        }
    );

    // -----------------------------------------------------------------------
    // Health endpoint
    // -----------------------------------------------------------------------
    app().registerHandler(
        "/health",
        [](const HttpRequestPtr& /*req*/,
           std::function<void(const HttpResponsePtr&)>&& cb)
        {
            Json::Value body;
            body["status"] = "UP";
            cb(HttpResponse::newHttpJsonResponse(body));
        },
        {Get}
    );

    // -----------------------------------------------------------------------
    // OPTIONS preflight handlers (CORS)
    // Paths with {1} capture a path segment — the handler must accept it.
    // -----------------------------------------------------------------------
    auto options0 = [](const HttpRequestPtr&,
                        std::function<void(const HttpResponsePtr&)>&& cb)
    {
        auto resp = HttpResponse::newHttpResponse();
        resp->setStatusCode(k204NoContent);
        cb(resp);
    };

    auto options1 = [](const HttpRequestPtr&,
                        std::function<void(const HttpResponsePtr&)>&& cb,
                        std::string /*pathParam*/)
    {
        auto resp = HttpResponse::newHttpResponse();
        resp->setStatusCode(k204NoContent);
        cb(resp);
    };

    app().registerHandler("/api/v1/auth/login",       options0, {Options});
    app().registerHandler("/api/v1/frameworks",        options0, {Options});
    app().registerHandler("/api/v1/threats",           options0, {Options});
    app().registerHandler("/api/v1/frameworks/{1}",    options1, {Options});
    app().registerHandler("/api/v1/threats/{1}",       options1, {Options});

    // -----------------------------------------------------------------------
    // Server startup
    // -----------------------------------------------------------------------
    app().setLogLevel(trantor::Logger::kInfo);
    app().addListener("0.0.0.0", cfg.httpPort).run();

    return 0;
}
