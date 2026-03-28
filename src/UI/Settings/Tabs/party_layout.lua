import "LUI.src.UI.Settings.Tabs.party_layout_page"

PartyLayout = {
    key = "party_layout",
    text = TR("Layout"),
}

local function _page(window)
    return window ~= nil and window._tab_pages ~= nil and window._tab_pages.party_layout or nil
end

function PartyLayout.create_page(window)
    return PartyLayoutPage(window)
end

function PartyLayout.load(window, s)
    local page = _page(window)
    if page == nil then
        return
    end

    local controls = page.controls
    local v = s.party
    page.loading = true
    controls.party_rows.tb:SetText(tostring(v.layout.rows))
    controls.party_spacing_x.tb:SetText(tostring(v.layout.spacing_x))
    controls.party_spacing_y.tb:SetText(tostring(v.layout.spacing_y))
    page.loading = false
end

function PartyLayout.apply(window, s)
    local page = _page(window)
    if page == nil then
        return
    end

    local controls = page.controls
    local v = s.party

    local rows = tonumber(controls.party_rows.tb:GetText())
    if rows ~= nil then
        v.layout.rows = rows
    end

    local sx = tonumber(controls.party_spacing_x.tb:GetText())
    if sx ~= nil then
        v.layout.spacing_x = sx
    end

    local sy = tonumber(controls.party_spacing_y.tb:GetText())
    if sy ~= nil then
        v.layout.spacing_y = sy
    end
end
