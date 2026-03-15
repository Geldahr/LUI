Global = {
    key = "global",
    text = TR("Global"),
}

function Global.create_controls(window, ui)
    local digits_help = table.concat({
        TR("How many digits are shown before shortening."),
        TR("3 digits: 999 -> 999, 1000 -> 1.0k, 1000000 -> 1.0M"),
        TR("4 digits: 9999 -> 9999, 10000 -> 10.0k, 1000000 -> 1000k"),
    }, "\n")
    local width_help = table.concat({
        TR("Maximum number of characters used by the shortened numeric part. The decimal point counts. Values are truncated, never rounded up."),
        TR("3 chars: 1000 -> 1.0k, 10000 -> 10k, 100000 -> 100k"),
        TR("4 chars: 1000 -> 1.0k, 10000 -> 10.0k, 1000000 -> 1000k"),
    }, "\n")
    local method_help = table.concat({
        TR("Which style is used for all shortened numbers."),
        TR("k / M / G: 2500000000 -> 2.5G"),
        TR("k / M / B: 2500000000 -> 2.5B"),
        TR("k / m / M: 2500000000 -> 2.5M"),
        TR("e3 / e6 / e9: 2500000000 -> 2.5e9"),
    }, "\n")

    ui.add_text("scale", TR("UI Scale"))

    ui.add_text("refresh_rate", TR("Refresh rate of some UI elements (fps)"))
    ui.add_checkbox("move_mode_shortcut", TR("Use LotRO move mode shortcut"))

    ui.add_checkbox("abbrev_enabled", TR("Shorten large numbers"))
    ui.add_dropdown("abbrev_digits", TR("Digits Before Shortening"), ui.abbrev_digits_labels, ui.abbrev_digits_values,
        digits_help)
    ui.add_dropdown("abbrev_width", TR("Max Shortened Width"), ui.abbrev_width_labels, ui.abbrev_width_values,
        width_help)
    ui.add_dropdown("abbrev_method", TR("Shortening Style"), ui.abbrev_method_labels, ui.abbrev_method_values,
        method_help)
end

function Global.register(window, ui)
    return {
        ui.add_title(TR("Global")),
        ui.add_break(),
        window.controls.scale,
        window.controls.refresh_rate,
        window.controls.move_mode_shortcut,

        ui.add_hr(),
        ui.add_title(TR("Numbers")),
        window.controls.abbrev_enabled,
        window.controls.abbrev_digits,
        window.controls.abbrev_width,
        window.controls.abbrev_method,
    }
end

function Global.load(window, s)
    window.controls.scale.tb:SetText(tostring(s.global.scale))
    window.controls.refresh_rate.tb:SetText(tostring(s.global.refresh_rate))

    local abbrev = s.global.number_abbrev
    window.controls.move_mode_shortcut.cb:SetChecked(s.global.move_mode_shortcut == true)
    window.controls.abbrev_enabled.cb:SetChecked(abbrev.enabled == true)
    window.controls.abbrev_digits:set_value(abbrev.digits)
    window.controls.abbrev_width:set_value(abbrev.width)
    window.controls.abbrev_method:set_value(abbrev.method)
end

function Global.apply(window, s)
    local scale = tonumber(window.controls.scale.tb:GetText())
    if scale ~= nil and scale > 0 then
        s.global.scale = scale
    end
    local refresh_rate = tonumber(window.controls.refresh_rate.tb:GetText())
    if refresh_rate ~= nil and refresh_rate > 0 then
        s.global.refresh_rate = refresh_rate
    end

    s.global.move_mode_shortcut = window.controls.move_mode_shortcut.cb:IsChecked() == true
    s.global.number_abbrev.enabled = window.controls.abbrev_enabled.cb:IsChecked()
    s.global.number_abbrev.digits = window.controls.abbrev_digits:get_value()
    s.global.number_abbrev.width = window.controls.abbrev_width:get_value()
    s.global.number_abbrev.method = window.controls.abbrev_method:get_value()
end
