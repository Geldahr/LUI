import "LUI.src.UI.Settings.Preview.common"
import "LUI.src.UI.Settings.Preview.self_expiring_effects"
import "LUI.src.UI.Settings.Preview.cooldowns"
import "LUI.src.UI.Settings.Preview.expiring_target_effects"
import "LUI.src.UI.Settings.Preview.target_boss_vitals"
import "LUI.src.UI.Settings.Preview.target_targets_target"
import "LUI.src.UI.Settings.Preview.party_vitals"
import "LUI.src.UI.Settings.Preview.vitals"

function ConfigWindow:_refresh_active_preview()
    if self.main_tab_bar == nil then
        return
    end

    local page = self.main_tab_bar:get_selected_widget()
    if page == nil then
        return
    end

    if page.sub_tab_bar ~= nil then
        local sub_page = page.sub_tab_bar:get_selected_widget()
        if sub_page ~= nil then
            page = sub_page
        end
    end

    if page.refresh_preview ~= nil then
        page:refresh_preview()
    end
    if page.layout ~= nil then
        page:layout()
    end
end
