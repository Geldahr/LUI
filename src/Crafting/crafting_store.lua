import "Turbine.Gameplay"
import "Turbine.UI"

Crafting = Crafting or {}

CraftingStore = class(Turbine.UI.Control)
Crafting.CraftingStore = CraftingStore

local SOURCE_BACKPACK = "backpack"
local SOURCE_BANK = "bank"
local SOURCE_VAULT = "vault"
local SOURCE_SHARED = "shared_storage"
local SOURCE_OTHER_CHARACTERS = "other_characters"
local SOURCE_SCOPE_PREFIX = "sources:"

local FILTER_ALL = "__all"
local SCOPE_SERVER = "server"
local SCOPE_INVENTORY = "inventory"
local SCOPE_PERSONAL = "personal"
local SCOPE_SHARED = "shared"
local RECIPE_LOAD_BATCH_SIZE = 1
local BACKGROUND_UPDATE_EVERY = 0.50
local FOREGROUND_UPDATE_EVERY = 0.20
local FOREGROUND_RECIPE_BATCH_SIZE = 2

local SOURCE_ORDER = {
    SOURCE_BACKPACK,
    SOURCE_BANK,
    SOURCE_VAULT,
    SOURCE_SHARED,
    SOURCE_OTHER_CHARACTERS,
}

local SOURCE_SET = {
    [SOURCE_BACKPACK] = true,
    [SOURCE_BANK] = true,
    [SOURCE_VAULT] = true,
    [SOURCE_SHARED] = true,
    [SOURCE_OTHER_CHARACTERS] = true,
}

local PROFESSION_ORDER = {
    Turbine.Gameplay.Profession.Cook,
    Turbine.Gameplay.Profession.Farmer,
    Turbine.Gameplay.Profession.Forester,
    Turbine.Gameplay.Profession.Jeweller,
    Turbine.Gameplay.Profession.Metalsmith,
    Turbine.Gameplay.Profession.Prospector,
    Turbine.Gameplay.Profession.Scholar,
    Turbine.Gameplay.Profession.Tailor,
    Turbine.Gameplay.Profession.Weaponsmith,
    Turbine.Gameplay.Profession.Woodworker,
}

local function _safe_string(value, fallback)
    if value == nil then
        return fallback or ""
    end
    return tostring(value)
end

local function _trim(text)
    local value = _safe_string(text, "")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")
    return value
end

local function _lower(text)
    return string.lower(_safe_string(text, ""))
end

local function _normalize_name(name)
    local value = _trim(name)
    if value == "" then
        return ""
    end
    value = value:gsub("%s+", " ")
    return _lower(value)
end

local function _copy_counts(source)
    local out = {}
    if type(source) ~= "table" then
        return out
    end

    for key, value in pairs(source) do
        out[key] = value
    end

    return out
end

