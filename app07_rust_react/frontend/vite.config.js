import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
export default defineConfig({
    plugins: [react()],
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src'),
        },
    },
    server: {
        port: 5173,
        proxy: {
            // dev-server convenience only; production routing to the backend is
            // handled by the reverse-proxy nginx container (see ../nginx/nginx.conf)
            '/api/v1': {
                target: 'http://localhost:8080',
                changeOrigin: true,
            },
        },
    },
});
