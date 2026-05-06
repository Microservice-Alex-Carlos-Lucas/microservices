import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const TOKEN = __ENV.TOKEN;

export const options = {
    vus: 10,
    duration: '30s',
    thresholds: {
        http_req_failed: ['rate<0.01'],
        http_req_duration: ['p(95)<500'],
    },
};

export default function () {
    const params = {
        headers: { Cookie: `__store_jwt_token=${TOKEN}` },
    };
    const res = http.get(`${BASE_URL}/products`, params);
    check(res, { 'status 200': (r) => r.status === 200 });
    sleep(1);
}
