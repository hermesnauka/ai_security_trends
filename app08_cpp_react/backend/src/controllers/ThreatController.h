#pragma once

#include <drogon/HttpController.h>

namespace cppcitadel {

class ThreatController : public drogon::HttpController<ThreatController> {
public:
    METHOD_LIST_BEGIN
        // ADD_METHOD_TO (not METHOD_ADD) - see AuthController.h for why.
        ADD_METHOD_TO(ThreatController::listThreats, "/api/v1/threats",     drogon::Get);
        ADD_METHOD_TO(ThreatController::getThreat,   "/api/v1/threats/{1}", drogon::Get);
    METHOD_LIST_END

    void listThreats(const drogon::HttpRequestPtr& req,
                     std::function<void(const drogon::HttpResponsePtr&)>&& callback);

    void getThreat(const drogon::HttpRequestPtr& req,
                   std::function<void(const drogon::HttpResponsePtr&)>&& callback,
                   std::string id);
};

} // namespace cppcitadel
