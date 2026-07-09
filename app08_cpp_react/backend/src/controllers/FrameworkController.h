#pragma once

#include <drogon/HttpController.h>

namespace cppcitadel {

class FrameworkController : public drogon::HttpController<FrameworkController> {
public:
    METHOD_LIST_BEGIN
        METHOD_ADD(FrameworkController::getAll,    "/api/v1/frameworks",      drogon::Get);
        METHOD_ADD(FrameworkController::getByCode, "/api/v1/frameworks/{1}",  drogon::Get);
    METHOD_LIST_END

    void getAll(const drogon::HttpRequestPtr& req,
                std::function<void(const drogon::HttpResponsePtr&)>&& callback);

    void getByCode(const drogon::HttpRequestPtr& req,
                   std::function<void(const drogon::HttpResponsePtr&)>&& callback,
                   std::string code);
};

} // namespace cppcitadel
