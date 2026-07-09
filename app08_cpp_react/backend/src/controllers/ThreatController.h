#pragma once

#include <drogon/HttpController.h>

namespace cppcitadel {

class ThreatController : public drogon::HttpController<ThreatController> {
public:
    METHOD_LIST_BEGIN
        METHOD_ADD(ThreatController::listThreats, "/api/v1/threats",     drogon::Get);
        METHOD_ADD(ThreatController::getThreat,   "/api/v1/threats/{1}", drogon::Get);
    METHOD_LIST_END

    void listThreats(const drogon::HttpRequestPtr& req,
                     std::function<void(const drogon::HttpResponsePtr&)>&& callback);

    void getThreat(const drogon::HttpRequestPtr& req,
                   std::function<void(const drogon::HttpResponsePtr&)>&& callback,
                   std::string id);
};

} // namespace cppcitadel