local function _copy_array(source)
    local out = {}
    if type(source) ~= "table" then
        return out
    end
    for i = 1, #source do
        out[#out + 1] = source[i]
    end
    return out
end

local function _add_count(map, key, quantity)
    local amount = tonumber(quantity) or 0
    if type(map) ~= "table" or key == nil or key == "" or amount <= 0 then
        return
    end
    map[key] = (map[key] or 0) + amount
end

local function _normalize_source_keys(source_keys)
    local selected = {}
    if type(source_keys) == "table" then
        for i = 1, #source_keys do
            local key = source_keys[i]
            if SOURCE_SET[key] == true then
                selected[key] = true
            end
        end
    elseif type(source_keys) == "string" then
        local encoded = source_keys
        if string.sub(encoded, 1, string.len(SOURCE_SCOPE_PREFIX)) == SOURCE_SCOPE_PREFIX then
            encoded = string.sub(encoded, string.len(SOURCE_SCOPE_PREFIX) + 1)
        end
        for key in string.gmatch(encoded, "[^,]+") do
            if SOURCE_SET[key] == true then
                selected[key] = true
            end
        end
    end

    local out = {}
    for i = 1, #SOURCE_ORDER do
        local key = SOURCE_ORDER[i]
        if selected[key] == true then
            out[#out + 1] = key
        end
    end
    return out
end

local function _source_scope_key(source_keys)
    local normalized = _normalize_source_keys(source_keys)
    return SOURCE_SCOPE_PREFIX .. table.concat(normalized, ",")
end

local function _is_source_scope_key(scope_key)
    return type(scope_key) == "table" or
        (type(scope_key) == "string" and string.sub(scope_key, 1, string.len(SOURCE_SCOPE_PREFIX)) == SOURCE_SCOPE_PREFIX)
end

local function _source_keys_from_scope(scope_key)
    if _is_source_scope_key(scope_key) == true then
        return _normalize_source_keys(scope_key)
    end
    if scope_key == SCOPE_INVENTORY then
        return { SOURCE_BACKPACK }
    end
    if scope_key == SCOPE_SHARED then
        return { SOURCE_SHARED }
    end
    if scope_key == SCOPE_SERVER then
        return _copy_array(SOURCE_ORDER)
    end
    return { SOURCE_BACKPACK, SOURCE_BANK, SOURCE_VAULT }
end

local function _normalized_scope_key(scope_key)
    if _is_source_scope_key(scope_key) == true then
        return _source_scope_key(scope_key)
    end
    if scope_key == SCOPE_SERVER or scope_key == SCOPE_INVENTORY or scope_key == SCOPE_PERSONAL or scope_key == SCOPE_SHARED then
        return scope_key
    end
    return SCOPE_PERSONAL
end

local function _count_map_signature(counts)
    if type(counts) ~= "table" then
        return ""
    end

    local keys = {}
    for key, quantity in pairs(counts) do
        if key ~= nil and key ~= "" and (tonumber(quantity) or 0) > 0 then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)

    local parts = {}
    for i = 1, #keys do
        local key = keys[i]
        parts[#parts + 1] = key .. "\31" .. tostring(tonumber(counts[key]) or 0)
    end

    return table.concat(parts, "\30")
end

local function _sum_missing_map(missing_map)
    local total = 0
    if type(missing_map) ~= "table" then
        return total
    end

    for _, entry in pairs(missing_map) do
        if type(entry) == "table" then
            total = total + (tonumber(entry.quantity) or 0)
        end
    end

    return total
end

local function _sort_missing_list(left, right)
    local left_name = _lower(left ~= nil and left.name or nil)
    local right_name = _lower(right ~= nil and right.name or nil)
    if left_name ~= right_name then
        return left_name < right_name
    end

    return (tonumber(left ~= nil and left.quantity or nil) or 0) > (tonumber(right ~= nil and right.quantity or nil) or 0)
end

local function _missing_map_to_list(missing_map)
    local out = {}
    if type(missing_map) ~= "table" then
        return out
    end

    for _, entry in pairs(missing_map) do
        if type(entry) == "table" and (tonumber(entry.quantity) or 0) > 0 then
            out[#out + 1] = entry
        end
    end

    table.sort(out, _sort_missing_list)
    return out
end

local function _collect_leaf_requirements(node, out)
    if type(node) ~= "table" or type(out) ~= "table" then
        return
    end

    local children = node.children
    if type(children) ~= "table" or #children == 0 then
        local key = node.key
        if key ~= nil and key ~= "" then
            if type(out[key]) ~= "table" then
                out[key] = {
                    key = key,
                    quantity = 0,
                }
            end
            out[key].quantity = (tonumber(out[key].quantity) or 0) + (tonumber(node.required) or 0)
        end
        return
    end

    for i = 1, #children do
        _collect_leaf_requirements(children[i], out)
    end
end

local function _resource_progress_sort_compare(left, right)
    local left_complete = left ~= nil and left.complete == true
    local right_complete = right ~= nil and right.complete == true
    if left_complete ~= right_complete then
        return left_complete ~= true
    end

    local left_missing = tonumber(left ~= nil and left.missing or nil) or 0
    local right_missing = tonumber(right ~= nil and right.missing or nil) or 0
    if left_missing ~= right_missing then
        return left_missing > right_missing
    end

    local left_required = tonumber(left ~= nil and left.required or nil) or 0
    local right_required = tonumber(right ~= nil and right.required or nil) or 0
    if left_required ~= right_required then
        return left_required > right_required
    end

    local left_name = _lower(left ~= nil and left.name or nil)
    local right_name = _lower(right ~= nil and right.name or nil)
    return left_name < right_name
end

local function _saved_plan_entry_matches_recipe(saved_entry, recipe)
    if type(saved_entry) ~= "table" or type(recipe) ~= "table" then
        return false
    end

    if saved_entry.profession_key ~= nil and tostring(saved_entry.profession_key) ~= tostring(recipe.profession_key) then
        return false
    end
    if saved_entry.result_key ~= nil and tostring(saved_entry.result_key) ~= tostring(recipe.result_key) then
        return false
    end
    if saved_entry.recipe_name_key ~= nil and tostring(saved_entry.recipe_name_key) ~= tostring(recipe.recipe_name_key or recipe.result_key or "") then
        return false
    end
    if saved_entry.category_name_key ~= nil and tostring(saved_entry.category_name_key) ~= _normalize_name(recipe.category_name) then
        return false
    end
    if saved_entry.tier ~= nil and (tonumber(saved_entry.tier) or 0) ~= (tonumber(recipe.tier) or 0) then
        return false
    end

    return true
end

local function _append_token(parts, value)
    local text = _safe_string(value, "")
    if text ~= "" then
        parts[#parts + 1] = text
    end
end

local function _current_character_name()
    if type(_G.current_character_name) == "string" and _G.current_character_name ~= "" then
        return _G.current_character_name
    end

    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    local name = player ~= nil and player:GetName() or nil
    name = _trim(name)
    if name ~= "" then
        return name
    end

    return "__unknown_character__"
end

local function _item_info_icon_id(item_info)
    if item_info == nil then
        return nil
    end
    local icon_id = tonumber(item_info:GetIconImageID())
    if icon_id == 0 then
        icon_id = nil
    end
    return icon_id
end

local function _item_info_background_id(item_info)
    if item_info == nil then
        return nil
    end
    local background_id = tonumber(item_info:GetBackgroundImageID())
    if background_id == nil or background_id == 0 then
        background_id = tonumber(item_info:GetQualityImageID())
        if background_id == 0 then
            background_id = nil
        end
    end
    return background_id
end

local function _item_info_quality(item_info)
    if item_info == nil then
        return nil
    end
    return item_info:GetQuality()
end

local function _item_info_category(item_info)
    if item_info == nil then
        return nil
    end
    return tonumber(item_info:GetCategory())
end

local function _item_info_description(item_info)
    if item_info == nil then
        return ""
    end
    return _trim(item_info:GetDescription())
end

local function _item_info_max_quantity(item_info)
    if item_info == nil then
        return nil
    end
    return tonumber(item_info:GetMaxQuantity())
end

local function _item_info_max_stack_size(item_info)
    if item_info == nil then
        return nil
    end
    return tonumber(item_info:GetMaxStackSize())
end

local function _item_info_is_magic(item_info)
    return item_info ~= nil and item_info:IsMagic() == true and 1 or 0
end

local function _item_info_is_unique(item_info)
    return item_info ~= nil and item_info:IsUnique() == true and 1 or 0
end

local function _positive_integer(value)
    local number = tonumber(value)
    if number == nil then
        return nil
    end
    number = math.floor(number + 0.5)
    if number <= 0 then
        return nil
    end
    return number
end

local function _extract_level_from_text(text)
    if type(text) ~= "string" or text == "" then
        return nil
    end

    local patterns = {
        "%([Ll]evel%s+(%d+)%)",
        "%([Nn]iveau%s+(%d+)%)",
        "%([Ss]tufe%s+(%d+)%)",
        "[Mm]inimum%s+[Ll]evel%s*:?%s*(%d+)",
        "[Rr]equires%s+[Ll]evel%s*:?%s*(%d+)",
        "[Nn]iveau%s+minimum%s*:?%s*(%d+)",
        "[Mm]indeststufe%s*:?%s*(%d+)",
    }

    for i = 1, #patterns do
        local level = _positive_integer(string.match(text, patterns[i]))
        if level ~= nil then
            return level
        end
    end

    return nil
end

local function _item_info_required_level(item_info)
    if item_info == nil then
        return nil
    end

    local method_names = {
        "GetRequiredLevel",
        "GetMinimumLevel",
        "GetMinLevel",
    }

    for i = 1, #method_names do
        local method = item_info[method_names[i]]
        if type(method) == "function" then
            local level = _positive_integer(method(item_info))
            if level ~= nil then
                return level
            end
        end
    end

    local level = _extract_level_from_text(item_info:GetName())
    if level ~= nil then
        return level
    end

    level = _extract_level_from_text(item_info:GetDescription())
    if level ~= nil then
        return level
    end

    return nil
end

local function _recipe_required_level(result_info, recipe_name, category_name)
    local level = _item_info_required_level(result_info)
    if level ~= nil then
        return level
    end

    level = _extract_level_from_text(category_name)
    if level ~= nil then
        return level
    end

    level = _extract_level_from_text(recipe_name)
    if level ~= nil then
        return level
    end

    return nil
end

local function _remember_item(items, key, name, item_info)
    if key == nil or key == "" then
        return
    end

    local current = items[key]
    if type(current) ~= "table" then
        current = {
            key = key,
            name = _trim(name),
            icon_id = nil,
            background_image_id = nil,
            quality = nil,
            required_level = nil,
            item_info = nil,
        }
        items[key] = current
    end

    if current.name == nil or current.name == "" then
        current.name = _trim(name)
    end

    if current.icon_id == nil then
        current.icon_id = _item_info_icon_id(item_info)
    end
    if current.background_image_id == nil then
        current.background_image_id = _item_info_background_id(item_info)
    end
    if current.quality == nil then
        current.quality = _item_info_quality(item_info)
    end
    if current.required_level == nil then
        current.required_level = _item_info_required_level(item_info)
    end
    if current.item_info == nil then
        current.item_info = item_info
    end
end

local function _copy_asset_record(record)
    if type(record) ~= "table" then
        return nil
    end

    return {
        name = record.name,
        quantity = record.quantity,
        owner = record.owner,
        source_key = record.source_key,
        source_name = record.source_name,
        icon_id = record.icon_id,
        background_image_id = record.background_image_id,
        quality = record.quality,
        item_info = record.item_info,
    }
end

local function _collect_asset_entries_from_cache()
    local entries = {}
    local cache = _G.ensure_assets_cache ~= nil and _G.ensure_assets_cache() or _G.assets_cache
    if type(cache) ~= "table" then
        return entries
    end

    local characters = type(cache.characters) == "table" and cache.characters or {}
    local character_names = {}
    for character_name, _ in pairs(characters) do
        character_names[#character_names + 1] = character_name
    end
    table.sort(character_names, function(left, right)
        return _lower(left) < _lower(right)
    end)

    local function append_items(items)
        if type(items) ~= "table" then
            return
        end
        for i = 1, #items do
            local copy = _copy_asset_record(items[i])
            if copy ~= nil then
                entries[#entries + 1] = copy
            end
        end
    end

    for i = 1, #character_names do
        local character_cache = characters[character_names[i]]
        if type(character_cache) == "table" then
            append_items(character_cache.backpack ~= nil and character_cache.backpack.items or nil)
            append_items(character_cache.bank ~= nil and character_cache.bank.items or nil)
            append_items(character_cache.vault ~= nil and character_cache.vault.items or nil)
        end
    end

    append_items(cache.shared_storage ~= nil and cache.shared_storage.items or nil)
    return entries
end

local function _scope_option_labels()
    return {
        TR["This character"],
        TR["Backpack only"],
        TR["Server-wide"],
    }
end

local function _scope_option_values()
    return {
        SCOPE_PERSONAL,
        SCOPE_INVENTORY,
        SCOPE_SERVER,
    }
end

local function _source_option_labels()
    return {
        TR["Backpack"],
        TR["Bank"],
        TR["Vault"],
        TR["Shared Storage"],
        TR["Other characters"],
    }
end

local function _source_option_values()
    return _copy_array(SOURCE_ORDER)
end

local function _recipe_sort_compare(items, left, right)
    local left_profession = _lower(left ~= nil and left.profession_name or nil)
    local right_profession = _lower(right ~= nil and right.profession_name or nil)
    if left_profession ~= right_profession then
        return left_profession < right_profession
    end

    local left_item = type(items) == "table" and items[left ~= nil and left.result_key or nil] or nil
    local right_item = type(items) == "table" and items[right ~= nil and right.result_key or nil] or nil
    local left_name = _lower(left_item ~= nil and left_item.name or nil)
    local right_name = _lower(right_item ~= nil and right_item.name or nil)
    if left_name ~= right_name then
        return left_name < right_name
    end

    local left_recipe_name = _lower(left ~= nil and left.recipe_name or nil)
    local right_recipe_name = _lower(right ~= nil and right.recipe_name or nil)
    if left_recipe_name ~= right_recipe_name then
        return left_recipe_name < right_recipe_name
    end

    return _lower(left ~= nil and left.id or nil) < _lower(right ~= nil and right.id or nil)
end

local function _recipe_reenters_path(recipe, visiting)
    if type(recipe) ~= "table" or type(recipe.ingredients) ~= "table" or type(visiting) ~= "table" then
        return false
    end

    for index = 1, #recipe.ingredients do
        local ingredient = recipe.ingredients[index]
        if type(ingredient) == "table" and visiting[ingredient.key] == true then
            return true
        end
    end

    return false
end

local function _add_result_index_entry(index_map, key, record)
    if type(index_map) ~= "table" or type(record) ~= "table" then
        return
    end

    local normalized_key = _normalize_name(key)
    if normalized_key == "" then
        return
    end

    local list = index_map[normalized_key]
    if type(list) ~= "table" then
        list = {}
        index_map[normalized_key] = list
    end

    for i = 1, #list do
        if list[i] == record then
            return
        end
    end

    list[#list + 1] = record
end

function CraftingStore:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetVisible(false)
    self:SetWantsUpdates(true)

    self.current_character_name = _current_character_name()
    self.professions = {}
    self.items = {}
    self.recipes = {}
    self.recipe_by_id = {}
    self.recipes_by_result = {}
    self.ownership = {
        [SCOPE_SERVER] = {},
        [SCOPE_INVENTORY] = {},
        [SCOPE_PERSONAL] = {},
        [SCOPE_SHARED] = {},
    }
    self.source_ownership = {
        [SOURCE_BACKPACK] = {},
        [SOURCE_BANK] = {},
        [SOURCE_VAULT] = {},
        [SOURCE_SHARED] = {},
        [SOURCE_OTHER_CHARACTERS] = {},
    }
    self.profession_option_labels = { TR["All professions"] }
    self.profession_option_values = { FILTER_ALL }
    self.scope_option_labels = _scope_option_labels()
    self.scope_option_values = _scope_option_values()
    self.source_option_labels = _source_option_labels()
    self.source_option_values = _source_option_values()
    self._status_cache = {}
    self._assets_token = nil
    self._recipe_token = nil
    self._recipes_initialized = false
    self._recipe_loading = false
    self._recipe_load_queue = nil
    self._recipe_load_queue_index = 1
    self._recipe_load_done = 0
    self._recipe_load_total = 0
    self._foreground_loading = false
    self._live_inventory_token = ""
    self.update_every = BACKGROUND_UPDATE_EVERY
    self.last_update_at = 0
    self.version = 0
end

function CraftingStore:destroy()
    self:SetWantsUpdates(false)
    self:SetVisible(false)
end

function CraftingStore:get_scope_options()
    return self.scope_option_labels, self.scope_option_values
end

function CraftingStore:get_source_options()
    return self.source_option_labels, self.source_option_values
end

function CraftingStore:get_default_source_keys()
    return { SOURCE_BACKPACK, SOURCE_BANK, SOURCE_VAULT, SOURCE_SHARED }
end

function CraftingStore:get_all_source_keys()
    return _copy_array(SOURCE_ORDER)
end

function CraftingStore:normalize_source_keys(source_keys)
    return _normalize_source_keys(source_keys)
end

function CraftingStore:source_keys_from_scope(scope_key)
    return _source_keys_from_scope(scope_key)
end

function CraftingStore:scope_key_from_sources(source_keys)
    return _source_scope_key(source_keys)
end

function CraftingStore:get_profession_options()
    return self.profession_option_labels, self.profession_option_values
end

function CraftingStore:is_loading()
    return self._recipe_loading == true
end

function CraftingStore:get_loading_progress()
    local total = tonumber(self._recipe_load_total) or #self.recipes
    local loaded = tonumber(self._recipe_load_done) or #self.recipes
    if total < loaded then
        total = loaded
    end

    return {
        loading = self._recipe_loading == true,
        loaded = loaded,
        total = total,
        complete = self._recipes_initialized == true and self._recipe_loading ~= true,
    }
end

function CraftingStore:set_loading_priority(enabled)
    local foreground = enabled == true
    if self._foreground_loading == foreground then
        return
    end

    self._foreground_loading = foreground
    self.update_every = foreground == true and FOREGROUND_UPDATE_EVERY or BACKGROUND_UPDATE_EVERY
    self.last_update_at = 0
end

function CraftingStore:Update()
    local now = Turbine.Engine.GetGameTime()
    if (now - (self.last_update_at or 0)) < self.update_every then
        return
    end
    self.last_update_at = now

    local batch_size = self._foreground_loading == true and FOREGROUND_RECIPE_BATCH_SIZE or RECIPE_LOAD_BATCH_SIZE
    self:refresh(false, batch_size)
end

function CraftingStore:refresh(force, recipe_batch_size)
    local current_character = _current_character_name()
    local assets_token = ASSETS_STORE ~= nil and (tonumber(ASSETS_STORE.generation) or 0) or 0
    local live_inventory_counts = self:_capture_live_backpack_counts(current_character)
    local live_inventory_token = _count_map_signature(live_inventory_counts)
    local changed = false
    local recipe_refresh_needed = force == true or self._recipes_initialized ~= true or self.current_character_name ~= current_character

    if recipe_refresh_needed == true then
        self:_start_recipe_load(current_character)
        changed = true
    elseif self._recipe_loading == true and self:_step_recipe_load(recipe_batch_size or RECIPE_LOAD_BATCH_SIZE) == true then
        changed = true
    end

    local ownership_refresh_needed = force == true or recipe_refresh_needed == true or self._assets_token ~= assets_token or
        self._live_inventory_token ~= live_inventory_token

    if changed ~= true and ownership_refresh_needed ~= true then
        return false
    end

    self.current_character_name = current_character
    if ownership_refresh_needed == true then
        self.ownership, self.source_ownership = self:_build_ownership(current_character, live_inventory_counts)
        self._status_cache = {}
        self._assets_token = assets_token
        self._live_inventory_token = live_inventory_token
    end
    self.version = self.version + 1
    return true
end

function CraftingStore:get_recipe_status(recipe_or_id, scope_key)
    local scope = _normalized_scope_key(scope_key)
    if type(self._status_cache[scope]) ~= "table" then
        self._status_cache[scope] = {}
    end

    local recipe = recipe_or_id
    if type(recipe_or_id) ~= "table" then
        recipe = self.recipe_by_id[recipe_or_id]
    end
    if type(recipe) ~= "table" then
        return nil
    end

    local cache = self._status_cache[scope]
    if cache[recipe.id] == nil then
        local evaluation = self:evaluate_recipe(recipe, scope, 1)
        local summary = {
            craftable = evaluation ~= nil and evaluation.craftable == true or false,
            used_expansion = evaluation ~= nil and evaluation.used_expansion == true or false,
            ingredients = {},
        }
        if evaluation ~= nil and type(evaluation.ingredients) == "table" then
            for i = 1, #evaluation.ingredients do
                local node = evaluation.ingredients[i]
                summary.ingredients[#summary.ingredients + 1] = {
                    satisfied = node ~= nil and node.satisfied == true or false,
                    expanded = node ~= nil and node.expanded == true or false,
                }
            end
        end
        cache[recipe.id] = summary
    end
    return cache[recipe.id]
end

function CraftingStore:get_item(item_key)
    if type(self.items) ~= "table" then
        return nil
    end
    return self.items[item_key]
end

function CraftingStore:get_recipe_result_item(recipe_or_id)
    local recipe = recipe_or_id
    if type(recipe_or_id) ~= "table" then
        recipe = self.recipe_by_id[recipe_or_id]
    end
    if type(recipe) ~= "table" then
        return nil
    end
    return self:get_item(recipe.result_key)
end

function CraftingStore:get_recipe_required_level(recipe_or_id)
    local item = self:get_recipe_result_item(recipe_or_id)
    return item ~= nil and item.required_level or nil
end

function CraftingStore:get_recipe_result_name(recipe_or_id)
    local item = self:get_recipe_result_item(recipe_or_id)
    if item ~= nil and item.name ~= nil and item.name ~= "" then
        return item.name
    end

    local recipe = recipe_or_id
    if type(recipe_or_id) ~= "table" then
        recipe = self.recipe_by_id[recipe_or_id]
    end
    return type(recipe) == "table" and (recipe.result_key or "") or ""
end

function CraftingStore:recipe_matches_query(recipe, groups)
    if type(recipe) ~= "table" then
        return false
    end
    if type(groups) ~= "table" or #groups == 0 then
        return true
    end

    local result_item = self:get_item(recipe.result_key)
    local searchable = {
        _lower(result_item ~= nil and result_item.name or nil),
        _lower(recipe.profession_name),
        _lower(recipe.category_name),
        _lower(recipe.recipe_name),
    }
    if type(recipe.ingredients) == "table" then
        for i = 1, #recipe.ingredients do
            local ingredient = recipe.ingredients[i]
            local item = self:get_item(ingredient ~= nil and ingredient.key or nil)
            searchable[#searchable + 1] = _lower(item ~= nil and item.name or nil)
        end
    end

    local haystack = table.concat(searchable, "\n")
    for group_index = 1, #groups do
        local group = groups[group_index]
        local matched = true
        for term_index = 1, #group do
            if string.find(haystack, group[term_index], 1, true) == nil then
                matched = false
                break
            end
        end
        if matched == true then
            return true
        end
    end

    return false
end

function CraftingStore:_stock_for_source_keys(source_keys)
    local stock = {}
    local normalized = _normalize_source_keys(source_keys)
    for i = 1, #normalized do
        local source_stock = self.source_ownership[normalized[i]]
        if type(source_stock) == "table" then
            for key, quantity in pairs(source_stock) do
                _add_count(stock, key, quantity)
            end
        end
    end
    return stock
end

function CraftingStore:_stock_for_scope(scope_key)
    local scope = _normalized_scope_key(scope_key)
    if _is_source_scope_key(scope) == true then
        return self:_stock_for_source_keys(_source_keys_from_scope(scope))
    end
    return _copy_counts(self.ownership[scope] or self.ownership[SCOPE_PERSONAL] or {})
end

function CraftingStore:evaluate_recipe(recipe_or_id, scope_key, craft_count)
    local recipe = recipe_or_id
    if type(recipe_or_id) ~= "table" then
        recipe = self.recipe_by_id[recipe_or_id]
    end
    if type(recipe) ~= "table" then
        return nil
    end

    local count = tonumber(craft_count) or 1
    if count < 1 then
        count = 1
    end
    count = math.floor(count + 0.5)

    local scope = _normalized_scope_key(scope_key)
    local base_stock = self:_stock_for_scope(scope)
    local evaluation = self:_evaluate_recipe_with_stock(recipe, count, base_stock)
    evaluation.scope_key = scope
    return evaluation
end

function CraftingStore:evaluate_plan(plan_entries, scope_key)
    local base_stock = self:_stock_for_scope(scope_key)
    local working_stock = _copy_counts(base_stock)
    local result = {
        entries = {},
        missing = {},
        missing_list = {},
        missing_total = 0,
        planned_recipe_count = 0,
        craftable_count_total = 0,
    }

    if type(plan_entries) ~= "table" then
        return result
    end

    for i = 1, #plan_entries do
        local entry = plan_entries[i]
        local recipe = entry ~= nil and self.recipe_by_id[entry.recipe_id] or nil
        local count = entry ~= nil and (tonumber(entry.count) or 0) or 0
        count = math.floor(count + 0.5)
        if recipe ~= nil and count > 0 then
            result.planned_recipe_count = result.planned_recipe_count + count
            local craftable_count = self:_count_craftable_with_stock(recipe, count, working_stock)
            result.craftable_count_total = result.craftable_count_total + craftable_count
            local evaluation = self:_evaluate_recipe_with_stock(recipe, count, working_stock)
            working_stock = evaluation.remaining_stock
            result.entries[#result.entries + 1] = {
                recipe = recipe,
                count = count,
                craftable_count = craftable_count,
                evaluation = evaluation,
            }
            self:_merge_missing_maps(result.missing, evaluation.missing)
        end
    end

    result.missing_list = _missing_map_to_list(result.missing)
    result.missing_total = _sum_missing_map(result.missing)
    return result
end

function CraftingStore:serialize_plan_entries(plan_entries)
    local saved_entries = {}
    if type(plan_entries) ~= "table" then
        return saved_entries
    end

    for i = 1, #plan_entries do
        local entry = plan_entries[i]
        local recipe = entry ~= nil and self.recipe_by_id[entry.recipe_id] or nil
        local count = entry ~= nil and (tonumber(entry.count) or 0) or 0
        count = math.floor(count + 0.5)
        if recipe ~= nil and count > 0 then
            local saved_entry = self:serialize_recipe_identity(recipe)
            saved_entry.count = count
            saved_entries[#saved_entries + 1] = saved_entry
        end
    end

    return saved_entries
end

function CraftingStore:serialize_recipe_identity(recipe)
    if type(recipe) ~= "table" then
        return nil
    end

    return {
        id = recipe.id,
        profession_key = recipe.profession_key,
        result_key = recipe.result_key,
        recipe_name_key = recipe.recipe_name_key,
        category_name_key = _normalize_name(recipe.category_name),
        tier = tonumber(recipe.tier) or 0,
    }
end

function CraftingStore:saved_entry_matches_recipe(saved_entry, recipe)
    return _saved_plan_entry_matches_recipe(saved_entry, recipe)
end

function CraftingStore:resolve_saved_plan_entries(saved_entries)
    local resolved_entries = {}
    local unresolved_entries = {}
    local unresolved_count = 0

    if type(saved_entries) ~= "table" then
        return {
            entries = resolved_entries,
            unresolved_entries = unresolved_entries,
            unresolved_count = unresolved_count,
            total_count = 0,
        }
    end

    for i = 1, #saved_entries do
        local saved_entry = saved_entries[i]
        local recipe = nil
        local count = saved_entry ~= nil and (tonumber(saved_entry.count) or 0) or 0
        count = math.floor(count + 0.5)

        if count > 0 and type(saved_entry) == "table" then
            recipe = saved_entry.id ~= nil and self.recipe_by_id[saved_entry.id] or nil
            if _saved_plan_entry_matches_recipe(saved_entry, recipe) ~= true then
                recipe = nil
            end

            if recipe == nil then
                for recipe_index = 1, #self.recipes do
                    local candidate = self.recipes[recipe_index]
                    if _saved_plan_entry_matches_recipe(saved_entry, candidate) == true then
                        recipe = candidate
                        break
                    end
                end
            end
        end

        if recipe ~= nil and count > 0 then
            resolved_entries[#resolved_entries + 1] = {
                recipe_id = recipe.id,
                count = count,
            }
        elseif count > 0 then
            unresolved_entries[#unresolved_entries + 1] = {
                saved_entry = saved_entry,
                count = count,
            }
            unresolved_count = unresolved_count + 1
        end
    end

    return {
        entries = resolved_entries,
        unresolved_entries = unresolved_entries,
        unresolved_count = unresolved_count,
        total_count = #saved_entries,
    }
end

function CraftingStore:evaluate_plan_resources(plan_entries, scope_key)
    local evaluation = self:evaluate_plan(plan_entries, scope_key)
    local leaf_requirements = {}
    local missing_by_key = {}
    local resources = {}
    local incomplete_resources = {}

    for i = 1, #evaluation.entries do
        local ingredients = evaluation.entries[i] ~= nil and evaluation.entries[i].evaluation ~= nil and
            evaluation.entries[i].evaluation.ingredients or nil
        if type(ingredients) == "table" then
            for ingredient_index = 1, #ingredients do
                _collect_leaf_requirements(ingredients[ingredient_index], leaf_requirements)
            end
        end
    end

    for i = 1, #evaluation.missing_list do
        local missing_entry = evaluation.missing_list[i]
        if type(missing_entry) == "table" and missing_entry.key ~= nil then
            missing_by_key[missing_entry.key] = missing_entry
        end
    end

    for key, requirement in pairs(leaf_requirements) do
        local required = tonumber(requirement ~= nil and requirement.quantity or nil) or 0
        if required > 0 then
            local missing_entry = missing_by_key[key]
            local missing = tonumber(missing_entry ~= nil and missing_entry.quantity or nil) or 0
            local owned = math.max(0, required - missing)
            local item = self:get_item(key)
            local resource = {
                key = key,
                name = item ~= nil and item.name or key,
                item_info = item ~= nil and item.item_info or nil,
                icon_id = item ~= nil and item.icon_id or nil,
                background_image_id = item ~= nil and item.background_image_id or nil,
                quality = item ~= nil and item.quality or nil,
                owned = owned,
                required = required,
                missing = missing,
                complete = missing <= 0,
            }
            resources[#resources + 1] = resource
            if resource.complete ~= true then
                incomplete_resources[#incomplete_resources + 1] = resource
            end
        end
    end

    table.sort(resources, _resource_progress_sort_compare)
    table.sort(incomplete_resources, _resource_progress_sort_compare)

    return {
        evaluation = evaluation,
        resources = resources,
        incomplete_resources = incomplete_resources,
        ready = #resources > 0 and #incomplete_resources == 0,
    }
end

function CraftingStore:recipe_uses_item_key(recipe, key_set)
    if type(recipe) ~= "table" or type(key_set) ~= "table" then
        return false
    end

    for i = 1, #recipe.ingredients do
        local ingredient = recipe.ingredients[i]
        if ingredient ~= nil and key_set[ingredient.key] == true then
            return true
        end
    end

    return false
end

function CraftingStore:_capture_live_backpack_counts(current_character)
    local counts = {}
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    local backpack = player ~= nil and player.GetBackpack ~= nil and player:GetBackpack() or nil
    if backpack == nil or backpack.GetSize == nil or backpack.GetItem == nil then
        return counts
    end

    local size = tonumber(backpack:GetSize()) or 0
    for index = 1, size do
        local item = backpack:GetItem(index)
        if item ~= nil then
            local item_info = item.GetItemInfo ~= nil and item:GetItemInfo() or nil
            local name = item.GetName ~= nil and item:GetName() or nil
            if (name == nil or name == "") and item_info ~= nil and item_info.GetName ~= nil then
                name = item_info:GetName()
            end

            local key = _normalize_name(name)
            if key ~= "" then
                local quantity = item.GetQuantity ~= nil and item:GetQuantity() or 1
                quantity = tonumber(quantity) or 0
                if quantity > 0 then
                    counts[key] = (counts[key] or 0) + quantity
                end
            end
        end
    end

    return counts
end

function CraftingStore:_build_ownership(current_character, live_inventory_counts)
    local ownership = {
        [SCOPE_SERVER] = {},
        [SCOPE_INVENTORY] = {},
        [SCOPE_PERSONAL] = {},
        [SCOPE_SHARED] = {},
    }
    local source_ownership = {
        [SOURCE_BACKPACK] = {},
        [SOURCE_BANK] = {},
        [SOURCE_VAULT] = {},
        [SOURCE_SHARED] = {},
        [SOURCE_OTHER_CHARACTERS] = {},
    }

    local entries
    if ASSETS_STORE ~= nil and ASSETS_STORE.get_entries ~= nil then
        entries = ASSETS_STORE:get_entries()
    else
        entries = _collect_asset_entries_from_cache()
    end

    if type(entries) ~= "table" then
        return ownership, source_ownership
    end

    for i = 1, #entries do
        local record = entries[i]
        local key = _normalize_name(record ~= nil and record.name or nil)
        local quantity = tonumber(record ~= nil and record.quantity or nil) or 0
        if key ~= "" and quantity > 0 then
            local is_current_backpack = record.owner == current_character and record.source_key == SOURCE_BACKPACK
            if is_current_backpack ~= true then
                _add_count(ownership[SCOPE_SERVER], key, quantity)

                if record.owner == current_character and record.source_key == SOURCE_BACKPACK then
                    _add_count(ownership[SCOPE_INVENTORY], key, quantity)
                end

                if record.owner == current_character and
                    (record.source_key == SOURCE_BACKPACK or record.source_key == SOURCE_BANK or record.source_key == SOURCE_VAULT) then
                    _add_count(ownership[SCOPE_PERSONAL], key, quantity)
                end

                if record.owner == current_character and record.source_key == SOURCE_BANK then
                    _add_count(source_ownership[SOURCE_BANK], key, quantity)
                elseif record.owner == current_character and record.source_key == SOURCE_VAULT then
                    _add_count(source_ownership[SOURCE_VAULT], key, quantity)
                elseif record.owner ~= current_character and
                    (record.source_key == SOURCE_BACKPACK or record.source_key == SOURCE_BANK or record.source_key == SOURCE_VAULT) then
                    _add_count(source_ownership[SOURCE_OTHER_CHARACTERS], key, quantity)
                end

                if record.source_key == SOURCE_SHARED then
                    _add_count(ownership[SCOPE_SHARED], key, quantity)
                    _add_count(source_ownership[SOURCE_SHARED], key, quantity)
                end
            end
        end
    end

    if type(live_inventory_counts) == "table" then
        for key, quantity in pairs(live_inventory_counts) do
            local amount = tonumber(quantity) or 0
            if key ~= nil and key ~= "" and amount > 0 then
                ownership[SCOPE_INVENTORY][key] = amount
                source_ownership[SOURCE_BACKPACK][key] = amount
                _add_count(ownership[SCOPE_PERSONAL], key, amount)
                _add_count(ownership[SCOPE_SERVER], key, amount)
            end
        end
    end

    return ownership, source_ownership
end

function CraftingStore:_start_recipe_load(current_character)
    local professions = {}
    local profession_labels = { TR["All professions"] }
    local profession_values = { FILTER_ALL }
    local recipe_queue = {}
    local recipe_total = 0

    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    local attributes = player ~= nil and player:GetAttributes() or nil

    if attributes ~= nil then
        for i = 1, #PROFESSION_ORDER do
            local profession_enum = PROFESSION_ORDER[i]
            local profession_info = attributes:GetProfessionInfo(profession_enum)
            if profession_info ~= nil then
                local profession_name = _trim(profession_info:GetName())
                if profession_name == "" then
                    profession_name = tostring(profession_enum)
                end

                local recipe_count = profession_info:GetRecipeCount() or 0
                local profession = {
                    profession = profession_enum,
                    key = tostring(profession_enum),
                    name = profession_name,
                    recipe_count = recipe_count,
                    proficiency_level = profession_info:GetProficiencyLevel() or 0,
                    proficiency_title = _trim(profession_info:GetProficiencyTitle()),
                    mastery_level = profession_info:GetMasteryLevel() or 0,
                    mastery_title = _trim(profession_info:GetMasteryTitle()),
                }
                professions[#professions + 1] = profession
                profession_labels[#profession_labels + 1] = profession_name
                profession_values[#profession_values + 1] = profession.key

                if recipe_count > 0 then
                    recipe_queue[#recipe_queue + 1] = {
                        profession = profession,
                        profession_info = profession_info,
                        recipe_count = recipe_count,
                        next_recipe_index = 1,
                    }
                    recipe_total = recipe_total + recipe_count
                end
            end
        end
    end

    self.current_character_name = current_character
    self.professions = professions
    self.items = {}
    self.recipes = {}
    self.recipe_by_id = {}
    self.recipes_by_result = {}
    self.profession_option_labels = profession_labels
    self.profession_option_values = profession_values
    self._status_cache = {}
    self._recipe_token = tostring(current_character or "")
    self._recipes_initialized = true
    self._recipe_loading = recipe_total > 0
    self._recipe_load_queue = recipe_queue
    self._recipe_load_queue_index = 1
    self._recipe_load_done = 0
    self._recipe_load_total = recipe_total
end

function CraftingStore:_register_recipe_record(record)
    if type(record) ~= "table" then
        return
    end

    self.recipes[#self.recipes + 1] = record
    self.recipe_by_id[record.id] = record
    _add_result_index_entry(self.recipes_by_result, record.result_key, record)
    if record.recipe_name_key ~= nil then
        _add_result_index_entry(self.recipes_by_result, record.recipe_name_key, record)
    end
end

function CraftingStore:_step_recipe_load(batch_size)
    if self._recipe_loading ~= true then
        return false
    end

    local remaining = tonumber(batch_size) or RECIPE_LOAD_BATCH_SIZE
    if remaining == nil or remaining < 1 then
        remaining = RECIPE_LOAD_BATCH_SIZE
    end

    local changed = false
    while remaining > 0 and type(self._recipe_load_queue) == "table" and
        self._recipe_load_queue_index <= #self._recipe_load_queue do
        local queue_entry = self._recipe_load_queue[self._recipe_load_queue_index]
        local recipe_index = tonumber(queue_entry ~= nil and queue_entry.next_recipe_index or nil) or 1
        local profession = queue_entry ~= nil and queue_entry.profession or nil
        local profession_info = queue_entry ~= nil and queue_entry.profession_info or nil
        local recipe = profession_info ~= nil and profession_info:GetRecipe(recipe_index) or nil
        if recipe ~= nil and profession ~= nil then
            self:_register_recipe_record(self:_build_recipe_record(recipe, profession, recipe_index, self.items))
        end

        self._recipe_load_done = self._recipe_load_done + 1
        queue_entry.next_recipe_index = recipe_index + 1
        remaining = remaining - 1
        changed = true

        if queue_entry.next_recipe_index > (tonumber(queue_entry.recipe_count) or 0) then
            self._recipe_load_queue_index = self._recipe_load_queue_index + 1
        end
    end

    if type(self._recipe_load_queue) ~= "table" or self._recipe_load_queue_index > #self._recipe_load_queue then
        self._recipe_loading = false
        self._recipe_load_queue = nil
        self._recipe_load_queue_index = 1
        table.sort(self.recipes, function(left, right)
            return _recipe_sort_compare(self.items, left, right)
        end)
        self._recipe_token = table.concat({
            tostring(self.current_character_name or ""),
            tostring(#self.professions),
            tostring(#self.recipes),
        }, "\30")
        self._status_cache = {}
    end

    return changed
end

function CraftingStore:_build_recipe_record(recipe, profession, recipe_index, items)
    local recipe_name = _trim(recipe:GetName())
    local recipe_name_key = _normalize_name(recipe_name)
    local result_info = recipe:GetResultItemInfo()
    local result_name = _trim(result_info ~= nil and result_info:GetName() or nil)
    local category_name = _trim(recipe:GetCategoryName())
    local critical_result_info = nil
    local critical_result_name = ""
    local critical_result_key = nil
    if result_name == "" then
        result_name = recipe_name
    end
    if result_name == "" then
        return nil
    end

    local result_key = _normalize_name(result_name)
    if result_key == "" then
        return nil
    end

    _remember_item(items, result_key, result_name, result_info)
    if type(items[result_key]) == "table" and items[result_key].required_level == nil then
        items[result_key].required_level = _recipe_required_level(result_info, recipe_name, category_name)
    end

    if recipe.HasCriticalResultItem ~= nil and recipe:HasCriticalResultItem() == true and
        recipe.GetCriticalResultItemInfo ~= nil then
        critical_result_info = recipe:GetCriticalResultItemInfo()
        critical_result_name = _trim(critical_result_info ~= nil and critical_result_info:GetName() or nil)
        critical_result_key = _normalize_name(critical_result_name)
        if critical_result_key ~= "" then
            _remember_item(items, critical_result_key, critical_result_name, critical_result_info)
            if type(items[critical_result_key]) == "table" and items[critical_result_key].required_level == nil then
                items[critical_result_key].required_level =
                    _recipe_required_level(critical_result_info, recipe_name, category_name)
            end
        else
            critical_result_key = nil
        end
    end

    local ingredient_count = recipe:GetIngredientCount() or 0
    local ingredients = {}

    for ingredient_index = 1, ingredient_count do
        local ingredient = recipe:GetIngredient(ingredient_index)
        if ingredient ~= nil then
            local ingredient_info = ingredient:GetItemInfo()
            local ingredient_name = _trim(ingredient_info ~= nil and ingredient_info:GetName() or nil)
            local ingredient_key = _normalize_name(ingredient_name)
            if ingredient_key ~= "" then
                local ingredient_record = {
                    key = ingredient_key,
                    quantity = math.max(1, tonumber(ingredient:GetRequiredQuantity()) or 1),
                }
                ingredients[#ingredients + 1] = ingredient_record
                _remember_item(items, ingredient_key, ingredient_name, ingredient_info)
            end
        end
    end

    local record = {
        id = table.concat({
            tostring(profession.key),
            tostring(recipe_index),
            result_key,
            _normalize_name(recipe_name),
        }, "\30"),
        profession = profession.profession,
        profession_key = profession.key,
        profession_name = profession.name,
        category_name = category_name,
        tier = tonumber(recipe:GetTier()) or 0,
        cooldown = tonumber(recipe:GetCooldown()) or 0,
        critical_chance = recipe.GetBaseCriticalSuccessChance ~= nil and
            tonumber(recipe:GetBaseCriticalSuccessChance()) or nil,
        result_key = result_key,
        critical_result_key = critical_result_key,
        critical_result_quantity = critical_result_key ~= nil and recipe.GetCriticalResultItemQuantity ~= nil and
            math.max(1, tonumber(recipe:GetCriticalResultItemQuantity()) or 1) or 0,
        recipe_name_key = recipe_name_key ~= "" and recipe_name_key ~= result_key and recipe_name_key or nil,
        recipe_name = recipe_name ~= "" and recipe_name ~= result_name and recipe_name or nil,
        result_quantity = math.max(1, tonumber(recipe:GetResultItemQuantity()) or 1),
        ingredients = ingredients,
    }

    return record
end

function CraftingStore:_merge_missing_maps(destination, source)
    if type(source) ~= "table" then
        return
    end

    for key, entry in pairs(source) do
        if type(entry) == "table" and (tonumber(entry.quantity) or 0) > 0 then
            if type(destination[key]) ~= "table" then
                destination[key] = {
                    key = key,
                    quantity = 0,
                }
            end
            destination[key].quantity = (tonumber(destination[key].quantity) or 0) + (tonumber(entry.quantity) or 0)
        end
    end
end

function CraftingStore:_make_missing_entry(item_key, quantity)
    return {
        key = item_key,
        quantity = quantity,
    }
end

function CraftingStore:_get_recipes_for_item(item_key)
    local list = self.recipes_by_result[item_key]
    if type(list) == "table" and #list > 0 then
        return list
    end

    return nil
end

function CraftingStore:_satisfy_item(stock, item_key, quantity, visiting)
    local needed = math.max(0, tonumber(quantity) or 0)
    local node = {
        key = item_key,
        required = needed,
        from_stock = 0,
        produced = 0,
        craft_count = 0,
        satisfied = false,
        expanded = false,
        ambiguous = false,
        missing = 0,
        recipe_id = nil,
        children = nil,
    }

    local next_stock = _copy_counts(stock)
    if needed <= 0 then
        node.satisfied = true
        return true, node, next_stock, {}
    end

    local available = tonumber(next_stock[item_key]) or 0
    if available > 0 then
        local used = math.min(available, needed)
        node.from_stock = used
        next_stock[item_key] = available - used
        needed = needed - used
    end

    if needed <= 0 then
        node.satisfied = true
        return true, node, next_stock, {}
    end

    local recipes = self:_get_recipes_for_item(item_key)
    if recipes == nil or visiting[item_key] == true then
        node.missing = needed
        node.satisfied = false
        return false, node, next_stock, {
            [item_key] = self:_make_missing_entry(item_key, needed),
        }
    end

    local best_failed_node = nil
    local best_failed_stock = nil
    local best_failed_missing = nil
    local best_failed_total = nil
    local best_failed_distinct = nil

    for recipe_index = 1, #recipes do
        local recipe = recipes[recipe_index]
        if _recipe_reenters_path(recipe, visiting) ~= true then
            local branch_stock = _copy_counts(next_stock)
            local per_craft = math.max(1, tonumber(recipe.result_quantity) or 1)
            local crafts_needed = math.floor(((needed + per_craft - 1) / per_craft) + 0.0)
            local combined_missing = {}
            local all_ok = true
            local candidate_node = {
                key = node.key,
                required = node.required,
                from_stock = node.from_stock,
                produced = 0,
                craft_count = crafts_needed,
                satisfied = false,
                expanded = true,
                ambiguous = false,
                missing = 0,
                recipe_id = recipe.id,
                children = {},
            }

            visiting[item_key] = true
            for i = 1, #recipe.ingredients do
                local ingredient = recipe.ingredients[i]
                local child_ok, child_node, child_stock, child_missing = self:_satisfy_item(
                    branch_stock,
                    ingredient.key,
                    ingredient.quantity * crafts_needed,
                    visiting
                )
                branch_stock = child_stock
                candidate_node.children[#candidate_node.children + 1] = child_node
                self:_merge_missing_maps(combined_missing, child_missing)
                if child_ok ~= true then
                    all_ok = false
                end
            end
            visiting[item_key] = nil

            if all_ok == true then
                local produced = crafts_needed * per_craft
                candidate_node.produced = produced
                candidate_node.satisfied = true
                local leftover = produced - needed
                if leftover > 0 then
                    branch_stock[item_key] = (tonumber(branch_stock[item_key]) or 0) + leftover
                end
                return true, candidate_node, branch_stock, combined_missing
            end

            candidate_node.missing = needed
            candidate_node.satisfied = false
            local missing_total = _sum_missing_map(combined_missing)
            local missing_distinct = 0
            for _ in pairs(combined_missing) do
                missing_distinct = missing_distinct + 1
            end

            if best_failed_node == nil or
                missing_total < best_failed_total or
                (missing_total == best_failed_total and missing_distinct < best_failed_distinct) then
                best_failed_node = candidate_node
                best_failed_stock = branch_stock
                best_failed_missing = combined_missing
                best_failed_total = missing_total
                best_failed_distinct = missing_distinct
            end
        end
    end

    if best_failed_node ~= nil then
        return false, best_failed_node, best_failed_stock, best_failed_missing
    end

    node.missing = needed
    node.satisfied = false
    return false, node, next_stock, {
        [item_key] = self:_make_missing_entry(item_key, needed),
    }
end

function CraftingStore:_node_has_expansion(node)
    if type(node) ~= "table" then
        return false
    end
    if node.expanded == true then
        return true
    end
    if type(node.children) ~= "table" then
        return false
    end
    for i = 1, #node.children do
        if self:_node_has_expansion(node.children[i]) == true then
            return true
        end
    end
    return false
end

function CraftingStore:_evaluate_recipe_with_stock(recipe, craft_count, stock)
    local count = math.max(1, math.floor((tonumber(craft_count) or 1) + 0.5))
    local base_stock = _copy_counts(stock)
    local working_stock = _copy_counts(stock)
    local evaluation = {
        requested_count = count,
        ingredients = {},
        missing = {},
        missing_list = {},
        missing_total = 0,
        craftable = true,
        used_expansion = false,
        remaining_stock = working_stock,
    }

    for i = 1, #recipe.ingredients do
        local ingredient = recipe.ingredients[i]
        local required = ingredient.quantity * count
        local ingredient_ok, node, next_stock, child_missing = self:_satisfy_item(
            working_stock,
            ingredient.key,
            required,
            {}
        )

        working_stock = next_stock
        node.required = required
        node.owned_in_scope = tonumber(base_stock[ingredient.key]) or 0
        node.satisfied = ingredient_ok == true
        evaluation.ingredients[#evaluation.ingredients + 1] = node
        self:_merge_missing_maps(evaluation.missing, child_missing)

        if ingredient_ok ~= true then
            evaluation.craftable = false
        end
        if self:_node_has_expansion(node) == true then
            evaluation.used_expansion = true
        end
    end

    evaluation.remaining_stock = working_stock
    evaluation.missing_total = _sum_missing_map(evaluation.missing)
    evaluation.missing_list = _missing_map_to_list(evaluation.missing)
    return evaluation
end

function CraftingStore:_count_craftable_with_stock(recipe, craft_count, stock)
    local requested = math.max(0, math.floor((tonumber(craft_count) or 0) + 0.5))
    if requested <= 0 or type(recipe) ~= "table" then
        return 0
    end

    local working_stock = _copy_counts(stock)
    local craftable_count = 0

    for _ = 1, requested do
        local evaluation = self:_evaluate_recipe_with_stock(recipe, 1, working_stock)
        if evaluation == nil or evaluation.craftable ~= true then
            break
        end
        craftable_count = craftable_count + 1
        working_stock = _copy_counts(evaluation.remaining_stock)
    end

    return craftable_count
end
