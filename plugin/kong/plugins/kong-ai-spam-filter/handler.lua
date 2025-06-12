local plugin = {
  PRIORITY = 8110,
  VERSION = "1.0"
}

local llm = require "kong.plugins.kong-ai-spam-filter.llm"
local cjson = require "cjson.safe"

local response_body_replace = function(plugin_conf, result)
  local model = plugin_conf.model

  -- if model is ollama, use the model name
  if model == "ollama" then
    model = plugin_conf.ollama_model
  end

  local response_body_table = {
    message = "Request blocked due to spam detection",
    category = result.category,
    reason = result.reason,
    model = model
  }

  local response_body = cjson.encode(response_body_table)

  if plugin_conf.custom_response_body and plugin_conf.custom_response_body ~= "" then
    -- replace %{result.category} string
    response_body = plugin_conf.custom_response_body:gsub("%%{result%.category}", result.category or "unknown")
    -- replace %{result.reason} string
    response_body = response_body:gsub("%%{result%.reason}", result.reason or "no reason provided")
    -- replace %{plugin_conf.model} string
    response_body = response_body:gsub("%%{plugin_conf%.model}", model)

  end

  return response_body

end

function plugin:access(plugin_conf)
  -- Check if the request is spam
  local result, err = llm.is_spam(plugin_conf)

  if err then
    kong.log.err("Error in spam detection: ", err)
    if plugin_conf.action == "block-if-spam-or-error" then
      -- If an error occurs and the action is block-if-spam-or-error, block the request
      kong.log.err("Blocking request due to error in spam detection")
      return kong.response.exit(500, { message = "Error in spam detection" })
    end

    if plugin_conf.action == "log-if-spam-or-error" then
      -- If an error occurs and the action is log-if-spam-or-error, log the error and continue
      kong.log.err("Error in spam detection: ", err)
    end

    return
  end

  if result then
    -- If debug mode is enabled, add the spam analysis to response headers
    if plugin_conf.debug then
      kong.response.set_header("X-Spam-Analysis", cjson.encode(result))

      -- print model used for spam detection
      kong.response.set_header("X-Spam-Model", plugin_conf.model)
    end

    if result.is_spam  then
      -- If spam is detected, block the request
      kong.log.notice("Spam detected: ", result.category or "unknown", " - ", result.reason or "no reason provided")

      -- Store the result for later phases and debug mode
      kong.ctx.plugin.spam_result = result

      -- Generate the response body
      local response_body = response_body_replace(plugin_conf, result)

      -- response code
      local response_code = plugin_conf.custom_response_code or 403
      local response_content_type = plugin_conf.custom_response_content_type or "application/json"
      local response_cache_control = plugin_conf.custom_response_cache_control or "max-age=0, private, no-store, no-cache, must-revalidate"

      if plugin_conf.action == "block-if-spam-or-error" or plugin_conf.action == "block-if-spam-only" then
        return kong.response.exit(
          response_code,
          response_body,
          {
            ["Content-Type"] = response_content_type,
            ["Cache-Control"] = response_cache_control
          }
        )
      end
    end
  end
end

--function plugin:header_filter(plugin_conf)
--end

return plugin
