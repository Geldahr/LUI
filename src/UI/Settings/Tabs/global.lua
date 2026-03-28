import "LUI.src.UI.Settings.Tabs.global_page"

Global = {
    key = "global",
    text = TR("Global"),
}

local function _page(window)
    return window ~= nil and window._tab_pages ~= nil and window._tab_pages.global or nil
end

function Global.create_page(window)
    return GlobalPage(window)
end

function Global.load(window, s)
    local page = _page(window)
    if page == nil then
        return
    end

    local controls = page.controls
    page.loading = true
    controls.scale.tb:SetText(tostring(s.global.scale))
    controls.refresh_rate.tb:SetText(tostring(s.global.refresh_rate))

    local abbrev = s.global.number_abbrev
    controls.move_mode_shortcut.cb:SetChecked(s.global.move_mode_shortcut == true)
    local english_only = is_lui_english_language == nil or is_lui_english_language() == true
    controls.bestiary_capture.cb:SetChecked(english_only == true and s.global.bestiary_capture == true)
    if controls.bestiary_capture.cb.SetEnabled ~= nil then
        controls.bestiary_capture.cb:SetEnabled(english_only == true)
    end
    controls.abbrev_enabled.cb:SetChecked(abbrev.enabled == true)
    controls.abbrev_digits:set_value(abbrev.digits)
    controls.abbrev_width:set_value(abbrev.width)
    controls.abbrev_method:set_value(abbrev.method)
    page.loading = false
    page:layout()
end

function Global.apply(window, s)
    local page = _page(window)
    if page == nil then
        return
    end

    local controls = page.controls
    local scale = tonumber(controls.scale.tb:GetText())
    if scale ~= nil and scale > 0 then
        s.global.scale = scale
    end
    local refresh_rate = tonumber(controls.refresh_rate.tb:GetText())
    if refresh_rate ~= nil and refresh_rate > 0 then
        s.global.refresh_rate = refresh_rate
    end

    s.global.move_mode_shortcut = controls.move_mode_shortcut.cb:IsChecked() == true
    if is_lui_english_language == nil or is_lui_english_language() == true then
        s.global.bestiary_capture = controls.bestiary_capture.cb:IsChecked() == true
    else
        s.global.bestiary_capture = false
    end
    s.global.number_abbrev.enabled = controls.abbrev_enabled.cb:IsChecked()
    s.global.number_abbrev.digits = controls.abbrev_digits:get_value()
    s.global.number_abbrev.width = controls.abbrev_width:get_value()
    s.global.number_abbrev.method = controls.abbrev_method:get_value()
end
