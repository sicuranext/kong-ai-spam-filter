POST http://localhost:8001/services
Host: localhost:8001
Content-Type: application/json
{
    "name": "regression-test",
    "retries": 5,
    "protocol": "https",
    "host": "httpbin.org",
    "port": 443,
    "path": "/anything",
    "connect_timeout": 6000,
    "write_timeout": 6000,
    "read_timeout": 6000,
    "enabled": true
}
HTTP 201
[Captures]
service_id: jsonpath "$['id']"


POST http://localhost:8001/routes
Host: localhost:8001
Content-Type: application/json
{
    "hosts": ["regression-test"],
    "service": {
        "id": "{{ service_id }}"
    },
    "strip_path": false,
    "preserve_host": false
}
HTTP 201
[Captures]
route_id: jsonpath "$['id']"


POST http://localhost:8001/services/{{ service_id }}/plugins
Host: localhost:8001
Content-Type: application/json
{
  "enabled": true,
  "name": "kong-ai-spam-filter",
  "config": {
    "debug": true,
    "temperature": 0.2,
    "request_path_regex": [".*"],
    "api_key_google": "{{GEMINI_API_KEY}}",
    "api_key_openai": "{{OPENAI_API_KEY}}",
    "api_key_anthropic": "{{ANTHROPIC_API_KEY}}",
    "model": "gemini-2.0-flash",
    "action": "block-if-spam-or-error",
    "request_body_regex": [".*"],
    "max_tokens": 300
  }
}

