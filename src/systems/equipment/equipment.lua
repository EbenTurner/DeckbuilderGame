
local EquipmentDB = {}

---@class Equipment
---@field id string
---@field instanceId integer?               Unique id for a specific card instance
---@field name string
---@field slot "hand" | nil?                TODO: add more as I add more assets
---@field description string
---@field granted_cards string[]?           Cards added to the deck by this equipment
---@field spawned_cards Card[]?             The instances of cards that have been added by this equipment
---@field transforms table<string, string>? Maps old cards to replacements e.g. with weapons

---@param data Equipment
---@return Equipment
function EquipmentDB.create(data)
    local card = {
        id          = data.id,
        name        = data.name,
        slot        = data.slot        or nil,
        description = data.description,
        transforms  = data.transforms,
        granted_cards = data.granted_cards
    }
    return card
end


EquipmentDB.library = {
    longsword = EquipmentDB.create({
        id = "longsword",
        name = "Longsword",
        slot = "hand",
        description = "A trusty sword. Improves attack action, grants 3 new offensive cards.",
        transforms = { attack = "slice" },
        granted_cards = { "cleave", "overhead_slash", "rush_attack" },
    }),

    shield = EquipmentDB.create({
        id = "shield",
        name = "Shield",
        slot = "hand",
        description = "A worn shield. Grants 2 new defensive cards.",
        granted_cards = { "defend", "shield_bash" },
    })
}

---@param id string
---@return Equipment
function EquipmentDB:get(id)
    local equipment = self.library[id]
    assert(equipment, "Could not find equipment in library with id: " .. tostring(id))

    return equipment
end

return EquipmentDB