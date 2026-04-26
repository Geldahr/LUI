import "LUI.src.Settings.Tabs.Global.global_page"
import "LUI.src.Settings.Tabs.Self.self_page"
import "LUI.src.Settings.Tabs.Target.target_page"
import "LUI.src.Settings.Tabs.Party.party_page"
import "LUI.src.Settings.Tabs.Inventory.inventory_page"
import "LUI.src.Settings.Tabs.Crafting.crafting_page"
import "LUI.src.Settings.Tabs.Travel.travel_page"
import "LUI.src.Settings.Tabs.Assets.assets_page"
import "LUI.src.Settings.Tabs.StatusBar.status_bar_page"
import "LUI.src.Settings.Tabs.ProfileManager.profile_manager_page"
import "LUI.src.Settings.Tabs.Help.help_page"

local GlobalPage = LUI.src.Settings.Tabs.Global.GlobalPage
local SelfPage = LUI.src.Settings.Tabs.Self.SelfPage
local TargetPage = LUI.src.Settings.Tabs.Target.TargetPage
local PartyPage = LUI.src.Settings.Tabs.Party.PartyPage
local InventoryPage = LUI.src.Settings.Tabs.Inventory.InventoryPage
local CraftingPage = LUI.src.Settings.Tabs.Crafting.CraftingPage
local TravelPage = LUI.src.Settings.Tabs.Travel.TravelPage
local AssetsPage = LUI.src.Settings.Tabs.Assets.AssetsPage
local StatusBarPage = LUI.src.Settings.Tabs.StatusBar.StatusBarPage
local ProfileManagerPage = LUI.src.Settings.Tabs.ProfileManager.ProfileManagerPage
local HelpPage = LUI.src.Settings.Tabs.Help.HelpPage

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

local function _apply_main_tab_content_border(window, page)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    window.main_tab_bar:set_show_content_border(page ~= nil and page.show_main_content_border == true)
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
    _apply_main_tab_content_border(self, page)
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
    local global_page = GlobalPage(self)
    global_page._tab_key = "global"
    self.main_tab_bar:add_tab(TR["Global"], global_page)

    local self_page = SelfPage(self)
    self_page._tab_key = "self"
    self.main_tab_bar:add_tab(TR["Self"], self_page)

    local target_page = TargetPage(self)
    target_page._tab_key = "target"
    self.main_tab_bar:add_tab(TR["Target"], target_page)

    local party_page = PartyPage(self)
    party_page._tab_key = "party"
    self.main_tab_bar:add_tab(TR["Party"], party_page)

    local inventory_page = InventoryPage(self)
    inventory_page._tab_key = "inventory"
    self.main_tab_bar:add_tab(TR["Inventory"], inventory_page)

    local crafting_page = CraftingPage(self)
    crafting_page._tab_key = "crafting"
    self.main_tab_bar:add_tab(TR["Crafting"], crafting_page)

    local travel_page = TravelPage(self)
    travel_page._tab_key = "travel"
    self.main_tab_bar:add_tab(TR["Travel"], travel_page)

    local assets_page = AssetsPage(self)
    assets_page._tab_key = "assets"
    self.main_tab_bar:add_tab(TR["Assets"], assets_page)

    local status_bar_page = StatusBarPage(self)
    status_bar_page._tab_key = "status_bar"
    self.main_tab_bar:add_tab(TR["Status Bar"], status_bar_page)

    local profile_manager_page = ProfileManagerPage(self)
    profile_manager_page._tab_key = "profile_manager"
    self.main_tab_bar:add_tab(TR["Profiles"], profile_manager_page)

    local help_page = HelpPage(self)
    help_page._tab_key = "help"
    self.main_tab_bar:add_tab(TR["Help"], help_page)
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
