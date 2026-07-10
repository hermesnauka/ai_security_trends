#pragma once

#include <drogon/HttpController.h>

namespace cppcitadel {

class AuthController : public drogon::HttpController<AuthController> {
public:
    METHOD_LIST_BEGIN
        // ADD_METHOD_TO (not METHOD_ADD) - METHOD_ADD prepends the fully
        // qualified class name to the path (Drogon's default RESTful-style
        // convention), which silently breaks every literal contract path
        // below; confirmed by actually running the binary and finding the
        // handlers live at /cppcitadel/AuthController/api/v1/auth/login etc.
        ADD_METHOD_TO(AuthController::login, "/api/v1/auth/login", drogon::Post);
    METHOD_LIST_END

    void login(const drogon::HttpRequestPtr& req,
               std::function<void(const drogon::HttpResponsePtr&)>&& callback);
};

} // namespace cppcitadel
