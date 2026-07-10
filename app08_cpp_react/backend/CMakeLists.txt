cmake_minimum_required(VERSION 3.15)
project(cppcitadel CXX)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Drogon REQUIRED)
find_package(jwt-cpp REQUIRED)
find_package(spdlog REQUIRED)
# jwt-cpp is JSON-library-agnostic since 0.6+: it needs an explicit traits
# type (see AuthController.cpp). Boost::json is used for that since Boost is
# already pulled in transitively by Drogon - no new dependency needed.
find_package(Boost REQUIRED)

add_executable(cppcitadel
    src/main.cpp
    src/controllers/FrameworkController.cpp
    src/controllers/ThreatController.cpp
    src/controllers/AuthController.cpp
)
target_include_directories(cppcitadel PRIVATE src)
target_link_libraries(cppcitadel PRIVATE Drogon::Drogon jwt-cpp::jwt-cpp spdlog::spdlog Boost::json crypt)
