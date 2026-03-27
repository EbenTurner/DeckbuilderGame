local State = require("src.states.state")
local UI = require("src.ui.renderer")
local EventDB = require("src.systems.events.events")

---@class EventState : State
---@field data Event
---@field win table<string, integer>
---@field btn table<string, integer>
local EventState = setmetatable({}, { __index = State })
EventState.__index = EventState

---@return EventState
function EventState:new(ctx)
    local instance = State.new(self, ctx, "event")
    ---@cast instance EventState

    return instance
end

---@param params table
function EventState:enter(params)
    local event_data = EventDB[params.id]
    assert(event_data, "No event data found for id: ".. params.id)

    self.data = EventDB[params.id]
    self.selected_option = 1

    local sw, sh = love.graphics.getDimensions()

    -- Window dimensions
    self.win = {
        w = 400,
        h = 300,
        x = (sw / 2) - 200, -- Centered X
        y = (sh / 2) - 150  -- Centered Y
    }

    -- Button Dimensions
    self.btn = {
        w = 200,
        h = 40,
        spacing = 10, -- Space between buttons
        startY = self.win.y + 150 -- Where the first button starts inside the window
    }
end

function EventState:mousepressed(x, y, button)
    if button ~= 1 then return end

    local bx = self.win.x + (self.win.w / 2) - (self.btn.w / 2)

    for i, option in ipairs(self.data.options) do
        local by = self.btn.startY + (i - 1) * (self.btn.h + self.btn.spacing)
        if Utils.checkMouseCollision(bx, by, self.btn.w, self.btn.h) then
            option.callback(self.ctx)
            break
        end
    end
end

function EventState:draw(ctx)
    love.graphics.setColor(0, 0, 0, 0.7)

    -- 1. Draw Window (The Parchment)
    love.graphics.setColor(0.7, 0.6, 0.4) -- Brownish parchment color
    love.graphics.rectangle("fill", self.win.x, self.win.y, self.win.w, self.win.h)

    -- 2. Draw Text (Description)
    love.graphics.setColor(0.1, 0.1, 0.1) -- Dark ink color
    love.graphics.printf(self.data.description, self.win.x + 20, self.win.y + 50, self.win.w - 40, "center")

    -- 3. Draw Buttons
    local bx = self.win.x + (self.win.w / 2) - (self.btn.w / 2)
    for i, option in ipairs(self.data.options) do
        local by = self.btn.startY + (i - 1) * (self.btn.h + self.btn.spacing)

        -- Hover Effect
        if Utils.checkMouseCollision(bx, by, self.btn.w, self.btn.h) then
            love.graphics.setColor(0.9, 0.8, 0.5) -- Highlight color
        else
            love.graphics.setColor(0.4, 0.3, 0.2) -- Default button color
        end

        love.graphics.rectangle("fill", bx, by, self.btn.w, self.btn.h)

        -- Button Text
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(option.text, bx, by + 10, self.btn.w, "center")
    end

    love.graphics.setColor(1, 0, 0, 0.5) -- Semi-transparent red
    for i = 1, #self.data.options do
        local by = self.btn.startY + (i - 1) * (self.btn.h + self.btn.spacing)
        love.graphics.rectangle("line", bx, by, self.btn.w, self.btn.h)
    end
end

return EventState