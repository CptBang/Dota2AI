local module = require(GetScriptDirectory().."/helpers")
local bot_generic = require(GetScriptDirectory().."/bot_generic")

local npcBot = GetBot()

function Think()
    bot_generic.Think()
end