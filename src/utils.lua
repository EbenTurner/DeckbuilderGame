local utils = {}

-- AABB Collision: Checks if a point (x,y) is inside a rectangle
---@return boolean
function utils.checkMouseCollision(rx, ry, rw, rh)
    local mx, my = love.mouse.getPosition()
    return mx >= rx and mx <= rx + rw and my >= ry and my <= ry + rh
end

return utils