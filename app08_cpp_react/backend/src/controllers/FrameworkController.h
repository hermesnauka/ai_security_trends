#pragma once

#include <drogon/HttpController.h>

namespace cppcitadel {

class FrameworkController : public drogon::HttpController<FrameworkController> {
public:
    METHOD_LIST_BEGIN
        // ADD_METHOD_TO (not METHOD_ADD) - see AuthController.h for why.
        ADD_METHOD_TO(FrameworkController::getAll,    "/api/v1/frameworks",      drogon::Get);
        ADD_METHOD_TO(FrameworkController::getByCode, "/api/v1/frameworks/{1}",  drogon::Get);
    METHOD_LIST_END

    void getAll(const drogon::HttpRequestPtr& req,
                std::function<void(const drogon::HttpResponsePtr&)>&& callback);

    void getByCode(const drogon::HttpRequestPtr& req,
                   std::function<void(const drogon::HttpResponsePtr&)>&& callback,
                   std::string code);
};

} // namespace cppcitadel
