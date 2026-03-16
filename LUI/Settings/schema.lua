import "Turbine.UI"
import "Geldahr.LUI.Settings.enums"

function _G.ensure_loaded_settings()
    if type(_G.loaded_settings) ~= "table" then
        _G.loaded_settings = {}
    end
    local s = _G.loaded_settings

    local display_w, display_h = Turbine.UI.Display.GetSize()
    local BASE_W = 2560
    local BASE_H = 1440

    local function _pos_x(base_left)
        return math.floor(((base_left / BASE_W) * display_w) + 0.5)
    end

    local function _pos_y(base_top)
        return math.floor(((base_top / BASE_H) * display_h) + 0.5)
    end

    local function ensure_table(t, key)
        if type(t[key]) ~= "table" then
            t[key] = {}
        end
        return t[key]
    end

    local function ensure_table_at(t, keys)
        local cur = t
        for i = 1, #keys do
            cur = ensure_table(cur, keys[i])
        end
        return cur
    end

    ensure_table(s, "global")
    ensure_table(s, "self")
    ensure_table(s, "target")
    ensure_table(s, "party")
    ensure_table(s, "inventory")
    ensure_table(s, "assets")
    ensure_table(s, "status_bar")

    ensure_table_at(s, { "global", "config_window" })
    ensure_table_at(s, { "global", "number_abbrev" })
    ensure_table_at(s, { "status_bar", "window" })
    ensure_table_at(s, { "status_bar", "bg" })
    ensure_table_at(s, { "status_bar", "font" })
    ensure_table_at(s, { "status_bar", "layout" })
    ensure_table_at(s, { "status_bar", "zones" })
    ensure_table_at(s, { "status_bar", "zones", "left" })
    ensure_table_at(s, { "status_bar", "zones", "center" })
    ensure_table_at(s, { "status_bar", "zones", "right" })
    ensure_table_at(s, { "status_bar", "widgets" })
    ensure_table_at(s, { "status_bar", "widgets", "time_local" })
    ensure_table_at(s, { "status_bar", "widgets", "inventory_space" })
    ensure_table_at(s, { "status_bar", "widgets", "inventory_space", "color" })
    ensure_table_at(s, { "status_bar", "widgets", "money" })

    ensure_table_at(s, { "self", "vitals" })
    ensure_table_at(s, { "self", "vitals", "frame" })
    ensure_table_at(s, { "self", "vitals", "window" })
    ensure_table_at(s, { "self", "vitals", "morale" })
    ensure_table_at(s, { "self", "vitals", "morale", "font" })
    ensure_table_at(s, { "self", "vitals", "morale", "color" })
    ensure_table_at(s, { "self", "vitals", "power" })
    ensure_table_at(s, { "self", "vitals", "power", "font" })
    ensure_table_at(s, { "self", "vitals", "power", "color" })
    ensure_table_at(s, { "self", "vitals", "effects" })
    ensure_table_at(s, { "self", "vitals", "effects", "buffs" })
    ensure_table_at(s, { "self", "vitals", "effects", "buffs", "timer_font" })
    ensure_table_at(s, { "self", "vitals", "effects", "debuffs" })
    ensure_table_at(s, { "self", "vitals", "effects", "debuffs", "timer_font" })

    ensure_table_at(s, { "target", "vitals" })
    ensure_table_at(s, { "target", "vitals", "frame" })
    ensure_table_at(s, { "target", "vitals", "window" })
    ensure_table_at(s, { "target", "vitals", "morale" })
    ensure_table_at(s, { "target", "vitals", "morale", "font" })
    ensure_table_at(s, { "target", "vitals", "morale", "color" })
    ensure_table_at(s, { "target", "vitals", "power" })
    ensure_table_at(s, { "target", "vitals", "power", "font" })
    ensure_table_at(s, { "target", "vitals", "power", "color" })
    ensure_table_at(s, { "target", "vitals", "targets_target" })
    ensure_table_at(s, { "target", "vitals", "targets_target", "font" })
    ensure_table_at(s, { "target", "vitals", "targets_target", "color" })
    ensure_table_at(s, { "target", "vitals", "targets_target", "window" })
    ensure_table_at(s, { "target", "vitals", "effects" })
    ensure_table_at(s, { "target", "vitals", "effects", "buffs" })
    ensure_table_at(s, { "target", "vitals", "effects", "buffs", "timer_font" })
    ensure_table_at(s, { "target", "vitals", "effects", "debuffs" })
    ensure_table_at(s, { "target", "vitals", "effects", "debuffs", "timer_font" })
    ensure_table_at(s, { "target", "boss_vitals" })
    ensure_table_at(s, { "target", "boss_vitals", "frame" })
    ensure_table_at(s, { "target", "boss_vitals", "window" })
    ensure_table_at(s, { "target", "boss_vitals", "morale" })
    ensure_table_at(s, { "target", "boss_vitals", "morale", "font" })
    ensure_table_at(s, { "target", "boss_vitals", "morale", "color" })
    ensure_table_at(s, { "target", "boss_vitals", "power" })
    ensure_table_at(s, { "target", "boss_vitals", "power", "font" })
    ensure_table_at(s, { "target", "boss_vitals", "power", "color" })
    ensure_table_at(s, { "target", "boss_vitals", "effects" })
    ensure_table_at(s, { "target", "boss_vitals", "effects", "buffs" })
    ensure_table_at(s, { "target", "boss_vitals", "effects", "buffs", "timer_font" })
    ensure_table_at(s, { "target", "boss_vitals", "effects", "debuffs" })
    ensure_table_at(s, { "target", "boss_vitals", "effects", "debuffs", "timer_font" })

    ensure_table_at(s, { "party", "frame" })
    ensure_table_at(s, { "party", "window" })
    ensure_table_at(s, { "party", "layout" })
    ensure_table_at(s, { "party", "class_icon" })
    ensure_table_at(s, { "party", "leader_icon" })
    ensure_table_at(s, { "party", "morale" })
    ensure_table_at(s, { "party", "morale", "font" })
    ensure_table_at(s, { "party", "morale", "color" })
    ensure_table_at(s, { "party", "power" })
    ensure_table_at(s, { "party", "power", "font" })
    ensure_table_at(s, { "party", "power", "color" })
    ensure_table_at(s, { "party", "effects" })
    ensure_table_at(s, { "party", "effects", "buffs" })
    ensure_table_at(s, { "party", "effects", "buffs", "timer_font" })
    ensure_table_at(s, { "party", "effects", "debuffs" })
    ensure_table_at(s, { "party", "effects", "debuffs", "timer_font" })

    ensure_table_at(s, { "inventory", "window" })
    ensure_table_at(s, { "assets", "window" })
    ensure_table_at(s, { "assets", "tile" })
    ensure_table_at(s, { "assets", "layouts" })
    ensure_table_at(s, { "assets", "layouts", "icons" })
    ensure_table_at(s, { "assets", "layouts", "details" })

    ensure_table_at(s, { "self", "expiring_effects" })
    ensure_table_at(s, { "self", "expiring_effects", "window" })
    ensure_table_at(s, { "self", "expiring_effects", "color" })
    ensure_table_at(s, { "self", "expiring_effects", "font" })
    ensure_table_at(s, { "self", "cooldowns" })
    ensure_table_at(s, { "self", "cooldowns", "window" })
    ensure_table_at(s, { "self", "cooldowns", "font" })
    ensure_table_at(s, { "self", "cooldowns", "color" })

    ensure_table_at(s, { "target", "expiring_effects" })
    ensure_table_at(s, { "target", "expiring_effects", "window" })
    ensure_table_at(s, { "target", "expiring_effects", "color" })
    ensure_table_at(s, { "target", "expiring_effects", "font" })

    if s.global.scale == nil then
        local sc = display_h / 1080
        s.global.scale = math.floor((sc * 100) + 0.5) / 100
    end

    if s.global.refresh_rate == nil then
        s.global.refresh_rate = 30
    end
    if s.global.bestiary_capture == nil then
        s.global.bestiary_capture = false
    end
    if is_lui_english_language ~= nil and is_lui_english_language() ~= true then
        s.global.bestiary_capture = false
    end

    local function apply_vital_defaults(v, is_target, morale_default, power_default, default_left, default_top,
                                        default_tt_left, default_tt_top, default_track_noncurable,
                                        default_frame_width)
        v.frame.width = v.frame.width or default_frame_width or 250
        v.frame.border_width = v.frame.border_width or 1
        v.frame.incombat_opacity = v.frame.incombat_opacity or 1.0
        v.frame.outcombat_opacity = v.frame.outcombat_opacity or 1.0

        if v.window.left == nil then
            v.window.left = default_left or (is_target and 600 or 200)
        end
        if v.window.top == nil then
            v.window.top = default_top or 200
        end

        v.morale.height = v.morale.height or 50
        v.power.height = v.power.height or 26

        if v.morale.font.name == nil then
            v.morale.font.name = LUI_ENUMS.font_name.VERDANA
        end
        v.morale.font.size = v.morale.font.size or 16
        if v.morale.font.style == nil then
            v.morale.font.style = LUI_ENUMS.font_style.OUTLINE
        end
        v.morale.font.color = v.morale.font.color or Turbine.UI.Color(1, 1, 1, 1)
        v.morale.font.outline_color = v.morale.font.outline_color or Turbine.UI.Color(1, 0, 0, 0)

        if v.power.font.name == nil then
            v.power.font.name = LUI_ENUMS.font_name.VERDANA
        end
        v.power.font.size = v.power.font.size or 14
        if v.power.font.style == nil then
            v.power.font.style = LUI_ENUMS.font_style.OUTLINE
        end
        v.power.font.color = v.power.font.color or Turbine.UI.Color(1, 1, 1, 1)
        v.power.font.outline_color = v.power.font.outline_color or Turbine.UI.Color(1, 0, 0, 0)

        v.morale.color.background = v.morale.color.background or Turbine.UI.Color(1, 0.0, 0.0, 0.0)
        v.frame.border_color = v.frame.border_color or v.morale.color.background
        v.morale.color.bubble = v.morale.color.bubble or Turbine.UI.Color(1, 0.529412, 0.800000, 0.980392)

        v.morale.color.high = v.morale.color.high or Turbine.UI.Color(1, 0.290196, 0.639216, 0.286275)
        v.morale.color.medium = v.morale.color.medium or Turbine.UI.Color(1, 0.650980, 0.803922, 0.196078)
        v.morale.color.low = v.morale.color.low or Turbine.UI.Color(1, 0.870588, 0.549020, 0.000000)
        v.morale.color.critical = v.morale.color.critical or Turbine.UI.Color(1, 0.870588, 0.109804, 0.000000)
        v.morale.color.neutral = v.morale.color.neutral or Turbine.UI.Color(1, 0.501961, 0.600000, 0.501961)
        if v.morale.color.gradient == nil then
            v.morale.color.gradient = true
        end
        v.morale.color.gradient_full = v.morale.color.gradient_full or v.morale.color.high
        v.morale.color.gradient_mid = v.morale.color.gradient_mid or Turbine.UI.Color(1, 0.847059, 0.776471, 0.235294)
        v.morale.color.gradient_low = v.morale.color.gradient_low or v.morale.color.critical

        v.power.color.power = v.power.color.power or Turbine.UI.Color(1, 0.200000, 0.600000, 0.980392)
        v.power.color.wrath = v.power.color.wrath or Turbine.UI.Color(1, 1.000000, 0.329412, 0.129412)

        if v.morale.string_format == nil then
            v.morale.string_format = morale_default or
                (is_target and "[%level%] %name%\\n%c / %t - %p" or "%c / %t - %p")
        end
        if v.background_matches_missing == nil then
            v.background_matches_missing = true
        end
        if v.background_dimming == nil then
            v.background_dimming = 0.75
        end
        if v.morale.bubble_format == nil then
            v.morale.bubble_format = " - %b"
        end
        if v.power.string_format == nil then
            v.power.string_format = power_default or "%c / %t - %p"
        end
        if v.morale.text_alignment == nil then
            v.morale.text_alignment = LUI_ENUMS.text_alignment.CENTER
        end
        if v.power.text_alignment == nil then
            v.power.text_alignment = LUI_ENUMS.text_alignment.CENTER
        end
        v.morale.text_margin = v.morale.text_margin or 4
        v.power.text_margin = v.power.text_margin or 4

        v.effects.buffs.icon_size = v.effects.buffs.icon_size or 22
        if v.effects.buffs.timer_font.name == nil then
            v.effects.buffs.timer_font.name = LUI_ENUMS.font_name.VERDANA
        end
        v.effects.buffs.timer_font.size = v.effects.buffs.timer_font.size or 10
        if v.effects.buffs.timer_font.style == nil then
            v.effects.buffs.timer_font.style = LUI_ENUMS.font_style.OUTLINE
        end
        v.effects.buffs.timer_font.color = v.effects.buffs.timer_font.color or Turbine.UI.Color(1, 1, 1, 1)
        v.effects.buffs.timer_font.outline_color = v.effects.buffs.timer_font.outline_color or
            Turbine.UI.Color(1, 0, 0, 0)

        v.effects.debuffs.icon_size = v.effects.debuffs.icon_size or 31
        if v.effects.debuffs.timer_font.name == nil then
            v.effects.debuffs.timer_font.name = LUI_ENUMS.font_name.VERDANA
        end
        v.effects.debuffs.timer_font.size = v.effects.debuffs.timer_font.size or 14
        if v.effects.debuffs.timer_font.style == nil then
            v.effects.debuffs.timer_font.style = LUI_ENUMS.font_style.OUTLINE
        end
        v.effects.debuffs.timer_font.color = v.effects.debuffs.timer_font.color or Turbine.UI.Color(1, 1, 1, 1)
        v.effects.debuffs.timer_font.outline_color = v.effects.debuffs.timer_font.outline_color or
            Turbine.UI.Color(1, 0, 0, 0)
        if v.effects.debuffs.track_curable == nil then
            v.effects.debuffs.track_curable = true
        end
        if v.effects.debuffs.track_noncurable == nil then
            if default_track_noncurable == nil then
                v.effects.debuffs.track_noncurable = true
            else
                v.effects.debuffs.track_noncurable = default_track_noncurable
            end
        end
        v.frame.effects_height = v.frame.effects_height or 200
        if v.frame.effects_position == nil then
            v.frame.effects_position = LUI_ENUMS.vitals_effects_position.ABOVE
        end

        if is_target and v.targets_target ~= nil then
            v.targets_target.width = v.targets_target.width or v.frame.width or 250
            v.targets_target.height = v.targets_target.height or v.power.height or 26
            v.targets_target.border_width = v.targets_target.border_width or v.frame.border_width
            if v.targets_target.window.left == nil then
                v.targets_target.window.left = default_tt_left
            end
            if v.targets_target.window.top == nil then
                v.targets_target.window.top = default_tt_top
            end
            if v.targets_target.font.name == nil then
                v.targets_target.font.name = LUI_ENUMS.font_name.VERDANA
            end
            v.targets_target.font.size = v.targets_target.font.size or 14
            if v.targets_target.font.style == nil then
                v.targets_target.font.style = LUI_ENUMS.font_style.OUTLINE
            end
            v.targets_target.font.color = v.targets_target.font.color or Turbine.UI.Color(1, 1, 1, 1)
            v.targets_target.font.outline_color = v.targets_target.font.outline_color or Turbine.UI.Color(1, 0, 0, 0)
            if v.targets_target.text == nil then
                v.targets_target.text = "%name%"
            end
            if v.targets_target.background_matches_missing == nil then
                v.targets_target.background_matches_missing = true
            end
            if v.targets_target.background_dimming == nil then
                v.targets_target.background_dimming = 0.75
            end
            if v.targets_target.bubble_format == nil then
                v.targets_target.bubble_format = " - %b"
            end
            if v.targets_target.text_alignment == nil then
                v.targets_target.text_alignment = LUI_ENUMS.text_alignment.CENTER
            end
            v.targets_target.text_margin = v.targets_target.text_margin or 4

            local tc = v.targets_target.color
            if tc.background == nil then tc.background = v.morale.color.background end
            if tc.border == nil then tc.border = tc.background end
            if tc.bubble == nil then tc.bubble = v.morale.color.bubble end
            if tc.neutral == nil then tc.neutral = v.morale.color.neutral end
            if tc.high == nil then tc.high = v.morale.color.high end
            if tc.medium == nil then tc.medium = v.morale.color.medium end
            if tc.low == nil then tc.low = v.morale.color.low end
            if tc.critical == nil then tc.critical = v.morale.color.critical end
            if tc.gradient == nil then tc.gradient = true end
            if tc.gradient_full == nil then tc.gradient_full = tc.high end
            if tc.gradient_mid == nil then
                tc.gradient_mid = Turbine.UI.Color(1, 0.847059, 0.776471, 0.235294)
            end
            if tc.gradient_low == nil then tc.gradient_low = tc.critical end
        end
    end

    local self_left = _pos_x(682)
    local self_top = _pos_y(820)
    local target_left = _pos_x(1600)
    local target_top = _pos_y(820)
    local party_left = _pos_x(0)
    local party_top = _pos_y(146)
    local tt_left = _pos_x(1600)
    local tt_top = _pos_y(1200)
    local boss_default_width = 800
    local boss_left = math.floor(((display_w - boss_default_width) / 2) + 0.5)
    local boss_top = math.floor((display_h * 0.10) + 0.5)

    local inv = s.inventory
    if inv.window.left == nil then
        inv.window.left = _pos_x(1980)
    end
    if inv.window.top == nil then
        inv.window.top = _pos_y(585)
    end
    if inv.enabled == nil then
        inv.enabled = true
    end
    if inv.replace == nil then
        inv.replace = true
    end
    if inv.cols == nil then inv.cols = 10 end
    if inv.tile_size == nil then inv.tile_size = 40 end
    inv.tile_pad = nil

    local assets = s.assets
    if assets.window.left == nil then
        assets.window.left = _pos_x(860)
    end
    if assets.window.top == nil then
        assets.window.top = _pos_y(180)
    end
    if assets.enabled == nil then
        assets.enabled = true
    end
    if assets.view_mode ~= LUI_ENUMS.assets_view_mode.ICONS and
        assets.view_mode ~= LUI_ENUMS.assets_view_mode.DETAILS then
        assets.view_mode = LUI_ENUMS.assets_view_mode.DETAILS
    end
    if assets.stack_items == nil then
        assets.stack_items = true
    end
    if assets.tile.icons == nil then assets.tile.icons = 40 end
    if assets.tile.details == nil then assets.tile.details = 40 end
    assets.tile.list = nil
    local assets_default_left = assets.window.left
    local assets_default_top = assets.window.top
    local assets_layouts = assets.layouts
    assets_layouts.list = nil
    local function ensure_assets_layout(layout, default_cols, default_rows)
        if layout.left == nil then
            layout.left = assets_default_left
        end
        if layout.top == nil then
            layout.top = assets_default_top
        end
        if layout.cols == nil then layout.cols = default_cols end
        if layout.rows == nil then layout.rows = default_rows end
    end
    ensure_assets_layout(assets_layouts.icons, 16, 8)
    ensure_assets_layout(assets_layouts.details, 4, 10)

    local cw = s.global.config_window
    if cw.width == nil then cw.width = 1005 end
    if cw.height == nil then cw.height = 1011 end
    if cw.left == nil then cw.left = _pos_x(450) end
    if cw.top == nil then cw.top = _pos_y(51) end

    local tv = s.target.vitals
    if tv.morale.bubble_format == nil then
        tv.morale.bubble_format = " - %b"
    end

    apply_vital_defaults(s.self.vitals, false, "%c / %t - %p", "%c / %t - %p", self_left, self_top, nil, nil, false,
        250)
    apply_vital_defaults(s.target.vitals, true, "[%level%] %name%\\n%c / %t - %p", "%c / %t - %p", target_left,
        target_top, tt_left, tt_top, true, 250)
    apply_vital_defaults(s.target.boss_vitals, false, "[%level%] %name%\\n%c / %t", "%c / %t - %p", boss_left,
        boss_top, nil, nil, true, 800)

    local bv = s.target.boss_vitals
    if bv.enabled == nil then
        bv.enabled = true
    end
    bv.frame.width = bv.frame.width or 800
    bv.frame.border_width = bv.frame.border_width or 1
    bv.frame.effects_height = bv.frame.effects_height or 100
    bv.morale.height = bv.morale.height or 34
    bv.power.height = bv.power.height or 20
    bv.power.width = bv.power.width or 140
    if bv.power.hide == nil then
        bv.power.hide = false
    end
    if bv.power.side == nil then
        bv.power.side = LUI_ENUMS.side.LEFT
    end

    local pv = s.party
    pv.frame.width = pv.frame.width or 110
    pv.window.left = pv.window.left or party_left
    pv.window.top = pv.window.top or party_top
    pv.morale.height = pv.morale.height or 32
    pv.power.height = pv.power.height or 16
    pv.morale.font.size = pv.morale.font.size or 12
    pv.power.font.size = pv.power.font.size or 10
    pv.effects.buffs.icon_size = pv.effects.buffs.icon_size or 32
    pv.effects.debuffs.icon_size = pv.effects.debuffs.icon_size or 36
    apply_vital_defaults(s.party, false, "%name%\\n%c / %t", "%c / %t", party_left, party_top, nil, nil, true, 110)

    local pli = s.party.leader_icon
    if pli.enabled == nil then
        pli.enabled = true
    end
    if pli.size == nil then pli.size = 16 end
    if pli.x == nil then pli.x = 94 end
    if pli.y == nil then pli.y = 8 end

    local pci = s.party.class_icon
    if pci.enabled == nil then
        pci.enabled = true
    end
    if pci.size == nil then pci.size = 16 end
    if pci.x == nil then pci.x = 1 end
    if pci.y == nil then pci.y = 8 end

    local pl = s.party.layout
    if pl.rows == nil then pl.rows = 6 end
    if pl.spacing_x == nil then pl.spacing_x = 0 end
    if pl.spacing_y == nil then pl.spacing_y = 0 end

    local se = s.self.expiring_effects
    if se.enabled == nil then
        se.enabled = true
    end
    if se.show_buffs == nil then
        se.show_buffs = true
    end
    if se.show_curable_debuffs == nil then se.show_curable_debuffs = false end
    if se.show_noncurable_debuffs == nil then se.show_noncurable_debuffs = false end
    if se.icon_side == nil then
        se.icon_side = LUI_ENUMS.side.RIGHT
    end
    if se.bar_expire_towards == nil then
        se.bar_expire_towards = LUI_ENUMS.side.RIGHT
    end
    if se.text_template == nil then se.text_template = "%n  %t" end
    if se.text_alignment == nil then
        se.text_alignment = LUI_ENUMS.text_alignment.LEFT
    end
    if se.name_max_chars == nil then se.name_max_chars = 24 end
    if se.threshold == nil then se.threshold = 5 end
    if se.columns == nil then se.columns = 2 end
    if se.rows == nil then se.rows = 3 end
    if se.spacing == nil then se.spacing = 4 end
    if se.bar_width == nil then se.bar_width = 100 end
    if se.bar_height == nil then se.bar_height = 30 end
    if se.border_width == nil then se.border_width = s.self.vitals.frame.border_width end

    if se.window.left == nil then
        se.window.left = _pos_x(1121)
    end
    if se.window.top == nil then
        se.window.top = _pos_y(921)
    end

    se.color.bar = se.color.bar or Turbine.UI.Color(1, 0.200000, 0.333333, 0.600000)
    se.color.bar_buff = se.color.bar_buff or Turbine.UI.Color(1, 0.149020, 0.701961, 0.749020)
    se.color.bar_debuff_curable = se.color.bar_debuff_curable or Turbine.UI.Color(1, 0.800000, 0.549020, 0.101961)
    se.color.bar_debuff_noncurable = se.color.bar_debuff_noncurable or Turbine.UI.Color(1, 0.901961, 0.250980, 0.250980)
    se.color.background = se.color.background or Turbine.UI.Color(1, 0.0, 0.0, 0.0)
    se.color.border = se.color.border or se.color.background

    if se.font.name == nil then
        se.font.name = LUI_ENUMS.font_name.VERDANA
    end
    se.font.size = se.font.size or 14
    if se.font.style == nil then
        se.font.style = LUI_ENUMS.font_style.OUTLINE
    end
    se.font.color = se.font.color or Turbine.UI.Color(1, 1, 1, 1)
    se.font.outline_color = se.font.outline_color or Turbine.UI.Color(1, 0, 0, 0)

    local ed = s.target.expiring_effects
    if ed.enabled == nil then
        ed.enabled = false
    end
    if ed.show_buffs == nil then
        ed.show_buffs = false
    end
    if ed.show_curable_debuffs == nil then
        ed.show_curable_debuffs = true
    end
    if ed.show_noncurable_debuffs == nil then
        ed.show_noncurable_debuffs = true
    end
    if ed.icon_side == nil then
        ed.icon_side = LUI_ENUMS.side.RIGHT
    end
    if ed.bar_expire_towards == nil then
        ed.bar_expire_towards = LUI_ENUMS.side.RIGHT
    end
    if ed.text_template == nil then ed.text_template = "%n  %t" end
    if ed.text_alignment == nil then
        ed.text_alignment = LUI_ENUMS.text_alignment.LEFT
    end
    if ed.name_max_chars == nil then ed.name_max_chars = 24 end
    if ed.threshold == nil then ed.threshold = 5 end
    if ed.columns == nil then ed.columns = 4 end
    if ed.rows == nil then ed.rows = 2 end
    if ed.spacing == nil then ed.spacing = 4 end
    if ed.bar_width == nil then ed.bar_width = 100 end
    if ed.bar_height == nil then ed.bar_height = 30 end
    if ed.border_width == nil then ed.border_width = s.target.vitals.frame.border_width end

    if ed.window.left == nil then
        ed.window.left = _pos_x(922)
    end
    if ed.window.top == nil then
        ed.window.top = _pos_y(2)
    end

    ed.color.bar = ed.color.bar or Turbine.UI.Color(1, 0.898039, 0.250980, 0.250980)
    ed.color.bar_buff = ed.color.bar_buff or Turbine.UI.Color(1, 0.149020, 0.701961, 0.749020)
    ed.color.bar_debuff_curable = ed.color.bar_debuff_curable or Turbine.UI.Color(1, 0.800000, 0.549020, 0.101961)
    ed.color.bar_debuff_noncurable = ed.color.bar_debuff_noncurable or Turbine.UI.Color(1, 0.901961, 0.250980, 0.250980)
    ed.color.background = ed.color.background or Turbine.UI.Color(1, 0.0, 0.0, 0.0)
    ed.color.border = ed.color.border or ed.color.background

    if ed.font.name == nil then
        ed.font.name = LUI_ENUMS.font_name.VERDANA
    end
    ed.font.size = ed.font.size or 14
    if ed.font.style == nil then
        ed.font.style = LUI_ENUMS.font_style.OUTLINE
    end
    ed.font.color = ed.font.color or Turbine.UI.Color(1, 1, 1, 1)
    ed.font.outline_color = ed.font.outline_color or Turbine.UI.Color(1, 0, 0, 0)

    if s.global.number_abbrev.enabled == nil then
        s.global.number_abbrev.enabled = true
    end
    if s.global.move_mode_shortcut == nil then
        s.global.move_mode_shortcut = true
    end
    s.global.number_abbrev.digits = s.global.number_abbrev.digits or LUI_ENUMS.abbrev_digits.DIGITS_3
    if s.global.number_abbrev.width == nil then
        s.global.number_abbrev.width = LUI_ENUMS.abbrev_width.CHARS_4
    end
    if s.global.number_abbrev.method == nil then
        s.global.number_abbrev.method = LUI_ENUMS.abbrev_method.K_M_B
    end

    local sb = s.status_bar
    if sb.enabled == nil then
        sb.enabled = false
    end

    if sb.bg.opacity == nil then sb.bg.opacity = 0.5 end
    sb.bg.color = sb.bg.color or Turbine.UI.Color(1, 0, 0, 0)

    if sb.height == nil then sb.height = 20 end
    if sb.padding == nil then sb.padding = 6 end
    if sb.gap == nil then sb.gap = 8 end

    if sb.window.left == nil then sb.window.left = _pos_x(200) end
    if sb.window.top == nil then sb.window.top = _pos_y(20) end

    if sb.font.name == nil then
        sb.font.name = LUI_ENUMS.font_name.VERDANA
    end
    if sb.font.size == nil then sb.font.size = 12 end
    if sb.font.style == nil then
        sb.font.style = LUI_ENUMS.font_style.OUTLINE
    end
    sb.font.color = sb.font.color or Turbine.UI.Color(1, 0.768627, 0.768627, 0.768627)
    sb.font.outline_color = sb.font.outline_color or Turbine.UI.Color(1, 0, 0, 0)

    local zones = sb.zones
    if #zones.left == 0 and #zones.center == 0 and #zones.right == 0 then
        zones.left = { "time_local" }
        zones.center = {}
        zones.right = { "inventory_space", "money" }
    end

    if sb.layout.left == nil then
        sb.layout.left = "%time%"
    end
    if sb.layout.center == nil then
        sb.layout.center = ""
    end
    if sb.layout.right == nil then
        sb.layout.right = "%inventory% %gold%"
    end

    local widgets = sb.widgets
    if widgets.time_local.width == nil then widgets.time_local.width = 40 end
    if widgets.time_local.icon == nil then widgets.time_local.icon = false end
    if widgets.time_local.text_alignment == nil then widgets.time_local.text_alignment = LUI_ENUMS.text_alignment.CENTER end

    if widgets.inventory_space.width == nil then widgets.inventory_space.width = 70 end
    if widgets.inventory_space.icon == nil then widgets.inventory_space.icon = true end
    if widgets.inventory_space.text_alignment == nil then
        widgets.inventory_space.text_alignment = LUI_ENUMS
            .text_alignment.LEFT
    end
    local invc = widgets.inventory_space.color
    invc.yellow = invc.yellow or Turbine.UI.Color(1, 0.913725, 0.870588, 0.019608)
    invc.orange = invc.orange or Turbine.UI.Color(1, 0.949020, 0.600000, 0.000000)
    invc.red = invc.red or Turbine.UI.Color(1, 0.905882, 0.113725, 0.000000)

    if widgets.money.width == nil then widgets.money.width = 140 end
    if widgets.money.icon == nil then widgets.money.icon = true end
    if widgets.money.text_alignment == nil then widgets.money.text_alignment = LUI_ENUMS.text_alignment.LEFT end

    local cd = s.self.cooldowns
    if cd.enabled == nil then
        cd.enabled = false
    end
    if cd.threshold == nil then
        cd.threshold = 90.0
    end
    if cd.min_base_cooldown == nil then
        cd.min_base_cooldown = 1.0
    end
    if cd.columns == nil then
        cd.columns = 1
    end
    if cd.rows == nil then
        cd.rows = 6
    end
    if cd.flow == nil then
        cd.flow = LUI_ENUMS.list_flow.BOTTOM_TO_TOP
    end
    if cd.spacing == nil then
        cd.spacing = 4
    end
    if cd.border_width == nil then
        cd.border_width = 1
    end

    if cd.item_w == nil then
        cd.item_w = 150
    end
    if cd.item_h == nil then
        cd.item_h = 26
    end
    if cd.icon_side == nil then
        cd.icon_side = LUI_ENUMS.side.RIGHT
    end
    if cd.bar_expire_towards == nil then
        cd.bar_expire_towards = LUI_ENUMS.side.RIGHT
    end
    if cd.bar_mode == nil then
        cd.bar_mode = LUI_ENUMS.bar_mode.UNLOAD
    end

    if cd.text_template == nil or cd.text_template == "" then
        cd.text_template = "%name%\\n%t"
    end
    if cd.text_alignment == nil then
        cd.text_alignment = LUI_ENUMS.text_alignment.CENTER
    end
    if cd.text_margin == nil then
        cd.text_margin = 4
    end
    if cd.name_max_chars == nil then
        cd.name_max_chars = 24
    end

    if cd.whitelist == nil then
        cd.whitelist = ""
    end
    if cd.blacklist == nil then
        cd.blacklist = ""
    end

    if cd.window.left == nil then
        cd.window.left = _pos_x(453)
    end
    if cd.window.top == nil then
        cd.window.top = _pos_y(1054)
    end

    cd.color.background = cd.color.background or Turbine.UI.Color(1, 0.0, 0.0, 0.0)
    cd.color.bar = cd.color.bar or Turbine.UI.Color(1, 0.0, 0.545098, 0.545098) -- #008B8B dark cyan
    cd.color.border = cd.color.border or Turbine.UI.Color(1, 0.0, 0.0, 0.0) -- #000000

    if cd.font.name == nil then
        cd.font.name = LUI_ENUMS.font_name.VERDANA
    end
    if cd.font.size == nil then
        cd.font.size = 12
    end
    if cd.font.style == nil then
        cd.font.style = LUI_ENUMS.font_style.OUTLINE
    end
    cd.font.color = cd.font.color or Turbine.UI.Color(1, 1, 1, 1) -- #FFFFFF
    cd.font.outline_color = cd.font.outline_color or Turbine.UI.Color(1, 0, 0, 0) -- #000000
end
