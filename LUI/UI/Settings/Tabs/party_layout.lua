PartyLayout = {
    key = "party_layout",
    text = TR("Layout"),
}

function PartyLayout.create_controls(window, ui)
    ui.add_text("party_rows", TR("Rows per Column"))
    ui.add_text("party_spacing_x", TR("Column Spacing"))
    ui.add_text("party_spacing_y", TR("Row Spacing"))
end

function PartyLayout.register(window, ui)
    return {
        ui.add_title(TR("Party Layout")),

        ui.add_hr(),
        ui.add_title(TR("Grid")),
        window.controls.party_rows,
        ui.add_break(),
        window.controls.party_spacing_x,
        window.controls.party_spacing_y,
    }
end

function PartyLayout.load(window, s)
    local v = s.party
    window.controls.party_rows.tb:SetText(tostring(v.layout.rows))
    window.controls.party_spacing_x.tb:SetText(tostring(v.layout.spacing_x))
    window.controls.party_spacing_y.tb:SetText(tostring(v.layout.spacing_y))
end

function PartyLayout.apply(window, s)
    local v = s.party

    local rows = tonumber(window.controls.party_rows.tb:GetText())
    if rows ~= nil then v.layout.rows = rows end

    local sx = tonumber(window.controls.party_spacing_x.tb:GetText())
    if sx ~= nil then v.layout.spacing_x = sx end

    local sy = tonumber(window.controls.party_spacing_y.tb:GetText())
    if sy ~= nil then v.layout.spacing_y = sy end
end
