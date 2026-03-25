local EquipmentDB = require("src.systems.equipment.equipment")
local UI = require("src.ui.renderer")

---@class EquipmentManager
---@field equipment table<string, Equipment|nil>
---@field _instance_counter integer
---@field slot_hitboxes table<string, table<string, number>>
---@field selected_slot_id string
local EquipmentManager = {
    equipment = {},
    _instance_counter = 0
}

---@return Equipment?, integer
-- function EquipmentManager:getSelectedEquipment()
--     return self:getCard(self.selected_idx), self.selected_idx
-- end

function EquipmentManager:initialize(ctx)
    -- Create a standard starter set: to be replaced later
    self:equip("longsword", ctx.deck)
    self:equip("shield", ctx.deck)
end

---@param id string
---@param deck DeckManager
function EquipmentManager:equip(id, deck)
    local template = EquipmentDB:get(id)
    assert(template, "No equipment associated with template for id: " .. id)

    self._instance_counter = self._instance_counter + 1

    local instance = {
        instanceId = self._instance_counter,
        spawned_cards = {},
    }
    setmetatable(instance, { __index = template })

    if instance.slot == "hand" then
        if not self.equipment.hand1 then
            self.equipment.hand1 = instance
        elseif not self.equipment.hand2 then
            self.equipment.hand2 = instance
        else
            -- Auto-replace hand1 if full
            self.equipment:unequip(self.equipment.hand1, deck)
            self.equipment.hand1 = instance
        end
    elseif instance.slot == "two_hand" then
        -- Auto replace anything currently in hands
        self.equipment:unequip(self.equipment.hand1, deck)
        self.equipment:unequip(self.equipment.hand2, deck)
        self.equipment.hand1 = instance
        self.equipment.hand2 = instance
    end

    if template.granted_cards then
        for _, cardId in ipairs(template.granted_cards) do
            local cardInstance = deck:addCard(cardId)
            table.insert(instance.spawned_cards, cardInstance) -- Store the instance of the card for unequipping
        end
    end
end

---@param equipment Equipment
---@param deck DeckManager
function EquipmentManager:unequip(equipment, deck)
    if not equipment then return end

    for _, card in ipairs(equipment.spawned_cards) do
        deck:removeCard(card)
    end
end

---@param ctx Context
function EquipmentManager:draw(ctx)
    UI.drawEquipment(ctx)
end

return EquipmentManager