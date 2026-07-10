#include "FrameworkController.h"

#include <drogon/orm/DbClient.h>
#include <json/json.h>
#include <memory>
#include <spdlog/spdlog.h>

#include "models/Models.h"
#include "utils/Headers.h"

namespace cppcitadel {

// ---------------------------------------------------------------------------
// GET /api/v1/frameworks
// ---------------------------------------------------------------------------
void FrameworkController::getAll(
    const drogon::HttpRequestPtr& /*req*/,
    std::function<void(const drogon::HttpResponsePtr&)>&& callback)
{
    // Shared so both success and error lambdas can call it — moving into
    // two separate lambda captures (double-move) is UB.
    auto cb = std::make_shared<decltype(callback)>(std::move(callback));
    auto db = drogon::app().getDbClient();

    db->execSqlAsync(
        "SELECT id::text, code, name, version, description, reference_url "
        "FROM framework ORDER BY name",

        [cb](const drogon::orm::Result& result) {
            Json::Value arr(Json::arrayValue);
            for (const auto& row : result) {
                Framework fw;
                fw.id           = row["id"].as<std::string>();
                fw.code         = row["code"].as<std::string>();
                fw.name         = row["name"].as<std::string>();
                fw.version      = row["version"].as<std::string>();
                fw.description  = row["description"].isNull()
                                      ? "" : row["description"].as<std::string>();
                fw.referenceUrl = row["reference_url"].isNull()
                                      ? "" : row["reference_url"].as<std::string>();
                arr.append(fw.toJson());
            }
            auto resp = drogon::HttpResponse::newHttpJsonResponse(arr);
            addSecurityHeaders(resp);
            (*cb)(resp);
        },

        [cb](const drogon::orm::DrogonDbException& e) {
            spdlog::error("FrameworkController::getAll DB error: {}", e.base().what());
            auto resp = drogon::HttpResponse::newHttpJsonResponse(
                makeError(500, "Internal Server Error", "Internal server error"));
            resp->setStatusCode(drogon::k500InternalServerError);
            addSecurityHeaders(resp);
            (*cb)(resp);
        }
    );
}

// ---------------------------------------------------------------------------
// GET /api/v1/frameworks/{code}
// ---------------------------------------------------------------------------
void FrameworkController::getByCode(
    const drogon::HttpRequestPtr& /*req*/,
    std::function<void(const drogon::HttpResponsePtr&)>&& callback,
    std::string code)
{
    auto cb = std::make_shared<decltype(callback)>(std::move(callback));
    auto db = drogon::app().getDbClient();

    db->execSqlAsync(
        "SELECT id::text, code, name, version, description, reference_url "
        "FROM framework WHERE code = $1",

        [cb, code](const drogon::orm::Result& result) {
            if (result.empty()) {
                auto resp = drogon::HttpResponse::newHttpJsonResponse(
                    makeError(404, "Not Found", "Framework not found: " + code));
                resp->setStatusCode(drogon::k404NotFound);
                addSecurityHeaders(resp);
                (*cb)(resp);
                return;
            }
            const auto& row = result[0];
            Framework fw;
            fw.id           = row["id"].as<std::string>();
            fw.code         = row["code"].as<std::string>();
            fw.name         = row["name"].as<std::string>();
            fw.version      = row["version"].as<std::string>();
            fw.description  = row["description"].isNull()
                                  ? "" : row["description"].as<std::string>();
            fw.referenceUrl = row["reference_url"].isNull()
                                  ? "" : row["reference_url"].as<std::string>();
            auto resp = drogon::HttpResponse::newHttpJsonResponse(fw.toJson());
            addSecurityHeaders(resp);
            (*cb)(resp);
        },

        [cb](const drogon::orm::DrogonDbException& e) {
            spdlog::error("FrameworkController::getByCode DB error: {}", e.base().what());
            auto resp = drogon::HttpResponse::newHttpJsonResponse(
                makeError(500, "Internal Server Error", "Internal server error"));
            resp->setStatusCode(drogon::k500InternalServerError);
            addSecurityHeaders(resp);
            (*cb)(resp);
        },

        code
    );
}

} // namespace cppcitadel
