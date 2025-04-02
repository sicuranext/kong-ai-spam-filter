local ngx = ngx
local kong = kong
local ngx_re_match = ngx.re.match

local _M = {}

local http  = require "resty.http"
local cjson = require "cjson.safe"
local utils = require "kong.plugins.kong-ai-spam-filter.utils"

_M.system_prompt = [[
You are a spam filter. You'll analyze messages coming from HTML contact forms or API.
Your job is to determine if a user-provided message is spam or not.

# Your instructions
- Analyze each message to determine if it's spam based on content and context.
- Messages containing links aren't automatically spam; evaluate the link's purpose and relevance.
- Messages primarily attempting to sell products/services are usually spam.
- The following are usually NOT spam:
  - Support requests
  - Contact requests
  - Product/service information inquiries
  - Collaboration/partnership proposals
- Label spam messages with one of these categories:
  - "advertising" - promotional content for products/services
  - "phishing" - attempts to collect sensitive information
  - "health" - unsolicited medical/health product promotions
  - "adult" - explicit or inappropriate sexual content
  - "product" - suspicious product offers
  - "dating" - unsolicited dating/relationship solicitations
  - "scam" - deceptive schemes to extract money/information
  - "malware" - attempting to distribute harmful software
  - "other" - spam that doesn't fit above categories

# Output format
Return ONLY a JSON object with this structure:
- For non-spam: { "is_spam": false }
- For spam: { "is_spam": true, "category": "[category]", "reason": "[brief explanation]" }

# Guidelines:
- Keep reason explanations concise and factual
- Avoid special characters in the reason field
- Return only the JSON object without additional text or explanation
]]

---@param plugin_conf table Configuration parameters
---@param user_prompt string Text to send to the LLM
---@return table|nil result Result from the LLM or nil on error
---@return string|nil error Error message if request failed
_M.gemini = function(plugin_conf, user_prompt)
  if not plugin_conf.model then
    plugin_conf.model = "gemini-2.0-flash"
  end

  if not plugin_conf.temperature then
    plugin_conf.temperature = 0.2
  end

  if not plugin_conf.max_tokens then
    plugin_conf.max_tokens = 150
  end

  if not plugin_conf.api_key_google then
    return nil, "Missing API key for Gemini"
  end

  local client = http.new()
  local url = string.format("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", plugin_conf.model, plugin_conf.api_key_google)

  local request_body = {
    contents = {
      {
        parts = {
          {
            text = user_prompt
          }
        }
      }
    },
    systemInstruction = {
      parts = {
        {
          text = _M.system_prompt
        }
      }
    },
    generationConfig = {
      temperature = plugin_conf.temperature,
      maxOutputTokens = plugin_conf.max_tokens
    }
  }

  local json_body = cjson.encode(request_body)

  local res, err = client:request_uri(url, {
    method = "POST",
    body = json_body,
    headers = {
      ["Content-Type"] = "application/json"
    },
    ssl_verify = false
  })

  if not res then
    return nil, "HTTP request failed: " .. (err or "unknown error")
  end

  if res.status ~= 200 then
    return nil, "API request failed with status " .. res.status .. ": " .. (res.body or "")
  end

  kong.log.err("LLM response: ", res.body)

  local success, response_data = pcall(cjson.decode, res.body)
  if not success then
    return nil, "Failed to decode JSON response: " .. (response_data or "unknown error")
  end

  -- Extract the text from the response
  local response_text
  if response_data.candidates and response_data.candidates[1] and
     response_data.candidates[1].content and
     response_data.candidates[1].content.parts and
     response_data.candidates[1].content.parts[1] and
     response_data.candidates[1].content.parts[1].text
  then
    response_text = response_data.candidates[1].content.parts[1].text

    -- remove markdown syntax if any
    response_text = response_text:gsub("```json\n", ""):gsub("\n```", "")

    -- remove all newlines
    response_text = response_text:gsub("\n", "")

    -- remove multiple spaces
    response_text = response_text:gsub("%s+", " ")

    print("Response text: ", response_text)
  else
    return nil, "Unexpected response structure"
  end

  -- Try to decode the response as JSON using pcall for error handling
  local success, result = pcall(cjson.decode, response_text)
  if not success then
    return nil, "Failed to parse LLM response as JSON: " .. (result or "unknown error")
  end

  print("Result: ", tostring(result))
  return result
end

---@param plugin_conf table Configuration parameters
---@param user_prompt string Text to send to the LLM
---@return table|nil result Result from the LLM or nil on error
---@return string|nil error Error message if request failed
_M.gpt = function(plugin_conf, user_prompt)
  if not plugin_conf.model then
    plugin_conf.model = "gpt-4o"
  end

  if not plugin_conf.temperature then
    plugin_conf.temperature = 0.2
  end

  if not plugin_conf.max_tokens then
    plugin_conf.max_tokens = 150
  end

  if not plugin_conf.api_key_openai then
    return nil, "Missing API key for OpenAI"
  end

  local client = http.new()
  local url = "https://api.openai.com/v1/chat/completions"

  local request_body = {
    model = plugin_conf.model,
    messages = {
      {
        role = "system",
        content = _M.system_prompt
      },
      {
        role = "user",
        content = user_prompt
      }
    },
    temperature = plugin_conf.temperature,
    max_tokens = plugin_conf.max_tokens
  }

  local json_body = cjson.encode(request_body)

  local res, err = client:request_uri(url, {
    method = "POST",
    body = json_body,
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer " .. plugin_conf.api_key_openai
    },
    ssl_verify = false
  })

  if not res then
    return nil, "HTTP request failed: " .. (err or "unknown error")
  end

  if res.status ~= 200 then
    return nil, "API request failed with status " .. res.status .. ": " .. (res.body or "")
  end

  kong.log.err("LLM response: ", res.body)

  local success, response_data = pcall(cjson.decode, res.body)
  if not success then
    return nil, "Failed to decode JSON response: " .. (response_data or "unknown error")
  end

  -- Extract the text from the response
  local response_text
  if response_data.choices and response_data.choices[1] and
     response_data.choices[1].message and
     response_data.choices[1].message.content
  then
    response_text = response_data.choices[1].message.content

    -- remove markdown syntax if any
    response_text = response_text:gsub("```json\n", ""):gsub("\n```", "")

    -- remove all newlines
    response_text = response_text:gsub("\n", "")

    -- remove multiple spaces
    response_text = response_text:gsub("%s+", " ")

    print("Response text: ", response_text)
  else
    return nil, "Unexpected response structure"
  end

  -- Try to decode the response as JSON using pcall for error handling
  local success, result = pcall(cjson.decode, response_text)
  if not success then
    return nil, "Failed to parse LLM response as JSON: " .. (result or "unknown error")
  end

  print("Result: ", tostring(result))
  return result
