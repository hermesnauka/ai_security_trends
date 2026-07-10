#include "ThreatController.h"

#include <drogon/orm/DbClient.h>
#include <drogon/orm/SqlBinder.h>
#include <json/json.h>
#include <memory>
#include <spdlog/spdlog.h>

#include <string>
#include <vector>
#include <functional>
#include <unordered_map>
#include <cctype>

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
// Helper: resolve the `sort` query param into a safe ORDER BY clause.
// `sort` is user input and, unlike a value, a column name/direction can't be
// bound through a $N placeholder - so it's resolved through this fixed
// allowlist instead of ever touching the SQL text directly. Anything not on
// the allowlist (unknown field, bad direction, or absent) falls back to the
// existing default order, same as how page/size already degrade below.
// ---------------------------------------------------------------------------
static std::string resolveOrderBy(const std::string& sortParam) {
    static const std::unordered_map<std::string, std::string> kSortableColumns = {
        {"id",       "t.id"},
        {"code",     "t.code"},
        {"title",    "t.title"},
        {"severity", "t.severity"},
        {"category", "t.category"},
    };
    static const std::string kDefault = " ORDER BY t.severity, t.code";

    if (sortParam.empty()) return kDefault;

    const auto comma = sortParam.find(',');
    const std::string field = sortParam.substr(0, comma);
    std::string dir = (comma == std::string::npos) ? "asc" : sortParam.substr(comma + 1);
    for (char& c : dir) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));

    const auto col = kSortableColumns.find(field);
    if (col == kSortableColumns.end() || (dir != "ASC" && dir != "DESC")) {
        return kDefault;
    }
    return " ORDER BY " + col->second + " " + dir + ", t.code";
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
    const std::string sortParam     = qparam(req, "sort");

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

    // WHERE clause + its bind params are shared by the count query and the
    // page query below, so the reported total always matches the filtered set.
    std::string whereClause = "WHERE 1=1 ";
    std::vector<std::string> params;

    if (!frameworkCode.empty()) {
        params.push_back(frameworkCode);
        whereClause += " AND f.code = $" + std::to_string(params.size());
    }
    if (!severity.empty()) {
        params.push_back(severity);
        whereClause += " AND t.severity = $" + std::to_string(params.size());
    }
    if (!strideFilter.empty()) {
        params.push_back("%" + strideFilter + "%");
        whereClause += " AND t.stride LIKE $" + std::to_string(params.size());
    }
    if (!tagFilter.empty()) {
        params.push_back("%" + tagFilter + "%");
        whereClause += " AND t.tags LIKE $" + std::to_string(params.size());
    }
    if (!q.empty()) {
        params.push_back("%" + q + "%");
        std::string pn = "$" + std::to_string(params.size());
        whereClause += " AND (t.title ILIKE " + pn + " OR t.description ILIKE " + pn + ")";
    }

    const std::string countSql =
        "SELECT count(*) AS total FROM threat t "
        "JOIN framework f ON f.id = t.framework_id " + whereClause;

    // LIMIT/OFFSET are bound params too, appended right after the filter
    // params, instead of string-concatenated - Postgres coerces the
    // unknown-typed text bind to bigint from the LIMIT/OFFSET position.
    std::vector<std::string> dataParams = params;
    dataParams.push_back(std::to_string(size));
    dataParams.push_back(std::to_string(page * size));
    const std::string limitParam  = "$" + std::to_string(dataParams.size() - 1);
    const std::string offsetParam = "$" + std::to_string(dataParams.size());

    const std::string dataSql =
        "SELECT t.id::text, f.code AS framework_code, t.code, t.title, "
        "       t.severity, t.category, t.stride, t.tags "
        "FROM threat t "
        "JOIN framework f ON f.id = t.framework_id " +
        whereClause + resolveOrderBy(sortParam) +
        " LIMIT " + limitParam + " OFFSET " + offsetParam;

    // Shared to avoid double-move UB when both success and error lambdas need callback.
    auto cb = std::make_shared<decltype(callback)>(std::move(callback));
    auto db = drogon::app().getDbClient();

    auto handleError = [cb](const drogon::orm::DrogonDbException& e) {
        spdlog::error("ThreatController::listThreats DB error: {}", e.base().what());
        auto resp = drogon::HttpResponse::newHttpJsonResponse(
            makeError(500, "Internal Server Error", "Internal server error"));
        resp->setStatusCode(drogon::k500InternalServerError);
        addSecurityHeaders(resp);
        (*cb)(resp);
    };

    // Count the filtered set, then fetch just the requested page - the same
    // two-query shape Spring Data's Page<T> uses, instead of pulling every
    // matching row into memory and slicing it locally. Both queries use the
    // SqlBinder streaming interface (`<<`/`>>`) rather than execSqlAsync's
    // templated overloads, since the bind-param count here is dynamic (up to
    // 5 filters + 2 pagination params) and not fixed at compile time.
    auto countBinder = *db << countSql;
    for (const auto& p : params) countBinder << p;
    countBinder >> [db, dataSql, dataParams, page, size, cb, handleError]
                     (const drogon::orm::Result& countResult) {
        const long long totalElements = countResult[0]["total"].as<long long>();

        auto dataBinder = *db << dataSql;
        for (const auto& p : dataParams) dataBinder << p;
        dataBinder >> [totalElements, page, size, cb](const drogon::orm::Result& result) {
            std::vector<ThreatSummary> threats;
            threats.reserve(result.size());
            for (const auto& row : result) {
                threats.push_back(rowToSummary(row));
            }
            auto resp = drogon::HttpResponse::newHttpJsonResponse(
                makePage(threats, totalElements, page, size));
            addSecurityHeaders(resp);
            (*cb)(resp);
        } >> handleError;
    } >> handleError;
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
                auto resp = drogon::HttpResponse::newHttpJsonResponse(
                    makeError(404, "Not Found", "Threat not found: " + id));
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
            auto resp = drogon::HttpResponse::newHttpJsonResponse(
                makeError(500, "Internal Server Error", "Internal server error"));
            resp->setStatusCode(drogon::k500InternalServerError);
            addSecurityHeaders(resp);
            (*cb)(resp);
        },

        id
    );
}

} // namespace cppcitadel
