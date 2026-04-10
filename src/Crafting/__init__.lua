Crafting = Crafting or {}

import "LUI.src.Crafting.crafting_store"
import "LUI.src.Crafting.crafting_window"

local _shared_store = nil

function Crafting.get_shared_store()
    if _shared_store == nil then
        _shared_store = CraftingStore()
        _G.CRAFTING_STORE = _shared_store
    end
    return _shared_store
end

function Crafting.destroy_shared_store()
    if _shared_store ~= nil and _shared_store.destroy ~= nil then
        _shared_store:destroy()
    end
    _shared_store = nil
    _G.CRAFTING_STORE = nil
end

Crafting.CraftingStore = CraftingStore
Crafting.CraftingWindow = CraftingWindow
