import "LUI.src.UI.Settings.Tabs.ProfileManager.profile_manager_page"

ProfileManager = {
    key = "profile_manager",
    text = TR("Profiles"),
}

function ProfileManager.create_page(window)
    return ProfileManagerPage(window)
end

function ProfileManager.load(window)
    local page = window._tab_pages ~= nil and window._tab_pages.profile_manager or nil
    if page ~= nil and page.load ~= nil then
        page:load()
    end
end

function ProfileManager.apply(window)
    local page = window._tab_pages ~= nil and window._tab_pages.profile_manager or nil
    if page ~= nil and page.apply ~= nil then
        page:apply()
    end
end
