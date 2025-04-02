local ngx = ngx
local kong = kong
local ngx_re_match = ngx.re.match

local _M = {}

_M.path_match = function(plugin_conf, request_path)
    local path_match = false

    if plugin_conf.request_path_regex then
        for _, regex in ipairs(plugin_conf.request_path_regex) do
            local match, _ = ngx_re_match(request_path, regex, "jo")
            if match then
                path_match = true
                break
            end
        end
    else
        -- If no path regex configured, consider it a match
        path_match = true
    end

    return path_match
end

_M.body_match = function(plugin_conf, request_body)
    local body_match = false

    if plugin_conf.request_body_regex and request_body then
        for _, regex in ipairs(plugin_conf.request_body_regex) do
            local match, err = ngx_re_match(request_body, regex, "jo")
            if match then
                body_match = true
                break
            end
        end
    else
        -- If no body regex configured, consider it a match
        body_match = true
    end

    return body_match
end

return _M