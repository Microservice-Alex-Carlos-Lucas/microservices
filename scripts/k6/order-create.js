import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const TOKEN = __ENV.TOKEN;
const PRODUCT_ID = __ENV.PRODUCT_ID; // exporte um ID antes de rodar

// Exercita o caminho mais caro: order → product (Feign) + order → exchange
// (Feign) + exchange → AwesomeAPI. Demonstra o ganho do cache de
// exchange-rates do Lucas (Bottleneck 4 do spec).
export const options = {
    vus: 50,
    duration: '60s',
};

const payload = JSON.stringify({
    currency: 'BRL',
    items: [{ productId: PRODUCT_ID, quantity: 1 }],
});

export default function () {
    const params = {
        headers: {
            'Content-Type': 'application/json',
            Cookie: `__store_jwt_token=${TOKEN}`,
        },
    };
    const res = http.post(`${BASE_URL}/orders`, payload, params);
    check(res, {
        'order created': (r) => r.status === 201 || r.status === 200,
    });
}
