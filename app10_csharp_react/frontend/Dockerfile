FROM node:20-alpine AS build
WORKDIR /build
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:1.27-alpine
COPY --from=build /build/dist /usr/share/nginx/html
# nginx.conf is bind-mounted by docker-compose.yml (../nginx/nginx.conf), not
# baked in here, so the proxy config can be edited without a rebuild.
EXPOSE 80
