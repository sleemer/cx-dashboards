import http from 'k6/http';
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export const options = {
  discardResponseBodies: true,
  scenarios: {
    first_get: {
      exec: 'first_get',
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 20 },
        { duration: '2m', target: 0 },
        { duration: '1m', target: 10 },
        { duration: '1m', target: 0 },
      ],
      gracefulRampDown: '0s',
    },
    first_put: {
      exec: 'first_put',
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '4m', target: 5 },
        { duration: '30s', target: 10 },
        { duration: '30s', target: 0 },
      ],
      gracefulRampDown: '0s',
    },
    second_get: {
      exec: 'second_get',
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 25 },
        { duration: '1m', target: 5 },
        { duration: '1m', target: 15 },
        { duration: '1m', target: 0 },
      ],
      gracefulRampDown: '0s',
    },
    second_put: {
      exec: 'second_put',
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '4m', target: 7 },
        { duration: '30s', target: 15 },
        { duration: '30s', target: 0 },
      ],
      gracefulRampDown: '0s',
    },
  },
};

const firstConsumerHeaders = {
    'X-APP-CUSTOMER': 'first',
}
const secondConsumerHeaders = {
    'X-APP-CUSTOMER': 'second',
}

export function first_get() {
  getDocument(randomIntBetween(1, 100000), firstConsumerHeaders);
}
export function first_put() {
  putDocument(firstConsumerHeaders)
}
export function second_get() {
  getDocument(randomIntBetween(100000, 200000), secondConsumerHeaders);
}
export function second_put() {
  putDocument(secondConsumerHeaders)
}

function getDocument(documentId, headers) {
  const hostName = __ENV.SOME_SERVICE_HOSTNAME || 'localhost';
  const hostPort = __ENV.SOME_SERVICE_HOSTPORT || 8080;
  const url = `http://${hostName}:${hostPort}/api/documents/${documentId}`;
  http.get(url, { headers: headers });
}
function putDocument(headers) {
  const hostName = __ENV.SOME_SERVICE_HOSTNAME || 'localhost';
  const hostPort = __ENV.SOME_SERVICE_HOSTPORT || 8080;
  const url = `http://${hostName}:${hostPort}/api/documents/`;
  const data = { content: "Some document" };
  http.put(url, JSON.stringify(data), { headers: headers });
}