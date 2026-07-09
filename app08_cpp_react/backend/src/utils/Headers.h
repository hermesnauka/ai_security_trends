#pragma once

#include <drogon/HttpResponse.h>

namespace cppcitadel {

inline void addSecurityHeaders(const drogon::HttpResponsePtr& resp) {
    resp->addHeader("Content-Security-Policy",
        "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; "
        "img-src 'self' data:; font-src 'self'; connect-src 'self'");
    resp->addHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
    resp->addHeader("X-Frame-Options",           "DENY");
    resp->addHeader("X-Content-Type-Options",    "nosniff");
    resp->addHeader("Access-Control-Allow-Origin",
        "*");
    resp->addHeader("Access-Control-Allow-Methods",
        "GET, POST, PUT, DELETE, OPTIONS");
    resp->addHeader("Access-Control-Allow-Headers",
        "Content-Type, Authorization, X-Requested-With");
    resp->addHeader("Access-Control-Max-Age", "86400");
}

} // namespace cppcitadel
