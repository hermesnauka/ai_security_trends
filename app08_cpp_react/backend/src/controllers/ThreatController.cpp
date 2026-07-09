#include "ThreatController.h"

#include <drogon/orm/DbClient.h>
#include <json/json.h>
#include <memory>
#include <spdlog/spdlog.h>

#include <string>
#include <vector>
#include <functional>

#include "models/Models.h"
#include "utils/Headers.h"

namespace cppcitadel {

// ---------------------------------------------------------------------------
// Helper: parse optional query param
// ---------------------------------------------------------------------------
static std::string qparam(const drogon::HttpRequestPtr& req, const std::string& name) {
    auto val = req->getOptionalParameter<std::string>(name);
    return val.value_or("");
}

// ---------------------------------------------------------------------------
// Helper: map a result row to ThreatSummary
// ---------------------------------------------------------------------------
static ThreatSummary rowToSummary(const drogon::orm::Row& row) {
    ThreatSummary t;
    t.id            = row["id"].as<std::string>();
    t.frameworkCode = row["framework_code"].as<std::string>();
    t.code          = row["code"].as<std::string>();
    t.title         = row["title"].as<std::string>();
    t.severity      = row["severity"].as<std::string>();
    t.category      = row["category"].isNull() ? "" : row["category"].as<std::string>();
    t.stride        = splitComma(row["stride"].isNull() ? "" : row["stride"].as<std::string>());
    t.tags          = splitComma(row["tags"].isNull()   ? "" : row["tags"].as<std::string>());
    return t;
}

// ---------------------------------------------------------------------------
// GET /api/v1/threats
// ---------------------------------------------------------------------------
void ThreatController::listThreats(
    const drogon::HttpRequestPtr& req,
    std::function<void(const drogon::HttpResponsePtr&)>&& callback)
{
    const std::string frameworkCode = qparam(req, "frameworkCode");
    const std::string severity      = qparam(req, "severity");
    const std::string strideFilter  = qparam(req, "stride");
    const std::string tagFilter     = qparam(req, "tag");
    const std::string q             = qparam(req, "q");

    int page = 0;
    int size = 20;
    {
        auto pStr = req->getOptionalParameter<std::string>("page");
        auto sStr = req->getOptionalParameter<std::string>("size");
        try { if (pStr) page = std::stoi(*pStr); } catch (...) {}
        try { if (sStr) size = std::stoi(*sStr); } catch (...) {}
        if (page < 0) page = 0;
        if (size < 1 || size > 200) size = 20;
    }

    // Build dynamic WHERE clause with positional $N parameters.
    // We collect string param values in order and build SQL accordingly.
    std::string sql =
        "SELECT t.id::text, f.code AS framework_code, t.code, t.title, "
        "       t.severity, t.category, t.stride, t.tags "
        "FROM threat t "
        "JOIN framework f ON f.id = t.framework_id "
        "WHERE 1=1 ";

    std::vector<std::string> params;

    if (!frameworkCode.empty()) {
        params.push_back(frameworkCode);
        sql += " AND f.code = $" + std::to_string(params.size());
    }
    if (!severity.empty()) {
        params.push_back(severity);
        sql += " AND t.severity = $" + std::to_string(params.size());
    }
    if (!strideFilter.empty()) {
        params.push_back("%" + strideFilter + "%");
        sql += " AND t.stride LIKE $" + std::to_string(params.size());
    }
    if (!tagFilter.empty()) {
        params.push_back("%" + tagFilter + "%");
        sql += " AND t.tags LIKE $" + std::to_string(params.size());
    }
    if (!q.empty()) {
        params.push_back("%" + q + "%");
        std::string pn = "$" + std::to_string(params.size());
        sql += " AND (t.title ILIKE " + pn + " OR t.description ILIKE " + pn + ")";
    }

    sql += " ORDER BY t.severity, t.code";

    // Drogon execSqlAsync supports up to ~7 variadic bind params via templates.
    // We handle 0-5 params with explicit overloads to avoid template-count limits.
    // (For > 5 filters we would use the SqlBinder API; this covers typical use.)

    // Shared to avoid double-move UB when both success and error lambdas need callback.
    auto cb = std::make_shared<decltype(callback)>(std::move(callback));

    auto handleResult = [cb, page, size](const drogon::orm::Result& result) {
        std::vector<ThreatSummary> threats;
        threats.reserve(result.size());
        for (const auto& row : result) {
            threats.push_back(rowToSummary(row));
        }
        auto pageJson = makePage(threats, page, size);
        auto resp = drogon::HttpResponse::newHttpJsonResponse(pageJson);
        addSecurityHeaders(resp);
        (*cb)(resp);
    };

    auto handleError = [cb](const drogon::orm::DrogonDbException& e) {
        spdlog::error("ThreatController::listThreats DB error: {}", e.base().what());
        Json::Value err;
        err["status"]  = 500;
        err["message"] = "Internal server error";
        auto resp = drogon::HttpResponse::newHttpJsonResponse(err);
        resp->setStatusCode(drogon::k500InternalServerError);
        addSecurityHeaders(resp);
        (*cb)(resp);
    };

    auto db = drogon::app().getDbClient();

    // Dispatch by number of bound parameters (0-5)
    const std::size_t n = params.size();
    if (n == 0) {
        db->execSqlAsync(sql, std::move(handleResult), std::move(handleError));
    } else if (n == 1) {
        db->execSqlAsync(sql, std::move(handleResult), std::move(handleError),
                         params[0]);
    } else if (n == 2) {
        db->execSqlAsync(sql, std::move(handleResult), std::move(handleError),
                         params[0], params[1]);
    } else if (n == 3) {
        db->execSqlAsync(sql, std::move(handleResult), std::move(handleError),
                         params[0], params[1], params[2]);
    } else if (n == 4) {
        db->execSqlAsync(sql, std::move(handleResult), std::move(handleError),
                         params[0], params[1], params[2], params[3]);
    } else {
        // 5 or more — use at most 5 (we have at most 5 filters defined above)
        db->execSqlAsync(sql, std::move(handleResult), std::move(handleError),
                         params[0], params[1], params[2], params[3], params[4]);
    }
}

// ---------------------------------------------------------------------------
// GET /api/v1/threats/{id}
// ---------------------------------------------------------------------------
void ThreatController::getThreat(
    const drogon::HttpRequestPtr& /*req*/,
    std::function<void(const drogon::HttpResponsePtr&)>&& callback,
    std::string id)
{
    auto cb = std::make_shared<decltype(callback)>(std::move(callback));
    auto db = drogon::app().getDbClient();

    db->execSqlAsync(
        "SELECT t.id::text, f.code AS framework_code, f.name AS framework_name, "
        "       t.code, t.title, t.severity, t.category, t.description, "
        "       t.attack_vector, t.attack_surface, t.stride, t.tags, t.cve_references "
        "FROM threat t "
        "JOIN framework f ON f.id = t.framework_id "
        "WHERE t.id::text = $1",

        [cb, id](const drogon::orm::Result& result) {
            if (result.empty()) {
                Json::Value err;
                err["status"]  = 404;
                err["message"] = "Threat not found: " + id;
                auto resp = drogon::HttpResponse::newHttpJsonResponse(err);
                resp->setStatusCode(drogon::k404NotFound);
                addSecurityHeaders(resp);
                (*cb)(resp);
                return;
            }

            const auto& row = result[0];
            ThreatDetail td;
            td.id            = row["id"].as<std::string>();
            td.frameworkCode = row["framework_code"].as<std::string>();
            td.frameworkName = row["framework_name"].as<std::string>();
            td.code          = row["code"].as<std::string>();
            td.title         = row["title"].as<std::string>();
            td.severity      = row["severity"].as<std::string>();
            td.category      = row["category"].isNull()       ? "" : row["category"].as<std::string>();
            td.description   = row["description"].isNull()    ? "" : row["description"].as<std::string>();
            td.attackVector  = row["attack_vector"].isNull()  ? "" : row["attack_vector"].as<std::string>();
            td.attackSurface = row["attack_surface"].isNull() ? "" : row["attack_surface"].as<std::string>();
            td.stride        = splitComma(row["stride"].isNull() ? "" : row["stride"].as<std::string>());
            td.tags          = splitComma(row["tags"].isNull()   ? "" : row["tags"].as<std::string>());
            td.cveReferences = splitComma(row["cve_references"].isNull()
                                              ? "" : row["cve_references"].as<std::string>());

            auto resp = drogon::HttpResponse::newHttpJsonResponse(td.toJson());
            addSecurityHeaders(resp);
            (*cb)(resp);
        },

        [cb](const drogon::orm::DrogonDbException& e) {
            spdlog::error("ThreatController::getThreat DB error: {}", e.base().what());
            Json::Value err;
            err["status"]  = 500;
            err["message"] = "Internal server error";
            auto resp = drogon::HttpResponse::newHttpJsonResponse(err);
            resp->setStatusCode(drogon::k500InternalServerError);
            addSecurityHeaders(resp);
            (*cb)(resp);
        },

        id
    );
}

} // namespace cppcitadel
