FROM openresty/openresty:1.25.3.1-0-alpine-fat

RUN apk add --no-cache postgresql-dev build-base git \
  && luarocks install lapis \
  && luarocks install pgmoon \
  && luarocks install lua-resty-jwt \
  && luarocks install lyaml \
  && luarocks install bcrypt \
  && luarocks install lua-resty-limit-traffic

WORKDIR /app
COPY . .

EXPOSE 9292
CMD ["sh", "-c", "lua scripts/db_migrate.lua && lua scripts/db_seed.lua && ADMIN_PASSWORD=${ADMIN_PASSWORD:-changeme} lua scripts/db_seed_admin.lua && openresty -p /app -c nginx.conf -g 'daemon off;'"]
