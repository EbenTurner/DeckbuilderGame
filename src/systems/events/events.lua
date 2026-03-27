---@class Event
---@field id string
---@field title string
---@field description string
---@field options Option[]

---@class Option
---@field text string
---@field callback function

local EventDB = {
    ["zombie_corpse"] = {
        title = "A Gruesome Feast",
        description = "You find a zombie hunched over a corpse in the corner, tearing at flesh. It hasn't noticed you yet.",
        options = {
            {
                text = "Sneak by",
                callback = function(ctx)
                    ctx.state:switch("passive")
                end
            },
            {
                text = "Attack",
                callback = function(ctx)
                    local stalker = ctx.enemies:spawn("stalker", ctx.map.current)
                    stalker:exhaust()
                    ctx.state:switch("combat")
                end
            }
        }
    }
}

return EventDB