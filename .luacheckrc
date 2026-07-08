std = "lua51"
max_line_length = false
codes = true
global = false
unused = false
redefined = false
unused_args = false
unused_secondaries = false

-- This addon runs inside WoW's Lua environment. Keep the CI pass focused on
-- parse errors without requiring every FrameXML global or callback-shaped local
-- to be listed here.
ignore = {
    "111", -- setting non-standard global variables such as slash aliases
    "113", -- accessing WoW/FrameXML globals
    "143", -- accessing fields on WoW objects with dynamic shapes
    "212", -- unused arguments used for WoW callback signatures
    "213", -- unused loop variables
}

globals = {
    "Nexus",
    "NexusDB",
}
