local typedefs = require "kong.db.schema.typedefs"

-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local request_path_regex_description = [[
  A list of regex patterns to match the request path against.
  If the request path matches any of the patterns, the plugin will run.
]]

local request_body_regex_description = [[
  A list of regex patterns to match the request body against.
  If the request body matches any of the patterns, the plugin will run.
]]

local prompt_suffix_description = [[
  Additional instructions to the system prompt.
]]

local model_description = [[
  The model to use for generating the response.
  The available models are:
  - gpt-4o: The full GPT-4 model.
  - gpt-4o-mini: A smaller version of the GPT-4 model.
  - gemini-2.0-flash: The Gemini 2.0 model.
  - claude-3-7-sonnet-latest: The Claude 3.7 model.
]]

local temperature_description = [[
  Controls randomness in the model's output.
  Lower values (e.g., 0.2) make the output more focused and deterministic.
  Higher values (e.g., 0.8) make the output more random and creative.
]]

local max_tokens_description = [[
  The maximum number of tokens that the model can generate in its response.
  For spam detection, a smaller value like 150 is usually sufficient.
]]

local api_key_openai_description = [[
  The API key for OpenAI's GPT models.
  Required if using gpt-4o or gpt-4o-mini models.
]]

local api_key_google_description = [[
  The API key for Google's Gemini models.
  Required if using gemini-2.0-flash model.
]]

local api_key_anthropic_description = [[
  The API key for Anthropic's Claude models.
  Required if using claude-3-7-sonnet-latest model.
]]

local debug_description = [[
  When enabled, additional debugging information will be logged.
  Useful for troubleshooting but should be disabled in production.
]]

local action_description = [[
  The action to take when spam is detected.
  - block-if-spam-or-error: Block the request if spam is detected or an error occurs.
  - block-if-spam-only: Block the request only if spam is detected.
  - log-if-spam-or-error: Log the request if spam is detected or an error occurs.
  - log-if-spam-only: Log the request only if spam is detected.
]]

local custom_response_code_description = [[
  HTTP status code to return when blocking a request.
  Common values: 403 (Forbidden), 429 (Too Many Requests), 400 (Bad Request).
]]

local custom_response_body_description = [[
  Template for the response body when blocking a request.
  Variables can be used with %{variable_name} syntax.
  Available variables: result.category, result.reason, plugin_conf.model.
]]

local custom_response_content_type_description = [[
  Content-Type header to return with the response.
  Common values: application/json, text/plain, text/html.
]]

local custom_response_cache_control_description = [[
  Cache-Control header to return with the response.
  Default ensures the response is not cached by browsers or proxies.
]]

local default_response_body = [[{
  "message": "Request blocked due to spam detection",
  "category": "%{result.category}",
  "reason": "%{result.reason}",
  "model": "%{plugin_conf.model}"
}]]

local schema = {
  name = plugin_name,
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { request_path_regex = {type = "array", elements = { type = "string" }, description = request_path_regex_description } },
          { request_body_regex = {type = "array", elements = { type = "string" }, description = request_body_regex_description } },
          { prompt_suffix = { type = "string", description = prompt_suffix_description } },
          { model = { type = "string", default = "gpt-4o-mini", one_of = {
                                                                  "gpt-4o",
                                                                  "gpt-4o-mini",
                                                                  "gemini-2.0-flash",
                                                                  "claude-3-7-sonnet-latest"
                                                                },
            description = model_description } },
          { temperature = { type = "number", default = 0.2, description = temperature_description } },
          { max_tokens = { type = "number", default = 150, description = max_tokens_description } },
          { api_key_openai = { type = "string", description = api_key_openai_description } },
          { api_key_google = { type = "string", description = api_key_google_description } },
          { api_key_anthropic = { type = "string", description = api_key_anthropic_description } },
          { action = { type = "string", default = "block-if-spam-only", one_of = {
                                                                          "block-if-spam-or-error",
                                                                          "block-if-spam-only",
                                                                          "log-if-spam-or-error",
                                                                          "log-if-spam-only"
                                                                        },
            description = action_description } },
          { custom_response_code = { type = "number", default = 403, description = custom_response_code_description } },
          { custom_response_body = { type = "string", default = default_response_body, description = custom_response_body_description } },
          { custom_response_content_type = { type = "string", default = "application/json", description = custom_response_content_type_description } },
          { custom_response_cache_control = { type = "string", default = "max-age=0, private, no-store, no-cache, must-revalidate", description = custom_response_cache_control_description } },
          { debug = { type = "boolean", default = false, description = debug_description } },
        },
        entity_checks = {
        },
      },
    },
  },
}

return schema
