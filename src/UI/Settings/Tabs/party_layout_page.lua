import "LUI.src.UI.Settings.Tabs.form_page"

PartyLayoutPage = class(SettingsFormPage)

function PartyLayoutPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)

    self:add_title(TR("Party Layout"))

    self:add_hr()
    self:add_title(TR("Grid"))
    self:add_text("party_rows", TR("Rows per Column"))
    self:add_break()
    self:add_text("party_spacing_x", TR("Column Spacing"))
    self:add_text("party_spacing_y", TR("Row Spacing"))
end
