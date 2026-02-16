local function planeswalker_config(starting_loyalty)
    return {
        has_activated_loyalty = false,
        loyalty = starting_loyalty,
    }
end

local function planeswalker_loc_vars(center)
    local info = {}
    local colors = {}
    table.insert(info, center.ability.extra.planeswalker.loyalty)
    if center.ability.extra.planeswalker.has_activated_loyalty then
        table.insert(info, "Inactive...")
        table.insert(colors, HEX('CCCCCC'))
    else
        table.insert(info, "Active!")
        table.insert(colors, HEX('FFD700'))
    end
    for index, value in ipairs(center.config.center.planeswalker.loyalty_abilities) do
        table.insert(info,
            G.FUNCS.format_loyalty_cost(center.config.center.planeswalker.loyalty_abilities[index]['cost']))
    end
    info["colours"] = colors
    return info
end

local function planeswalker_calculate(card, context)
    if context.setting_blind and not (context.blueprint_card or card).getting_sliced then
        card_eval_status_text(card, 'extra', nil, nil, nil, { message = localize('mtg_planeswalker_active_ex') })
        card.ability.extra.planeswalker.has_activated_loyalty = false
    end
end

local function planeswalker_loyalty_ability(cost, can_use, use)
    return {
        cost = cost,
        can_use = can_use,
        use = use
    }
end

--Ajani
SMODS.Joker {
    object_type = "Joker",
    name = "mtg-ajani",
    key = "ajani",
    pos = { x = 0, y = 7 },
    config = {
        extra = {
            ability_1_targets = 2,
            ability_1_strength = 1,
            ability_2_strength = 1,
            ability_2_loyalty = 1,
            planeswalker = planeswalker_config(3)
        },
    },
    order = 5,
    rarity = 2,
    cost = 8,
    atlas = "mtg_atlas",
    loc_vars = function(self, info_queue, center)
        local info = planeswalker_loc_vars(center)
        table.insert(info, center.ability.extra.ability_1_targets)
        table.insert(info, center.ability.extra.ability_1_strength)
        table.insert(info, center.ability.extra.ability_2_strength)
        table.insert(info, center.ability.extra.ability_2_loyalty)
        return { vars = info }
    end,
    calculate = function(self, card, context)
        planeswalker_calculate(card, context)
    end,
    planeswalker = {
        loyalty_abilities = {
            planeswalker_loyalty_ability(
                2,
                function(card, loyalty_ability)
                    local num_highlighted = #G.hand.highlighted
                    return num_highlighted <= card.ability.extra.ability_1_targets and num_highlighted > 0
                end,
                function(card, loyalty_ability)
                    G.FUNCS.buff_cards(G.hand.highlighted, card.ability.extra.ability_1_strength, 1)
                end
            ),
            planeswalker_loyalty_ability(
                -2,
                function(card, loyalty_ability)
                    local cards = #G.hand.cards
                    return cards > 0
                end,
                function(card, loyalty_ability)
                    G.FUNCS.buff_cards(G.hand.cards, card.ability.extra.ability_2_strength, 1)
                    local jokers_to_buff = {}
                    for index, value in ipairs(G.jokers.cards) do
                        if value ~= card then table.insert(jokers_to_buff, value) end
                    end
                    G.FUNCS.buff_loyalty(jokers_to_buff, card.ability.extra.ability_2_loyalty, 1)
                end
            ),
            planeswalker_loyalty_ability(
                -7,
                function(card, loyalty_ability)
                    local cards = #G.hand.cards
                    return cards > 0
                end,
                function(card, loyalty_ability)
                    local cards = G.hand.cards
                    for i = 1, #cards do
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.15,
                            func = function()
                                cards[i]:set_seal("Red")
                                return true
                            end
                        }))
                    end
                end
            )
        },
    },
}
