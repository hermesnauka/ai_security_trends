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
    // OPTIONS preflight (CORS): short-circuit before routing, for every path.
    // A per-path app().registerHandler(path, ..., {Options}) was tried here
    // instead, using the exact same path strings as each controller's
    // METHOD_ADD - Drogon does not merge the two registrations' methods for
    // an identical path, so it silently made GET/POST return 405 on every
    // real endpoint (confirmed by actually running the binary; not visible
    // from reading the code). registerPreRoutingAdvice runs before routing
    // ever sees the request, so it can't collide with a controller's routes.
    // -----------------------------------------------------------------------
    app().registerPreRoutingAdvice(
        [](const HttpRequestPtr& req,
           AdviceCallback&& acb,
           AdviceChainCallback&& accb)
        {
            if (req->method() == Options) {
                auto resp = HttpResponse::newHttpResponse();
                resp->setStatusCode(k204NoContent);
                acb(resp);
                return;
            }
            accb();
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
    // Server startup
    // -----------------------------------------------------------------------
    app().setLogLevel(trantor::Logger::kInfo);
    app().addListener("0.0.0.0", cfg.httpPort).run();

    return 0;
}
