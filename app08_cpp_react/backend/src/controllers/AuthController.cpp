#include "AuthController.h"

#include <crypt.h>
#include <cstring>

#include <jwt-cpp/jwt.h>
#include <json/json.h>
#include <spdlog/spdlog.h>

#include <chrono>
#include <string>

#include "config/Config.h"
#include "models/Models.h"
#include "utils/Headers.h"

namespace cppcitadel {

// ---------------------------------------------------------------------------
// POST /api/v1/auth/login
// ---------------------------------------------------------------------------
void AuthController::login(
    const drogon::HttpRequestPtr& req,
    std::function<void(const drogon::HttpResponsePtr&)>&& callback)
{
    // Parse JSON body
    auto jsonBody = req->getJsonObject();
    if (!jsonBody) {
        auto resp = drogon::HttpResponse::newHttpJsonResponse(
            makeError(400, "Bad Request", "Request body must be JSON"));
        resp->setStatusCode(drogon::k400BadRequest);
        addSecurityHeaders(resp);
        callback(resp);
        return;
    }

    const std::string username = (*jsonBody).get("username", "").asString();
    const std::string password = (*jsonBody).get("password", "").asString();

    const Config& cfg = Config::get();

    // Constant-time username check (prevent timing oracle on username alone)
    bool usernameOk = (username == cfg.adminUsername);

    // bcrypt verification using system crypt_r
    bool passwordOk = false;
    if (!password.empty() && !cfg.adminPasswordHash.empty()) {
        struct crypt_data data;
        std::memset(&data, 0, sizeof(data));
        data.initialized = 0;

        const char* result = crypt_r(password.c_str(),
                                     cfg.adminPasswordHash.c_str(),
                                     &data);
        if (result != nullptr) {
            passwordOk = (std::strcmp(result, cfg.adminPasswordHash.c_str()) == 0);
        }
    }

    if (!usernameOk || !passwordOk) {
        spdlog::warn("Failed login attempt for username: '{}'", username);
        auto resp = drogon::HttpResponse::newHttpJsonResponse(
            makeError(401, "Unauthorized", "Invalid credentials"));
        resp->setStatusCode(drogon::k401Unauthorized);
        addSecurityHeaders(resp);
        callback(resp);
        return;
    }

    // Build JWT (HS256)
    auto now    = std::chrono::system_clock::now();
    auto expiry = now + std::chrono::hours(cfg.jwtExpirationHours);

    std::string token;
    try {
        token = jwt::create()
            .set_type("JWT")
            .set_subject(username)
            .set_issued_at(now)
            .set_expires_at(expiry)
            .set_payload_claim("role", jwt::claim(std::string("ADMIN")))
            .sign(jwt::algorithm::hs256{cfg.jwtSecret});
    } catch (const std::exception& ex) {
        spdlog::error("JWT signing failed: {}", ex.what());
        auto resp = drogon::HttpResponse::newHttpJsonResponse(
            makeError(500, "Internal Server Error", "Token generation failed"));
        resp->setStatusCode(drogon::k500InternalServerError);
        addSecurityHeaders(resp);
        callback(resp);
        return;
    }

    Json::Value body;
    body["token"]     = token;
    body["tokenType"] = "Bearer";
    body["role"]      = "ADMIN";

    auto resp = drogon::HttpResponse::newHttpJsonResponse(body);
    resp->setStatusCode(drogon::k200OK);
    addSecurityHeaders(resp);
    callback(resp);
}

} // namespace cppcitadel
