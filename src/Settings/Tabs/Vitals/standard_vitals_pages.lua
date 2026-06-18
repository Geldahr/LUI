local TR = _G.LUI.Locale.TR
local SearchQuery = _G.LUI.Utils.SearchQuery
local Coords = _G.LUI.Utils.Coords
local is_boss_target = _G.LUI.Utils.is_boss_target
local lui_tokenize_format = _G.LUI.Utils.lui_tokenize_format
local lui_format_tokenized = _G.LUI.Utils.lui_format_tokenized
local lui_format_timeout = _G.LUI.Utils.lui_format_timeout
local lui_format_timeout_seconds = _G.LUI.Utils.lui_format_timeout_seconds
local lui_vitals_layout_label = _G.LUI.Utils.lui_vitals_layout_label
local lui_timed_row_resolved_font_size = _G.LUI.Utils.lui_timed_row_resolved_font_size
local lui_timed_row_estimate_text_width = _G.LUI.Utils.lui_timed_row_estimate_text_width
local lui_timed_row_format_time = _G.LUI.Utils.lui_timed_row_format_time
local lui_timed_row_text_gap = _G.LUI.Utils.lui_timed_row_text_gap
local lui_timed_row_time_label_width = _G.LUI.Utils.lui_timed_row_time_label_width
local lui_timed_row_min_name_width = _G.LUI.Utils.lui_timed_row_min_name_width
local lui_timed_row_min_timed_bar_width = _G.LUI.Utils.lui_timed_row_min_timed_bar_width
local lui_timed_row_min_item_width = _G.LUI.Utils.lui_timed_row_min_item_width
local lui_format_cooldown_time = _G.LUI.Utils.lui_format_cooldown_time
local lui_cooldown_resolved_font_size = _G.LUI.Utils.lui_cooldown_resolved_font_size
local lui_cooldown_estimate_text_width = _G.LUI.Utils.lui_cooldown_estimate_text_width
local lui_cooldown_text_gap = _G.LUI.Utils.lui_cooldown_text_gap
local lui_cooldown_time_label_width = _G.LUI.Utils.lui_cooldown_time_label_width
local lui_cooldown_min_name_width = _G.LUI.Utils.lui_cooldown_min_name_width
local lui_cooldown_min_timed_bar_width = _G.LUI.Utils.lui_cooldown_min_timed_bar_width
local lui_cooldown_min_item_width = _G.LUI.Utils.lui_cooldown_min_item_width
local lui_clamp_ratio = _G.LUI.Utils.lui_clamp_ratio
local lui_dim_color = _G.LUI.Utils.lui_dim_color
local lui_lerp_number = _G.LUI.Utils.lui_lerp_number
local lui_lerp_color = _G.LUI.Utils.lui_lerp_color
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local lui_gradient_morale_color = _G.LUI.Utils.lui_gradient_morale_color
local lui_color_to_hex = _G.LUI.Utils.lui_color_to_hex
local lui_hex_to_color = _G.LUI.Utils.lui_hex_to_color
local lui_abbrev_number = _G.LUI.Utils.lui_abbrev_number
local lui_set_number_abbrev_preview_settings = _G.LUI.Utils.lui_set_number_abbrev_preview_settings
local lui_clear_number_abbrev_preview_settings = _G.LUI.Utils.lui_clear_number_abbrev_preview_settings
local lui_abbrev_gold = _G.LUI.Utils.lui_abbrev_gold
local ConfigSectionPage = _G.LUI.Settings.Content.ConfigSectionPage
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local Pages = _G.LUI.Settings.Pages

local Builder = Pages.StandardVitalsPageBuilder or {}
Pages.StandardVitalsPageBuilder = Builder

