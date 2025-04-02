GET http://localhost:8001/services
Host: regression-test
HTTP 200
[Captures]
service_id: jsonpath "$['data'][0]['id']"

GET http://localhost:8001/services/{{ service_id }}/plugins
Host: regression-test
HTTP 200
[Captures]
plugin_id: jsonpath "$['data'][0]['id']"
plugin_config: jsonpath "$['data'][0]['config']"

PATCH http://localhost:8001/services/{{ service_id }}/plugins/{{ plugin_id }}
Host: regression-test
Content-Type: application/json
```
{
  "enabled": true,
  "name": "kong-ai-spam-filter",
  "config": {
    "debug": true,
    "temperature": 0.2,
    "action": "block-if-spam-or-error",
    "request_path_regex": ["^/test.*"],
    "request_body_regex": [".*message[=].*"]
  }
}
```
HTTP 200
[Asserts]
jsonpath "$['config']['request_path_regex'][0]" == "^/test.*"
jsonpath "$['config']['request_body_regex'][0]" == ".*message[=].*"

POST http://localhost:8000/test
Host: regression-test
Content-Type: application/x-www-form-urlencoded
`message=hello, are you interested in training at low costs? Visit our website traninglowcost dot com.`
HTTP 403
[Asserts]
jsonpath "$['message']" == "Request blocked due to spam detection"

POST http://localhost:8000/ignored
Host: regression-test
Content-Type: application/x-www-form-urlencoded
`message=hello, are you interested in training at low costs? Visit our website traninglowcost dot com.`
HTTP 200
[Asserts]
jsonpath "$['form']['message']" == "hello, are you interested in training at low costs? Visit our website traninglowcost dot com."

PATCH http://localhost:8001/services/{{ service_id }}/plugins/{{ plugin_id }}
Host: regression-test
Content-Type: application/json
```
{
  "enabled": true,
  "name": "kong-ai-spam-filter",
  "config": {
    "debug": true,
    "temperature": 0.2,
    "action": "block-if-spam-or-error",
    "request_path_regex": [".*"],
    "request_body_regex": [".*"]
  }
}
```


