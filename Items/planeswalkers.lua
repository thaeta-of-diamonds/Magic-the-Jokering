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
    pos = { x = 0, y = 0 },
    config = {
        extra = {
            ability_1_targets = 2,
            ability_1_strength = 1,
            ability_2_strength = 1,
            ability_2_loyalty = 1,
            planeswalker = planeswalker_config(3)
        },
    },
    rarity = 4,
    cost = 20,
    atlas = "mtg_planeswalkers",
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

--Jace
SMODS.Joker {
    object_type = "Joker",
    name = "mtg-jace",
    key = "jace",
    pos = { x = 2, y = 0 },
    config = {
        extra = {
            ability_1_cards = 3,
            ability_1_active = false,
            ability_3_cards = 2,
            planeswalker = planeswalker_config(3)
        },
    },
    rarity = 4,
    cost = 20,
    atlas = "mtg_planeswalkers",
    loc_vars = function(self, info_queue, center)
        local info = planeswalker_loc_vars(center)
        table.insert(info, center.ability.extra.ability_1_cards)
        table.insert(info, center.ability.extra.ability_3_cards)
        return { vars = info }
    end,
    calculate = function(self, card, context)
        planeswalker_calculate(card, context)
        if context.blind_defeated and not context.blueprint then
            card.ability.ability_1_active = card.ability.ability_1_active or 0
            if card.ability.ability_1_active > 0 then
                G.hand:change_size(-math.floor(card.ability.extra.ability_1_cards) * card.ability.ability_1_active)
                card.ability.ability_1_active = 0
                return nil, true
            end
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        if card.ability.ability_1_active then
            G.hand:change_size(-math.floor(card.ability.extra.ability_1_cards) * card.ability.ability_1_active)
            card.ability.ability_1_active = 0
        end
    end,
    planeswalker = {
        loyalty_abilities = {
            planeswalker_loyalty_ability(
                2,
                function(card, loyalty_ability)
                    return G.GAME.blind
                end,
                function(card, loyalty_ability)
                    local bonus = math.floor(card.ability.extra.ability_1_cards)
                    card.ability.ability_1_active = card.ability.ability_1_active or 0
                    G.hand:change_size(bonus)
                    card.ability.ability_1_active = card.ability.ability_1_active + 1
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.1,
                        func = function()
                            G.FUNCS.draw_from_deck_to_hand(bonus)
                            return true
                        end
                    }))

                    card_eval_status_text(card, 'extra', nil, nil, nil, { message = localize('mtg_draw_ex') })
                end
            ),
            planeswalker_loyalty_ability(
                -2,
                function(card, loyalty_ability)
                    local cards = #G.hand.cards
                    return cards > 0
                end,
                function(card, loyalty_ability)
                    -- Shoutout to Cryptid Mod, just using their implementation
                    G.GAME.effarcire_buffer = true
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            SMODS.draw_cards(#G.deck.cards)
                            G.E_MANAGER:add_event(Event({
                                func = function()
                                    G.GAME.effarcire_buffer = nil
                                    save_run()
                                    return true
                                end,
                            }))
                            return true
                        end,
                    }))

                    card_eval_status_text(card, 'extra', nil, nil, nil, { message = localize('mtg_draw_ex') })
                end
            ),
            planeswalker_loyalty_ability(
                -7,
                function(card, loyalty_ability)
                    local cards = #G.hand.cards
                    return cards > 0
                end,
                function(card, loyalty_ability)
                    local bonus = math.floor(card.ability.extra.ability_3_cards)
                    if G.hand then
                        G.hand:change_size(bonus)
                    end
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.1,
                        func = function()
                            G.FUNCS.draw_from_deck_to_hand(bonus)
                            return true
                        end
                    }))

                    card_eval_status_text(card, 'extra', nil, nil, nil, { message = localize('mtg_draw_ex') })
                end
            )
        },
    },
}

--Bolas
SMODS.Joker {
    object_type = "Joker",
    name = "mtg-nicol-bolas",
    key = "nicolbolas",
    pos = { x = 1, y = 0 },
    config = {
        extra = {
            ability_1_cards = 2,
            ability_2_damage = 7,
            planeswalker = planeswalker_config(5)
        },
    },
    rarity = 4,
    cost = 20,
    atlas = "mtg_planeswalkers",
    loc_vars = function(self, info_queue, center)
        local info = planeswalker_loc_vars(center)
        table.insert(info, center.ability.extra.ability_1_cards)
        table.insert(info, center.ability.extra.ability_2_damage)
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
                    return G.GAME.blind
                end,
                function(card, loyalty_ability)
                    
                end
            ),
            planeswalker_loyalty_ability(
                -3,
                function(card, loyalty_ability)
                    return G.GAME.blind
                end,
                function(card, loyalty_ability)
                    damage_blind(card, card.ability.extra.ability_2_damage)
                end
            ),
            planeswalker_loyalty_ability(
                -8,
                function(card, loyalty_ability)
                    return G.GAME.blind
                end,
                function(card, loyalty_ability)
                    instant_win()
                end
            )
        },
    },
}
