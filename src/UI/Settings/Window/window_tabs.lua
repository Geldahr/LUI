import "LUI.src.UI.Settings.Tabs.Global.global_page"
import "LUI.src.UI.Settings.Tabs.Self.self_page"
import "LUI.src.UI.Settings.Tabs.Target.target_page"
import "LUI.src.UI.Settings.Tabs.Party.party_page"
import "LUI.src.UI.Settings.Tabs.Inventory.inventory_page"
import "LUI.src.UI.Settings.Tabs.Assets.assets_page"
import "LUI.src.UI.Settings.Tabs.StatusBar.status_bar_page"
import "LUI.src.UI.Settings.Tabs.ProfileManager.profile_manager_page"
import "LUI.src.UI.Settings.Tabs.Help.help_page"

local GlobalPage = LUI.src.UI.Settings.Tabs.Global.GlobalPage
local SelfPage = LUI.src.UI.Settings.Tabs.Self.SelfPage
local TargetPage = LUI.src.UI.Settings.Tabs.Target.TargetPage
local PartyPage = LUI.src.UI.Settings.Tabs.Party.PartyPage
local InventoryPage = LUI.src.UI.Settings.Tabs.Inventory.InventoryPage
local AssetsPage = LUI.src.UI.Settings.Tabs.Assets.AssetsPage
local StatusBarPage = LUI.src.UI.Settings.Tabs.StatusBar.StatusBarPage
local ProfileManagerPage = LUI.src.UI.Settings.Tabs.ProfileManager.ProfileManagerPage
local HelpPage = LUI.src.UI.Settings.Tabs.Help.HelpPage

local function _normalize_main_tab_request(main_key, preferred_sub_key)
    if type(main_key) ~= "string" then
        return "global", preferred_sub_key
    end

    if main_key == "self_vitals" or main_key == "expiring_effects" or main_key == "cooldowns" then
        return "self", main_key
    end
    if main_key == "target_vitals" or main_key == "target_boss_vitals" or
        main_key == "target_targets_target" or main_key == "expiring_target_effects" then
        return "target", main_key
    end
    if main_key == "party_layout" or main_key == "party_vitals" then
        return "party", main_key
    end

    return main_key, preferred_sub_key
end

local MAIN_TABS_WITH_CONTENT_BORDER = {
    global = true,
    inventory = true,
    assets = true,
    status_bar = true,
    profile_manager = true,
    help = true,
}

local function _apply_main_tab_content_border(window, main_key)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    window.main_tab_bar:set_show_content_border(MAIN_TABS_WITH_CONTENT_BORDER[main_key] == true)
end

local function _find_main_tab(window, main_key)
    if window == nil or window.main_tab_bar == nil then
        return nil, nil
    end

    return window.main_tab_bar:find_index(function(_, page)
        return page ~= nil and page._tab_key == main_key
    end)
end

function ConfigWindow:_on_main_tab_changed(index, page, _, preferred_sub_key)
    if page == nil then
        return
    end

    local main_key = page._tab_key
    self.active_main_tab = main_key
    _apply_main_tab_content_border(self, main_key)
    self._pending_main_tab_sub_key = nil

    self:hide_hint()
    self:layout()

    if page.on_selected ~= nil then
        page:on_selected(preferred_sub_key)
    elseif page.layout ~= nil then
        page:layout()
    end

    if page.get_active_tab_key ~= nil then
        self.active_tab = page:get_active_tab_key() or main_key
    else
        self.active_tab = main_key
    end
end

function ConfigWindow:_activate_active_page()
    local index = self.main_tab_bar ~= nil and self.main_tab_bar:get_selected_index() or nil
    local page = self.main_tab_bar ~= nil and self.main_tab_bar:get_selected_widget() or nil
    if page == nil then
        return
    end

    self:_on_main_tab_changed(index, page, self.main_tab_bar:get_selected_text(), nil)
end

function ConfigWindow:build_tabs()
    self._tab_pages = {}
    self._tab_pages.global = GlobalPage(self)
    self._tab_pages.self = SelfPage(self)
    self._tab_pages.target = TargetPage(self)
    self._tab_pages.party = PartyPage(self)
    self._tab_pages.inventory = InventoryPage(self)
    self._tab_pages.assets = AssetsPage(self)
    self._tab_pages.status_bar = StatusBarPage(self)
    self._tab_pages.profile_manager = ProfileManagerPage(self)
    self._tab_pages.help = HelpPage(self)

    self._tab_pages.global._tab_key = "global"
    self._tab_pages.self._tab_key = "self"
    self._tab_pages.target._tab_key = "target"
    self._tab_pages.party._tab_key = "party"
    self._tab_pages.inventory._tab_key = "inventory"
    self._tab_pages.assets._tab_key = "assets"
    self._tab_pages.status_bar._tab_key = "status_bar"
    self._tab_pages.profile_manager._tab_key = "profile_manager"
    self._tab_pages.help._tab_key = "help"

    self.main_tab_bar:add_tab(TR("Global"), self._tab_pages.global)
    self.main_tab_bar:add_tab(TR("Self"), self._tab_pages.self)
    self.main_tab_bar:add_tab(TR("Target"), self._tab_pages.target)
    self.main_tab_bar:add_tab(TR("Party"), self._tab_pages.party)
    self.main_tab_bar:add_tab(TR("Inventory"), self._tab_pages.inventory)
    self.main_tab_bar:add_tab(TR("Assets"), self._tab_pages.assets)
    self.main_tab_bar:add_tab(TR("Status Bar"), self._tab_pages.status_bar)
    self.main_tab_bar:add_tab(TR("Profiles"), self._tab_pages.profile_manager)
    self.main_tab_bar:add_tab(TR("Help"), self._tab_pages.help)
end

function ConfigWindow:select_main_tab(main_key, preferred_sub_key)
    main_key, preferred_sub_key = _normalize_main_tab_request(main_key, preferred_sub_key)

    local index, page = _find_main_tab(self, main_key)
    if index == nil or page == nil then
        main_key = "global"
        preferred_sub_key = nil
        index, page = _find_main_tab(self, main_key)
    end
    if index == nil or page == nil then
        return
    end

    if self.main_tab_bar ~= nil and self.main_tab_bar:get_selected_index() == index then
        self:_on_main_tab_changed(index, page, self.main_tab_bar:get_selected_text(), preferred_sub_key)
        return
    end

    self._pending_main_tab_sub_key = preferred_sub_key
    self.main_tab_bar:select_tab(index)
end
