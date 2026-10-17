-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Encyclopedia settings: the bestiary chat-capture toggle and the search
-- bar mode of every Encyclopedia tab (writes the encyclopedia settings section).

local TR = _G.LUI.Locale.TR
local is_lui_english_language = _G.LUI.Locale.is_english_language
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local class = _G.LUI.Core.class
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"

local EncyclopediaPage = class(ConfigTabs)
Pages.EncyclopediaPage = EncyclopediaPage

function EncyclopediaPage:Constructor(window)
    ConfigTabs.Constructor(self, window)

    local general = ConfigContent(window, 4)
    general:add_checkbox("bestiary_capture", TR["Enable bestiary capture (English client only)"],
        function(value)
            if is_lui_english_language() == true then
                self._settings.encyclopedia.bestiary_capture = value == true
            else
                self._settings.encyclopedia.bestiary_capture = false
            end
        end,
        function()
            return is_lui_english_language() == true and self._settings.encyclopedia.bestiary_capture == true
        end, true)
    general.controls.bestiary_capture.load_fn = function()
        local english_only = is_lui_english_language() == true
        general.controls.bestiary_capture.cb:SetEnabled(english_only == true)
        return english_only == true and self._settings.encyclopedia.bestiary_capture == true
    end
    general:add_row_break()
    general:add_dropdown("search_mode", TR["Search bar"], { TR["Classic"], TR["Tokens"] }, { "classic", "tokens" },
        function(value)
            self._settings.encyclopedia.search_mode = value
        end,
        function()
            return self._settings.encyclopedia.search_mode
        end, TR["Classic: the search runs on every keystroke. Tokens: Enter turns the typed text into a chip and the search runs when chips change."])
    self:add_tab(TR["General"], "general", general)
end
