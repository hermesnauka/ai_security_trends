#pragma once

#include <cstdlib>
#include <string>

namespace cppcitadel {

struct Config {
    std::string dbHost;
    int         dbPort;
    std::string dbName;
    std::string dbUser;
    std::string dbPassword;
    int         httpPort;
    std::string jwtSecret;
    int         jwtExpirationHours;
    std::string adminUsername;
    std::string adminPasswordHash;

    static const Config& get() {
        static Config instance = load();
        return instance;
    }

private:
    static std::string env(const char* name, const char* defaultValue) {
        const char* val = std::getenv(name);
        return (val && *val) ? std::string(val) : std::string(defaultValue);
    }

    static int envInt(const char* name, int defaultValue) {
        const char* val = std::getenv(name);
        if (val && *val) {
            try { return std::stoi(val); } catch (...) {}
        }
        return defaultValue;
    }

    static Config load() {
        Config c;
        c.dbHost             = env("DB_HOST",               "127.0.0.1");
        c.dbPort             = envInt("DB_PORT",            5432);
        c.dbName             = env("DB_NAME",               "cppcitadel");
        c.dbUser             = env("DB_USER",               "cppcitadel");
        c.dbPassword         = env("DB_PASSWORD",           "cppcitadel");
        c.httpPort           = envInt("HTTP_PORT",          8080);
        c.jwtSecret          = env("JWT_SECRET",            "dev-only-secret-CHANGE-IN-PRODUCTION-min32");
        c.jwtExpirationHours = envInt("JWT_EXPIRATION_HOURS", 8);
        c.adminUsername      = env("ADMIN_USERNAME",        "admin");
        c.adminPasswordHash  = env("ADMIN_PASSWORD_HASH",
            "$2a$10$VsjBojBm5B6FIDsmrvqUS.lopvpAwPvl3WFDEMX4zd95X2cKtswz6");
        return c;
    }
};

} // namespace cppcitadel
