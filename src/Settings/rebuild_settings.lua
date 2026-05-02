import "Turbine.UI"
import "LUI.src.Utils.font"
import "LUI.src.Utils.token_format"
import "LUI.src.Settings.enums"
import "LUI.src.StatusBar.common"
import "LUI.src.UI.native_scaling"

local S = _G.STATUS_BAR_COMMON

function _G.rebuild_settings()
    local raw = _G.loaded_settings
    local configured_scaling = UI.NativeScaling.get_configured_scale(raw)
    local scaling = UI.NativeScaling.get_effective_scale(raw)
    local refresh_rate = raw.global.refresh_rate

    local function scaled_int(value)
        return math.floor((value * scaling) + 0.5)
    end

    local function scaled_number(value)
        return value * scaling
    end

    local function scaled_border(value)
        local n = value
        if type(n) ~= "number" then
            n = tonumber(n)
        end
        if n == nil or n <= 0 then
            return 0
        end
        local out = math.floor(n * scaling)
        if out < 1 then out = 1 end
        return out
    end

    _G.settings = {
        global = {
            number_abbrev = {},
            bestiary_capture = false,
        },
        ui = {
            windows = {},
            hud = {},
        },
        status_bar = {
            bg = {},
            font = {},
            zones = { left = {}, center = {}, right = {} },
            item_registry = {},
            widgets = {},
        },
        self = {
            vitals = {
                frame = {},
                morale = { font = {}, color = {} },
                power = { font = {}, color = {} },
                effects = {
                    buffs = { timer_font = {} },
                    debuffs = { timer_font = {} },
                },
            },
            expiring_effects = { font = {}, color = {} },
            cooldowns = { font = {}, color = {} },
            drops = { hud = {}, item = {} },
        },
        target = {
            vitals = {
                frame = {},
                morale = { font = {}, color = {} },
                power = { font = {}, color = {} },
                targets_target = { font = {}, color = {}, labels = {} },
                effects = {
                    buffs = { timer_font = {} },
                    debuffs = { timer_font = {} },
                },
            },
            boss_vitals = {
                frame = {},
                morale = { font = {}, color = {} },
                power = { font = {}, color = {} },
                effects = {
                    buffs = { timer_font = {} },
                    debuffs = { timer_font = {} },
                },
            },
            expiring_effects = { font = {}, color = {} },
        },
        party = {
            frame = {},
            morale = { font = {}, color = {} },
            power = { font = {}, color = {} },
            layout = {},
            class_icon = {},
            leader_icon = {},
            effects = {
                buffs = { timer_font = {} },
                debuffs = { timer_font = {} },
            },
        },
        inventory = {},
        drops = { hud = {}, item = {} },
        crafting = { display_mode = "pages", enabled = true },
        travel = { display_mode = "list", enabled = true },
        assets = { tile = {}, layouts = { icons = {}, details = {} } },
        bestiary = {},
    }

    _G.settings.global.scale = scaling
    _G.settings.global.configured_scale = configured_scaling
    _G.settings.global.refresh_rate = refresh_rate
    _G.settings.global.native_scaling = raw.global.native_scaling == true
    _G.settings.global.move_mode_shortcut = raw.global.move_mode_shortcut
    _G.settings.global.bestiary_capture = raw.global.bestiary_capture == true
    _G.settings.ui.windows = raw.ui.windows
    _G.settings.ui.hud = raw.ui.hud

    local function build_color(value)
        if value.A ~= nil and value.R ~= nil and value.G ~= nil and value.B ~= nil then
            return Turbine.UI.Color(value.A, value.R, value.G, value.B)
        end
        return value
    end

    local function build_vital_label(src)
        local dst = { font = {} }
        dst.enabled = src.enabled == true
        dst.text = src.text
        dst.tokens = lui_tokenize_format(dst.text)
        dst.anchor = src.anchor
        dst.width_mode = src.width_mode
        dst.text_alignment = src.text_alignment
        dst.x_offset = scaled_int(src.x_offset)
        dst.y_offset = scaled_int(src.y_offset)
        dst.font.name = src.font.name
        dst.font.size = scaled_number(src.font.size)
        dst.font.lotro = FONT_TO_LOTRO(dst.font.name, dst.font.size)
        dst.font.style = src.font.style
        dst.font.color = build_color(src.font.color)
        dst.font.outline_color = build_color(src.font.outline_color)
        return dst
    end

    local function build_vital(dst, src)
        dst.frame.width = scaled_int(src.frame.width)
        dst.frame.border_width = scaled_border(src.frame.border_width)
        dst.frame.border_color = src.frame.border_color
        dst.frame.incombat_opacity = src.frame.incombat_opacity
        dst.frame.outcombat_opacity = src.frame.outcombat_opacity

        dst.morale.height = scaled_int(src.morale.height)
        dst.power.height = scaled_int(src.power.height)

        dst.morale.font.name = src.morale.font.name
        dst.morale.font.size = scaled_number(src.morale.font.size)
        dst.morale.font.lotro = FONT_TO_LOTRO(dst.morale.font.name, dst.morale.font.size)
        dst.morale.font.style = src.morale.font.style
        dst.morale.font.color = src.morale.font.color
        dst.morale.font.outline_color = src.morale.font.outline_color

        dst.power.font.name = src.power.font.name
        dst.power.font.size = scaled_number(src.power.font.size)
        dst.power.font.lotro = FONT_TO_LOTRO(dst.power.font.name, dst.power.font.size)
        dst.power.font.style = src.power.font.style
        dst.power.font.color = src.power.font.color
        dst.power.font.outline_color = src.power.font.outline_color

        dst.morale.color = src.morale.color
        dst.power.color = src.power.color

        dst.morale.string_format = src.morale.string_format
        dst.morale.bubble_format = src.morale.bubble_format
        dst.power.string_format = src.power.string_format
        dst.morale.string_tokens = lui_tokenize_format(dst.morale.string_format)
        dst.morale.bubble_tokens = lui_tokenize_format(dst.morale.bubble_format)
        dst.power.string_tokens = lui_tokenize_format(dst.power.string_format)
        dst.background_matches_missing = src.background_matches_missing
        dst.background_dimming = src.background_dimming
        dst.morale.text_alignment = src.morale.text_alignment
        dst.power.text_alignment = src.power.text_alignment
        dst.morale.text_margin = scaled_int(src.morale.text_margin)
        dst.power.text_margin = scaled_int(src.power.text_margin)
        if src.morale.labels ~= nil then
            dst.morale.labels = {
                build_vital_label(src.morale.labels[1]),
                build_vital_label(src.morale.labels[2]),
            }
        end
        if src.power.labels ~= nil then
            dst.power.labels = {
                build_vital_label(src.power.labels[1]),
                build_vital_label(src.power.labels[2]),
            }
        end

        dst.frame.effects_height = scaled_int(src.frame.effects_height)
        dst.frame.effects_position = src.frame.effects_position

        if src.effects ~= nil then
            dst.effects.buffs.icon_size = scaled_int(src.effects.buffs.icon_size)
            dst.effects.debuffs.icon_size = scaled_int(src.effects.debuffs.icon_size)

            dst.effects.buffs.timer_font.name = src.effects.buffs.timer_font.name
            dst.effects.buffs.timer_font.size = scaled_number(src.effects.buffs.timer_font.size)
            dst.effects.buffs.timer_font.lotro = FONT_TO_LOTRO(dst.effects.buffs.timer_font.name,
                dst.effects.buffs.timer_font.size)
            dst.effects.buffs.timer_font.style = src.effects.buffs.timer_font.style
            dst.effects.buffs.timer_font.color = src.effects.buffs.timer_font.color
            dst.effects.buffs.timer_font.outline_color = src.effects.buffs.timer_font.outline_color

            dst.effects.debuffs.timer_font.name = src.effects.debuffs.timer_font.name
            dst.effects.debuffs.timer_font.size = scaled_number(src.effects.debuffs.timer_font.size)
            dst.effects.debuffs.timer_font.lotro = FONT_TO_LOTRO(dst.effects.debuffs.timer_font.name,
                dst.effects.debuffs.timer_font.size)
            dst.effects.debuffs.timer_font.style = src.effects.debuffs.timer_font.style
            dst.effects.debuffs.timer_font.color = src.effects.debuffs.timer_font.color
            dst.effects.debuffs.timer_font.outline_color = src.effects.debuffs.timer_font.outline_color

            dst.effects.debuffs.track_curable = src.effects.debuffs.track_curable
            dst.effects.debuffs.track_noncurable = src.effects.debuffs.track_noncurable
        end
    end

    build_vital(_G.settings.self.vitals, raw.self.vitals)
    build_vital(_G.settings.target.vitals, raw.target.vitals)
    build_vital(_G.settings.target.boss_vitals, raw.target.boss_vitals)
    build_vital(_G.settings.party, raw.party)

    local raw_inv = raw.inventory
    if raw_inv ~= nil then
        local inv = _G.settings.inventory
        inv.enabled = raw_inv.enabled
        inv.replace = raw_inv.replace
        inv.cols = raw_inv.cols
        inv.tile_size = scaled_int(raw_inv.tile_size)
    end

    local raw_assets = raw.assets
    if raw_assets ~= nil then
        local assets = _G.settings.assets
        assets.layouts = raw_assets.layouts
        assets.enabled = raw_assets.enabled
        assets.view_mode = raw_assets.view_mode
        assets.stack_items = raw_assets.stack_items
        assets.tile.icons = scaled_int(raw_assets.tile.icons)
        assets.tile.details = scaled_int(raw_assets.tile.details)
    end

    local raw_crafting = raw.crafting
    if raw_crafting ~= nil then
        _G.settings.crafting.display_mode = raw_crafting.display_mode
        _G.settings.crafting.enabled = raw_crafting.enabled
    end

    local raw_travel = raw.travel
    if raw_travel ~= nil then
        _G.settings.travel.display_mode = raw_travel.display_mode
        _G.settings.travel.enabled = raw_travel.enabled
    end

    local raw_party_ci = raw.party.class_icon
    _G.settings.party.class_icon.enabled = raw_party_ci.enabled
    _G.settings.party.class_icon.size = scaled_int(raw_party_ci.size)
    _G.settings.party.class_icon.x = scaled_int(raw_party_ci.x)
    _G.settings.party.class_icon.y = scaled_int(raw_party_ci.y)

    local raw_party_li = raw.party.leader_icon
    _G.settings.party.leader_icon.enabled = raw_party_li.enabled
    _G.settings.party.leader_icon.size = scaled_int(raw_party_li.size)
    _G.settings.party.leader_icon.x = scaled_int(raw_party_li.x)
    _G.settings.party.leader_icon.y = scaled_int(raw_party_li.y)

    local raw_tt = raw.target.vitals.targets_target
    local dst_tt = _G.settings.target.vitals.targets_target
    dst_tt.width = scaled_int(raw_tt.width)
    dst_tt.height = scaled_int(raw_tt.height)
    dst_tt.border_width = scaled_border(raw_tt.border_width)
    dst_tt.color = raw_tt.color
    dst_tt.bubble_format = raw_tt.bubble_format
    dst_tt.bubble_tokens = lui_tokenize_format(dst_tt.bubble_format)
    dst_tt.background_matches_missing = raw_tt.background_matches_missing
    dst_tt.background_dimming = raw_tt.background_dimming
    dst_tt.labels = {
        build_vital_label(raw_tt.labels[1]),
        build_vital_label(raw_tt.labels[2]),
    }

    local raw_bv = raw.target.boss_vitals
    local dst_bv = _G.settings.target.boss_vitals
    dst_bv.enabled = raw_bv.enabled
    dst_bv.power.width = scaled_int(raw_bv.power.width)
    dst_bv.power.hide = raw_bv.power.hide
    dst_bv.power.side = raw_bv.power.side

    local raw_party_layout = raw.party.layout
    _G.settings.party.layout.rows = raw_party_layout.rows
    _G.settings.party.layout.spacing_x = scaled_int(raw_party_layout.spacing_x)
    _G.settings.party.layout.spacing_y = scaled_int(raw_party_layout.spacing_y)

    local raw_self_ee = raw.self.expiring_effects
    local self_ee = _G.settings.self.expiring_effects
    self_ee.enabled = raw_self_ee.enabled
    self_ee.show_buffs = raw_self_ee.show_buffs
    self_ee.show_curable_debuffs = raw_self_ee.show_curable_debuffs
    self_ee.show_noncurable_debuffs = raw_self_ee.show_noncurable_debuffs
    self_ee.icon_side = raw_self_ee.icon_side
    self_ee.bar_expire_towards = raw_self_ee.bar_expire_towards
    self_ee.name_max_chars = raw_self_ee.name_max_chars
    self_ee.threshold = raw_self_ee.threshold
    self_ee.columns = raw_self_ee.columns
    self_ee.rows = raw_self_ee.rows
    self_ee.spacing = scaled_int(raw_self_ee.spacing)
    self_ee.bar_width = scaled_int(raw_self_ee.bar_width)
    self_ee.bar_height = scaled_int(raw_self_ee.bar_height)
    self_ee.border_width = scaled_border(raw_self_ee.border_width)
    self_ee.color = raw_self_ee.color

    self_ee.font.name = raw_self_ee.font.name
    self_ee.font.size = scaled_number(raw_self_ee.font.size)
    self_ee.font.lotro = FONT_TO_LOTRO(self_ee.font.name, self_ee.font.size)
    self_ee.font.style = raw_self_ee.font.style
    self_ee.font.color = raw_self_ee.font.color
    self_ee.font.outline_color = raw_self_ee.font.outline_color

    local raw_expiring_target_effects = raw.target.expiring_effects
    local target_ee = _G.settings.target.expiring_effects
    target_ee.enabled = raw_expiring_target_effects.enabled
    target_ee.show_buffs = raw_expiring_target_effects.show_buffs
    target_ee.show_curable_debuffs = raw_expiring_target_effects.show_curable_debuffs
    target_ee.show_noncurable_debuffs = raw_expiring_target_effects.show_noncurable_debuffs
    target_ee.icon_side = raw_expiring_target_effects.icon_side
    target_ee.bar_expire_towards = raw_expiring_target_effects.bar_expire_towards
    target_ee.name_max_chars = raw_expiring_target_effects.name_max_chars
    target_ee.threshold = raw_expiring_target_effects.threshold
    target_ee.columns = raw_expiring_target_effects.columns
    target_ee.rows = raw_expiring_target_effects.rows
    target_ee.spacing = scaled_int(raw_expiring_target_effects.spacing)
    target_ee.bar_width = scaled_int(raw_expiring_target_effects.bar_width)
    target_ee.bar_height = scaled_int(raw_expiring_target_effects.bar_height)
    target_ee.border_width = scaled_border(raw_expiring_target_effects.border_width)
    target_ee.color = raw_expiring_target_effects.color

    target_ee.font.name = raw_expiring_target_effects.font.name
    target_ee.font.size = scaled_number(raw_expiring_target_effects.font.size)
    target_ee.font.lotro = FONT_TO_LOTRO(target_ee.font.name, target_ee.font.size)
    target_ee.font.style = raw_expiring_target_effects.font.style
    target_ee.font.color = raw_expiring_target_effects.font.color
    target_ee.font.outline_color = raw_expiring_target_effects.font.outline_color

    local raw_abbrev = raw.global.number_abbrev
    _G.settings.global.number_abbrev.enabled = raw_abbrev.enabled
    _G.settings.global.number_abbrev.digits = raw_abbrev.digits
    _G.settings.global.number_abbrev.width = raw_abbrev.width
    _G.settings.global.number_abbrev.method = raw_abbrev.method

    local raw_sb = raw.status_bar
    local sb = _G.settings.status_bar
    sb.enabled = raw_sb.enabled
    sb.height = scaled_int(raw_sb.height)
    sb.padding = scaled_int(raw_sb.padding)
    sb.gap = scaled_int(raw_sb.gap)
    sb.bg.opacity = raw_sb.bg.opacity
    sb.bg.color = raw_sb.bg.color

    sb.font.name = raw_sb.font.name
    sb.font.size = scaled_number(raw_sb.font.size)
    sb.font.lotro = FONT_TO_LOTRO(sb.font.name, sb.font.size)
    sb.font.style = raw_sb.font.style
    sb.font.color = raw_sb.font.color
    sb.font.outline_color = raw_sb.font.outline_color

    sb.layout = raw_sb.layout
    sb.item_registry = raw_sb.item_registry or {}
    sb.zones.left = S.parse_status_bar_layout(raw_sb.layout.left, sb.item_registry)
    sb.zones.center = S.parse_status_bar_layout(raw_sb.layout.center, sb.item_registry)
    sb.zones.right = S.parse_status_bar_layout(raw_sb.layout.right, sb.item_registry)

    local function list_has(list, value)
        for i = 1, #list do
            if list[i] == value then
                return true
            end
        end
        return false
    end

    local function in_zones(widget_key)
        return list_has(sb.zones.left, widget_key) or list_has(sb.zones.center, widget_key) or
            list_has(sb.zones.right, widget_key)
    end

    sb.widgets.time_local = {
        enabled = in_zones("time_local"),
        width = scaled_int(raw_sb.widgets.time_local.width),
        content_alignment = LUI_TO_LOTRO.text_alignment[raw_sb.widgets.time_local.text_alignment],
        time_format = raw_sb.widgets.time_local.time_format,
    }
    sb.widgets.inventory_space = {
        enabled = in_zones("inventory_space"),
        width = scaled_int(raw_sb.widgets.inventory_space.width),
        icon = raw_sb.widgets.inventory_space.icon,
        color = raw_sb.widgets.inventory_space.color,
        content_alignment = LUI_TO_LOTRO.text_alignment[raw_sb.widgets.inventory_space.text_alignment],
    }
    sb.widgets.equipment_wear = {
        enabled = in_zones("equipment_wear"),
        width = scaled_int(raw_sb.widgets.equipment_wear.width),
        icon = raw_sb.widgets.equipment_wear.icon,
        coloring = raw_sb.widgets.equipment_wear.coloring == true,
        color = raw_sb.widgets.equipment_wear.color,
        content_alignment = LUI_TO_LOTRO.text_alignment[raw_sb.widgets.equipment_wear.text_alignment],
    }
    sb.widgets.money = {
        enabled = in_zones("money"),
        width = scaled_int(raw_sb.widgets.money.width),
        content_alignment = LUI_TO_LOTRO.text_alignment[raw_sb.widgets.money.text_alignment],
    }
    sb.widgets.wallet = {
        enabled = in_zones("wallet"),
        width = scaled_int(raw_sb.widgets.wallet.width),
        items = _G.STATUS_BAR_COMMON.parse_wallet_item_list(raw_sb.widgets.wallet.items),
        content_alignment = LUI_TO_LOTRO.text_alignment[raw_sb.widgets.wallet.text_alignment],
    }
    sb.widgets.item = {
        width = scaled_int(raw_sb.widgets.item.width),
    }

    sb.widgets.shortcut = {
        width = scaled_int(raw_sb.widgets.shortcut.width),
        height = scaled_int(raw_sb.widgets.shortcut.height),
    }

    sb.widgets.craft_plan = {
        enabled = in_zones("craft_plan"),
        width = scaled_int(raw_sb.widgets.craft_plan.width),
        max_visible = math.max(1, tonumber(raw_sb.widgets.craft_plan.max_visible) or 4),
    }

    sb.widgets.button = {
        width = sb.widgets.shortcut.width,
        height = sb.widgets.shortcut.height,
    }

    local function build_shortcut_widget(widget_key)
        return {
            enabled = in_zones(widget_key),
            width = sb.widgets.shortcut.width,
            height = sb.widgets.shortcut.height,
        }
    end

    sb.widgets.config = build_shortcut_widget("config")
    sb.widgets.assets = build_shortcut_widget("assets")
    sb.widgets.bestiary = build_shortcut_widget("bestiary")
    sb.widgets.craft = build_shortcut_widget("craft")
    sb.widgets.travel = build_shortcut_widget("travel")

    local raw_cd = raw.self.cooldowns
    local cd = _G.settings.self.cooldowns
    cd.enabled = raw_cd.enabled
    cd.threshold = raw_cd.threshold
    cd.min_base_cooldown = raw_cd.min_base_cooldown
    cd.columns = raw_cd.columns
    cd.rows = raw_cd.rows
    cd.flow = raw_cd.flow
    cd.spacing = scaled_int(raw_cd.spacing)
    cd.border_width = scaled_border(raw_cd.border_width)
    cd.item_w = scaled_int(raw_cd.item_w)
    cd.item_h = scaled_int(raw_cd.item_h)
    cd.icon_side = raw_cd.icon_side
    cd.bar_expire_towards = raw_cd.bar_expire_towards
    cd.bar_mode = raw_cd.bar_mode
    cd.time_format = raw_cd.time_format
    cd.text_margin = scaled_int(raw_cd.text_margin)
    cd.name_max_chars = raw_cd.name_max_chars
    cd.whitelist = raw_cd.whitelist
    cd.blacklist = raw_cd.blacklist
    cd.color = raw_cd.color

    cd.font.name = raw_cd.font.name
    cd.font.size = scaled_number(raw_cd.font.size)
    cd.font.lotro = FONT_TO_LOTRO(cd.font.name, cd.font.size)
    cd.font.style = raw_cd.font.style
    cd.font.color = raw_cd.font.color
    cd.font.outline_color = raw_cd.font.outline_color

    local raw_drops = raw.drops
    local drops = _G.settings.drops
    drops.enabled = raw_drops.enabled
    drops.visible_duration = raw_drops.visible_duration
    drops.rows = raw_drops.rows
    drops.icon_size = scaled_int(raw_drops.icon_size)
    drops.width = scaled_int(raw_drops.width)
    drops.flow = raw_drops.flow
    drops.align = raw_drops.align
    drops.icon_side = raw_drops.icon_side
    drops.animations_enabled = raw_drops.animations_enabled
    drops.move_duration = raw_drops.move_duration
    drops.hud.background_opacity = raw_drops.hud.background_opacity
    drops.hud.background_color = raw_drops.hud.background_color
    drops.item.background_opacity = raw_drops.item.background_opacity
    drops.item.background_color = raw_drops.item.background_color
end

rebuild_settings = _G.rebuild_settings
