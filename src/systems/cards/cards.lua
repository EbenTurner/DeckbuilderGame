
local CardDB = {}

---@class Card
---@field id string
---@field instanceId integer? -- Unique id for a specific card instance
---@field name string
---@field type "EVENT"|"ASSET"
---@field slot "weapon"?   -- add more as I add more assets
---@field description string
---@field targeted boolean?
---@field cost number?
---@field actionCost number?
---@field damage number?
---@field effect function?  -- assets generally don't have instant effects
---@field transforms table<string, string>?  -- Maps old cards to replacements

---@param data Card
---@return Card
function CardDB.create(data)
    local card = {
        id          = data.id,
        name        = data.name,
        type        = data.type,
        slot        = data.slot,
        targeted    = data.targeted    or false,
        cost        = data.cost        or 0,
        actionCost  = data.actionCost  or 1,
        damage      = data.damage,
        description = data.description,
        effect      = data.effect,
        transforms  = data.transforms,
    }
    return card
end


CardDB.library = {
    ice_bolt = CardDB.create({
        id = "ice_bolt",
        name = "Ice Bolt",
        type = "EVENT",
        action = "COMBAT",
        targeted = true,
        cost = 2,
        damage = 7,
        description = "Deal 7 damage to an enemy.",
        effect = function(self, ctx, target)
            target.hp = target.hp - self.damage
        end,
    }),

    fireball = CardDB.create({
        id = "fireball",
        name = "Fireball",
        type = "EVENT",
        action = "COMBAT",
        cost = 2,
        damage = 3,
        description = "Deal 3 damage to all enemies.",
        effect = function(self, ctx)
            for _, target in ipairs(ctx.enemies.engaged_enemies) do
                target.hp = target.hp - self.damage
            end
        end,
    }),

    longsword = CardDB.create({
        id = "longsword",
        name = "Longsword",
        type = "ASSET",
        slot = "weapon",
        action = "DECK",
        cost = 1,
        description = "Replaces 'Attack' with 'Slice' (3 dmg).",
        transforms = {
            attack = "slice"
        },
    }),
}

---@param id string
---@return Card
function CardDB:get(id)
    local card = self.library[id]
    assert(card, "Could not find card in library with id: " .. tostring(id))

    return card
end

return CardDB