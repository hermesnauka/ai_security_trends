#pragma once

#include <json/json.h>
#include <string>
#include <vector>
#include <cmath>
#include <chrono>
#include <format>

namespace cppcitadel {

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// UTC, millisecond precision - matches Java's Instant.now().toString(),
// which is the shape app01 (the contract of record) actually emits.
inline std::string nowIso8601() {
    using namespace std::chrono;
    auto ms = time_point_cast<milliseconds>(system_clock::now());
    return std::format("{:%FT%T}Z", ms);
}

// Canonical error body: {timestamp, status, error, message} - see
// app01's ApiExceptionHandler.java. `error` is the HTTP reason phrase
// (e.g. "Not Found"), not a machine-readable error code.
inline Json::Value makeError(int status, const std::string& error, const std::string& message) {
    Json::Value v;
    v["timestamp"] = nowIso8601();
    v["status"]    = status;
    v["error"]     = error;
    v["message"]   = message;
    return v;
}

inline std::vector<std::string> splitComma(const std::string& s) {
    std::vector<std::string> result;
    if (s.empty()) return result;
    std::string token;
    for (char c : s) {
        if (c == ',') {
            if (!token.empty()) {
                result.push_back(token);
                token.clear();
            }
        } else {
            token += c;
        }
    }
    if (!token.empty()) result.push_back(token);
    return result;
}

// ---------------------------------------------------------------------------
// Framework
// ---------------------------------------------------------------------------

struct Framework {
    std::string id;
    std::string code;
    std::string name;
    std::string version;
    std::string description;
    std::string referenceUrl;

    Json::Value toJson() const {
        Json::Value v;
        v["id"]           = id;
        v["code"]         = code;
        v["name"]         = name;
        v["version"]      = version;
        v["description"]  = description;
        v["referenceUrl"] = referenceUrl;
        return v;
    }
};

// ---------------------------------------------------------------------------
// ThreatSummary
// ---------------------------------------------------------------------------

struct ThreatSummary {
    std::string              id;
    std::string              frameworkCode;
    std::string              code;
    std::string              title;
    std::string              severity;
    std::string              category;
    std::vector<std::string> stride;
    std::vector<std::string> tags;

    Json::Value toJson() const {
        Json::Value v;
        v["id"]            = id;
        v["frameworkCode"] = frameworkCode;
        v["code"]          = code;
        v["title"]         = title;
        v["severity"]      = severity;
        v["category"]      = category;

        Json::Value strideArr(Json::arrayValue);
        for (const auto& s : stride) strideArr.append(s);
        v["stride"] = strideArr;

        Json::Value tagsArr(Json::arrayValue);
        for (const auto& t : tags) tagsArr.append(t);
        v["tags"] = tagsArr;

        return v;
    }
};

// ---------------------------------------------------------------------------
// ThreatDetail  (extends ThreatSummary)
// ---------------------------------------------------------------------------

struct ThreatDetail : ThreatSummary {
    std::string              frameworkName;
    std::string              description;
    std::string              attackVector;
    std::string              attackSurface;
    std::vector<std::string> cveReferences;

    Json::Value toJson() const {
        Json::Value v = ThreatSummary::toJson();
        v["frameworkName"]  = frameworkName;
        v["description"]    = description;
        v["attackVector"]   = attackVector;
        v["attackSurface"]  = attackSurface;

        Json::Value cveArr(Json::arrayValue);
        for (const auto& c : cveReferences) cveArr.append(c);
        v["cveReferences"] = cveArr;

        return v;
    }
};

// ---------------------------------------------------------------------------
// Page envelope  (Spring Data shape)
// ---------------------------------------------------------------------------

// `items` must already be exactly one page's worth of rows (SQL-side
// LIMIT/OFFSET) - `totalElements` is the count of the full filtered set,
// from a separate COUNT query, not items.size().
template<typename T>
Json::Value makePage(const std::vector<T>& items, long long totalElements, int page, int size) {
    int totalPages = (size > 0) ? static_cast<int>(std::ceil(
                          static_cast<double>(totalElements) / size)) : 0;

    Json::Value content(Json::arrayValue);
    for (const auto& item : items) {
        content.append(item.toJson());
    }

    Json::Value result;
    result["content"]       = content;
    result["totalElements"] = totalElements;
    result["totalPages"]    = totalPages;
    result["number"]        = page;
    result["size"]          = size;
    return result;
}

} // namespace cppcitadel
