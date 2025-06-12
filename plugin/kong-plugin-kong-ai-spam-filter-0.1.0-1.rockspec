package = "kong-plugin-kong-ai-spam-filter"
version = "0.1.0-1"

local pluginName = package:match("^kong%-plugin%-(.+)$")

supported_platforms = {"linux"}
source = {
  url = "https://github.com/sicuranext/kong-ai-spam-filter",
  tag = "main"
}

description = {
  summary = "Kong Plugin to filter out spam messages using AI"
}

dependencies = {
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
    ["kong.plugins."..pluginName..".llm"] = "kong/plugins/"..pluginName.."/llm.lua",
    ["kong.plugins."..pluginName..".utils"] = "kong/plugins/"..pluginName.."/utils.lua",
  }
}
