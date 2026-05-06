import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const TOKEN = __ENV.TOKEN;

// Ramp 1 → 200 VUs em 2min, hold 1min — força CPU acima de 50% e dispara
// o HPA do gateway (target=50%, min=1, max=5).
export const options = {
    stages: [
        { duration: '2m', target: 200 },
        { duration: '1m', target: 200 },
        { duration: '30s', target: 0 },
    ],
    thresholds: {
        http_req_failed: ['rate<0.05'],
    },
};

export default function () {
    const params = {
        headers: { Cookie: `__store_jwt_token=${TOKEN}` },
    };
    // health-check é open route — bate só no gateway, não no auth/db
    const res = http.get(`${BASE_URL}/health-check`, params);
    check(res, { 'status 200': (r) => r.status === 200 });
}
