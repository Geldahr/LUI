SettingsGroupVitalsPageBuilder = SettingsGroupVitalsPageBuilder or {}

local Builder = SettingsGroupVitalsPageBuilder

function Builder.new_group_unit_page(window, root, options, deps)
    local get = function()
        return root._settings[options.settings_root]
    end

    local refresh_preview = function(win)
        win[options.preview_method](win)
    end

    local page = deps.ConfigSectionPage(window, options.preview_key, 178, refresh_preview)

    local frame = deps.ConfigContent(window, 4, page.refresh_preview)
    frame.on_scroll_changed = function()
        window[options.preview_method](window)
    end
    deps.add_number_field(frame, options.prefix .. "_width", TR["Frame Width"], function() return get().frame.width end,
        function(value) get().frame.width = value end)
    deps.add_number_field(frame, options.prefix .. "_border_width", TR["Border Width"],
        function() return get().frame.border_width end,
        function(value) get().frame.border_width = value end)
    frame:add_row_break()
    deps.add_number_field(frame, options.prefix .. "_rows", TR["Rows per Column"], function() return get().layout.rows end,
        function(value) get().layout.rows = value end)
    if options.include_self_toggle == true then
        frame:add_row_break()
        deps.add_checkbox_field(frame, options.prefix .. "_show_self_in_fellowship", TR["Show self in fellowship"],
            function() return get().show_self_in_fellowship end,
            function(value) get().show_self_in_fellowship = value end, true)
    end
    frame:add_row_break()
    deps.add_number_field(frame, options.prefix .. "_spacing_x", TR["Column Spacing"],
        function() return get().layout.spacing_x end,
        function(value) get().layout.spacing_x = value end)
    deps.add_number_field(frame, options.prefix .. "_spacing_y", TR["Row Spacing"],
        function() return get().layout.spacing_y end,
        function(value) get().layout.spacing_y = value end)
    frame:add_row_break()
    deps.add_number_field(frame, options.prefix .. "_incombat_opacity", TR["In-combat opacity"],
        function() return get().frame.incombat_opacity end,
        function(value) get().frame.incombat_opacity = value end)
    deps.add_number_field(frame, options.prefix .. "_outcombat_opacity", TR["Out-of-combat opacity"],
        function() return get().frame.outcombat_opacity end,
        function(value) get().frame.outcombat_opacity = value end)
    frame:add_row_break()
    deps.add_checkbox_field(frame, options.prefix .. "_ressource_background_matches_missing", TR["Matching background"],
        function() return get().background_matches_missing end,
        function(value) get().background_matches_missing = value end)
    deps.add_number_field(frame, options.prefix .. "_ressource_background_dimming", TR["Dimming"],
        function() return get().background_dimming end,
        function(value) get().background_dimming = value end)
    page:add_tab(TR["Frame"], "frame", frame)

    local colors = deps.new_standard_colors_section(window, page.refresh_preview, options.prefix, get, false)
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_standard_morale_form(morale, options.prefix, get)
    page:add_tab(TR["Morale"], "morale", morale)

    local power = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_standard_power_form(power, options.prefix, get, false)
    page:add_tab(TR["Power / Wrath"], "power", power)

    local info = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_info_form(info, options.prefix, get)
    page:add_tab(TR["Info"], "info", info)

    page:add_tab(TR["Texts"], "texts", deps.new_texts_section(window, page.refresh_preview, options.prefix, get))

    local icons = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.add_checkbox_field(icons, options.prefix .. "_class_icon_enabled", TR["Show class icon"],
        function() return get().class_icon.enabled end,
        function(value) get().class_icon.enabled = value end, true)
    icons:add_row_break()
    deps.add_number_field(icons, options.prefix .. "_class_icon_size", TR["Icon Size"],
        function() return get().class_icon.size end,
        function(value) get().class_icon.size = value end)
    icons:add_row_break()
    deps.add_number_field(icons, options.prefix .. "_class_icon_x", TR["Icon X"], function() return get().class_icon.x end,
        function(value) get().class_icon.x = value end)
    deps.add_number_field(icons, options.prefix .. "_class_icon_y", TR["Icon Y"], function() return get().class_icon.y end,
        function(value) get().class_icon.y = value end)
    icons:add_row_break()
    deps.add_checkbox_field(icons, options.prefix .. "_leader_icon_enabled", TR["Show leader icon"],
        function() return get().leader_icon.enabled end,
        function(value) get().leader_icon.enabled = value end, true)
    icons:add_row_break()
    deps.add_number_field(icons, options.prefix .. "_leader_icon_size", TR["Leader Icon Size"],
        function() return get().leader_icon.size end,
        function(value) get().leader_icon.size = value end)
    icons:add_row_break()
    deps.add_number_field(icons, options.prefix .. "_leader_icon_x", TR["Leader Icon X"],
        function() return get().leader_icon.x end,
        function(value) get().leader_icon.x = value end)
    deps.add_number_field(icons, options.prefix .. "_leader_icon_y", TR["Leader Icon Y"],
        function() return get().leader_icon.y end,
        function(value) get().leader_icon.y = value end)
    page:add_tab(TR["Icons"], "icons", icons)

    page:add_tab(TR["Effects"], "effects", deps.new_effects_section(window, page.refresh_preview, options.prefix, get))
    deps.bind_standard_outline_visibility(page, colors, options.prefix, false)

    return page
end
