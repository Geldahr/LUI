import "LUI.src.UI.Settings.Tabs.ProfileManager.profile_manager_page"

ProfileManager = {
    key = "profile_manager",
    text = TR("Profiles"),
}

function ProfileManager.create_page(window)
    return ProfileManagerPage(window)
end

function ProfileManager.load(window)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "profile_manager"
    end)
    if page ~= nil and page.load_from_settings ~= nil then
        page:load_from_settings()
    end
end

function ProfileManager.apply(window)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "profile_manager"
    end)
    if page ~= nil and page.apply_to_settings ~= nil then
        page:apply_to_settings()
    end
end
