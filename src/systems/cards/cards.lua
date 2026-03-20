
local CardDB = {}

---@class Card
---@field id string
---@field instanceId integer?               Unique id for a specific card instance
---@field name string
---@field type "EVENT"|"ASSET"
---@field combat_only boolean?               Clarify whether events are combat only or not
---@field slot "weapon"?                    TODO: add more as I add more assets
---@field description string
---@field targeted boolean?
---@field cost number?
---@field actionCost number?
---@field damage number?
---@field effect function?                  The instant effect of the card
---@field transforms table<string, string>? Maps old cards to replacements e.g. with weapons

---@param data Card
---@return Card
function CardDB.create(data)
    local card = {
        id          = data.id,
        name        = data.name,
        type        = data.type,
        combat_only = data.combat_only or false,
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
        combat_only = true,
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
        combat_only = true,
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
        cost = 1,
        description = "Replaces 'Attack' with 'Slice' (3 dmg).",
        transforms = {
            attack = "slice"
        },
    }),

    sprint = CardDB.create({
        id = "sprint",
        name = "Sprint",
        type = "EVENT",
        cost = 1,
        description = "Move up to 3 locations away.",
        effect = function(self, ctx)
            ctx.state:switch("roaming", { speed = 3 })
        end,
    })
}

---@param id string
---@return Card
function CardDB:get(id)
    local card = self.library[id]
    assert(card, "Could not find card in library with id: " .. tostring(id))

    return card
end

return CardDB