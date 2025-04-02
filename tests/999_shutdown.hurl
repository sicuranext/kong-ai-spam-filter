GET http://localhost:8001/services
Host: localhost:8001
HTTP 200
[Captures]
services: jsonpath "$['data'][0]['id']"

GET http://localhost:8001/services/{{ services }}/routes
Host: localhost:8001
HTTP 200
[Captures]
routes: jsonpath "$['data'][0]['id']"

DELETE http://localhost:8001/routes/{{ routes }}
Host: localhost:8001
HTTP 204

DELETE http://localhost:8001/services/{{ services }}
Host: localhost:8001
HTTP 204