function Builder.new_standard_unit_page(window, root, options, deps)
    local get = function()
        return options.get_settings(root)
    end

    local page = deps.ConfigSectionPage(window, options.preview_key, options.preview_height, function(win)
        win[options.preview_method](win)
    end)

    local frame = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.add_number_field(frame, options.prefix .. "_width", TR["Frame Width"], function() return get().frame.width end,
        function(value) get().frame.width = value end)
    deps.add_number_field(frame, options.prefix .. "_border_width", TR["Border Width"],
        function() return get().frame.border_width end,
        function(value) get().frame.border_width = value end)
    frame:add_row_break()
    deps.add_number_field(frame, options.prefix .. "_effects_height", TR["Effects Height"],
        function() return get().frame.effects_height end,
        function(value) get().frame.effects_height = value end)
    frame:add_row_break()
    deps.add_number_field(frame, options.prefix .. "_incombat_opacity", TR["In-combat opacity"],
        function() return get().frame.incombat_opacity end,
        function(value) get().frame.incombat_opacity = value end)
    deps.add_number_field(frame, options.prefix .. "_outcombat_opacity", TR["Out-of-combat opacity"],
        function() return get().frame.outcombat_opacity end,
        function(value) get().frame.outcombat_opacity = value end)
    page:add_tab(TR["Frame"], "frame", frame)

    local colors = deps.new_standard_colors_section(window, page.refresh_preview, options.prefix, get,
        options.show_outline_settings)
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_standard_morale_form(morale, options.prefix, get)
    page:add_tab(TR["Morale"], "morale", morale)

    local power = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_standard_power_form(power, options.prefix, get, options.boss_power_mode == true)
    page:add_tab(TR["Power / Wrath"], "power", power)

    local info = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_info_form(info, options.prefix, get)
    page:add_tab(TR["Info"], "info", info)

    page:add_tab(TR["Texts"], "texts", deps.new_texts_section(window, page.refresh_preview, options.prefix, get))
    page:add_tab(TR["Effects"], "effects", deps.new_effects_section(window, page.refresh_preview, options.prefix, get))
    deps.bind_standard_outline_visibility(page, colors, options.prefix, options.show_outline_settings)

    return page
end

function Builder.new_targets_target_unit_page(window, root, deps)
    local get = function()
        return root._settings.target.vitals.targets_target
    end

    local page = deps.ConfigSectionPage(window, "target_targets_target_preview", 133, function(win)
        win:update_target_targets_target_preview()
    end)

    local frame = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.add_number_field(frame, "target_targets_target_width", TR["Frame Width"], function() return get().width end,
        function(value) get().width = value end)
    deps.add_number_field(frame, "target_targets_target_height", TR["Bar Height"], function() return get().height end,
        function(value) get().height = value end)
    deps.add_number_field(frame, "target_targets_target_border_width", TR["Border Width"],
        function() return get().border_width end,
        function(value) get().border_width = value end)
    frame:add_row_break()
    deps.add_text_field(frame, "target_targets_target_bubble_text", TR["Bubble Format (%B)"],
        function() return get().bubble_format end,
        function(value) get().bubble_format = value end,
        frame.bubble_format_help, true)
    page:add_tab(TR["Frame"], "frame", frame)

    local colors = deps.new_targets_target_colors_section(window, page.refresh_preview, get)
    page:add_tab(TR["Colors"], "colors", colors)
    page:add_tab(TR["Texts"], "texts", deps.new_targets_target_texts_section(window, page.refresh_preview, get))
    deps.bind_targets_target_outline_visibility(page, colors)

    return page
end

function Builder.new_general_page(window, root, deps)
    local page = deps.ConfigContent(window, 4)
    page:add_title(TR["General"])
    page:add_checkbox("self_vitals_enabled", TR["Enable self vitals"],
        function(value)
            root._settings.self.vitals.enabled = value == true
        end,
        function()
            return root._settings.self.vitals.enabled == true
        end)
    page:add_checkbox("target_vitals_enabled", TR["Enable target vitals"],
        function(value)
            root._settings.target.vitals.enabled = value == true
        end,
        function()
            return root._settings.target.vitals.enabled == true
        end)
    page:add_checkbox("target_boss_enabled", TR["Enable boss vitals"],
        function(value)
            root._settings.target.boss_vitals.enabled = value == true
        end,
        function()
            return root._settings.target.boss_vitals.enabled == true
        end)
    page:add_checkbox("target_targets_target_enabled", TR["Enable target's target"],
        function(value)
            root._settings.target.vitals.targets_target.enabled = value == true
        end,
        function()
            return root._settings.target.vitals.targets_target.enabled == true
        end)
    page:add_checkbox("fellowship_vitals_enabled", TR["Enable fellowship vitals"],
        function(value)
            root._settings.fellowship.enabled = value == true
        end,
        function()
            return root._settings.fellowship.enabled == true
        end)
    page:add_checkbox("raid_vitals_enabled", TR["Enable raid vitals"],
        function(value)
            root._settings.raid.enabled = value == true
        end,
        function()
            return root._settings.raid.enabled == true
        end)
    return page
end
