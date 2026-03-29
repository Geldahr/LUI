import "LUI.src.Settings.Tabs.Party.party_layout_page"

PartyLayout = {
    key = "party_layout",
    text = TR("Layout"),
}

function PartyLayout.create_page(window)
    return PartyLayoutPage(window)
end

function PartyLayout.load(page, s)
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

function PartyLayout.apply(page, s)
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
