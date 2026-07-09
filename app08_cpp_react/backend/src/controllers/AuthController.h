#pragma once

#include <drogon/HttpController.h>

namespace cppcitadel {

class AuthController : public drogon::HttpController<AuthController> {
public:
    METHOD_LIST_BEGIN
        METHOD_ADD(AuthController::login, "/api/v1/auth/login", drogon::Post);
    METHOD_LIST_END

    void login(const drogon::HttpRequestPtr& req,
               std::function<void(const drogon::HttpResponsePtr&)>&& callback);
};

} // namespace cppcitadel