end

---@param plugin_conf table Configuration parameters
---@param user_prompt string Text to send to the LLM
---@return table|nil result Result from the LLM or nil on error
---@return string|nil error Error message if request failed
_M.claude = function(plugin_conf, user_prompt)
  if not plugin_conf.model then
    plugin_conf.model = "claude-3-7-sonnet-latest"
  end

  if not plugin_conf.temperature then
    plugin_conf.temperature = 0.2
  end

  if not plugin_conf.max_tokens then
    plugin_conf.max_tokens = 150
  end

  if not plugin_conf.api_key_anthropic then
    return nil, "Missing API key for Anthropic"
  end

  local client = http.new()
  local url = "https://api.anthropic.com/v1/messages"

  local request_body = {
    model = plugin_conf.model,
    messages = {
      {
        role = "user",
        content = user_prompt
      }
    },
    system = _M.system_prompt,
    temperature = plugin_conf.temperature,
    max_tokens = plugin_conf.max_tokens
  }

  local json_body = cjson.encode(request_body)

  local res, err = client:request_uri(url, {
    method = "POST",
    body = json_body,
    headers = {
      ["Content-Type"] = "application/json",
      ["x-api-key"] = plugin_conf.api_key_anthropic,
      ["anthropic-version"] = "2023-06-01"
    },
    ssl_verify = false
  })

  if not res then
    return nil, "HTTP request failed: " .. (err or "unknown error")
  end

  if res.status ~= 200 then
    return nil, "API request failed with status " .. res.status .. ": " .. (res.body or "")
  end

  kong.log.err("LLM response: ", res.body)

  local success, response_data = pcall(cjson.decode, res.body)
  if not success then
    return nil, "Failed to decode JSON response: " .. (response_data or "unknown error")
  end

  -- Extract the text from the response
  local response_text
  if response_data.content and response_data.content[1] and
     response_data.content[1].text
  then
    response_text = response_data.content[1].text

    -- remove markdown syntax if any
    response_text = response_text:gsub("```json\n", ""):gsub("\n```", "")

    -- remove all newlines
    response_text = response_text:gsub("\n", "")

    -- remove multiple spaces
    response_text = response_text:gsub("%s+", " ")

    print("Response text: ", response_text)
  else
    return nil, "Unexpected response structure"
  end

  -- Try to decode the response as JSON using pcall for error handling
  local success, result = pcall(cjson.decode, response_text)
  if not success then
    return nil, "Failed to parse LLM response as JSON: " .. (result or "unknown error")
  end

  print("Result: ", tostring(result))
  return result
end

---@param plugin_conf table Configuration parameters
---@return table result Result from the LLM indicating if the request is spam
---@return string|nil error Error message if request failed
_M.is_spam = function(plugin_conf)
  local request_body = kong.request.get_raw_body()

  -- Only proceed if path matched
  if not utils.path_match(plugin_conf, kong.request.get_path()) then
    return { is_spam = false }
  end

  -- Only proceed if body matched
  if not utils.body_match(plugin_conf, request_body) then
    return { is_spam = false }
  end

  -- At this point, both path and body matched the regex patterns
  -- Send the request body to the LLM for spam detection
  if not request_body or request_body == "" then
    return { is_spam = false }
  end

  if plugin_conf.prompt_suffix then
    request_body = request_body .. "\n" .. plugin_conf.prompt_suffix
  end

  -- Use Gemini as the default LLM
  local result, err
  result = {}
  if plugin_conf.model:match("^gemini") then
    result, err = _M.gemini(plugin_conf, request_body)
    if err then
      kong.log.err("Error calling Gemini: ", err)
      return { is_spam = false }  -- Default to allowing if Gemini call fails
    end
  elseif plugin_conf.model:match("^gpt") then
    result, err = _M.gpt(plugin_conf, request_body)
    if err then
      kong.log.err("Error calling GPT: ", err)
      return { is_spam = false }  -- Default to allowing if GPT call fails
    end
  elseif plugin_conf.model:match("^claude") then
    result, err = _M.claude(plugin_conf, request_body)
    if err then
      kong.log.err("Error calling Claude: ", err)
      return { is_spam = false }  -- Default to allowing if Claude call fails
    end
  else
    -- Add support for other models here if needed
    return {}, "Unsupported model: " .. plugin_conf.model
  end

  if err then
    kong.log.err("Error calling LLM: ", err)
    return { is_spam = false }  -- Default to allowing if LLM call fails
  end

  return result
end

return _M

