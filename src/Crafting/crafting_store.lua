import "Turbine.Gameplay"
import "Turbine.UI"

Crafting = Crafting or {}

CraftingStore = class(Turbine.UI.Control)
Crafting.CraftingStore = CraftingStore

local SOURCE_BACKPACK = "backpack"
local SOURCE_BANK = "bank"
local SOURCE_VAULT = "vault"
local SOURCE_SHARED = "shared_storage"

local FILTER_ALL = "__all"
local SCOPE_SERVER = "server"
local SCOPE_INVENTORY = "inventory"
local SCOPE_PERSONAL = "personal"
local SCOPE_SHARED = "shared"
local RECIPE_LOAD_BATCH_SIZE = 1
local BACKGROUND_UPDATE_EVERY = 1.00
local FOREGROUND_UPDATE_EVERY = 0.25
local FOREGROUND_RECIPE_BATCH_SIZE = 2

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
                    name = node.name or "",
                    item_info = node.item_info,
                    icon_id = node.icon_id,
                    background_image_id = node.background_image_id,
                    quality = node.quality,
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
    if saved_entry.recipe_name_key ~= nil and tostring(saved_entry.recipe_name_key) ~= _normalize_name(recipe.name) then
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

local function _remember_item_meta(item_meta, key, name, item_info)
    if key == nil or key == "" then
        return
    end

    local current = item_meta[key]
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
        item_meta[key] = current
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

local function _recipe_sort_compare(left, right)
    local left_profession = _lower(left ~= nil and left.profession_name or nil)
    local right_profession = _lower(right ~= nil and right.profession_name or nil)
    if left_profession ~= right_profession then
        return left_profession < right_profession
    end

    local left_name = _lower(left ~= nil and left.result_name or nil)
    local right_name = _lower(right ~= nil and right.result_name or nil)
    if left_name ~= right_name then
        return left_name < right_name
    end

    return _lower(left ~= nil and left.name or nil) < _lower(right ~= nil and right.name or nil)
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
    self.recipes = {}
    self.recipe_by_id = {}
    self.result_index = {}
    self.item_meta = {}
    self.ownership = {
        [SCOPE_SERVER] = {},
        [SCOPE_INVENTORY] = {},
        [SCOPE_PERSONAL] = {},
        [SCOPE_SHARED] = {},
    }
    self.profession_option_labels = { TR["All professions"] }
    self.profession_option_values = { FILTER_ALL }
    self.scope_option_labels = _scope_option_labels()
    self.scope_option_values = _scope_option_values()
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
    self.update_every = BACKGROUND_UPDATE_EVERY
    self.last_update_at = 0
    self.version = 0
end

function CraftingStore:destroy()
    self:SetWantsUpdates(false)
    self:SetVisible(false)
    self.current_character_name = nil
    self.professions = nil
    self.recipes = nil
    self.recipe_by_id = nil
    self.result_index = nil
    self.item_meta = nil
    self.ownership = nil
    self.profession_option_labels = nil
    self.profession_option_values = nil
    self.scope_option_labels = nil
    self.scope_option_values = nil
    self._status_cache = nil
    self._assets_token = nil
    self._recipe_token = nil
    self._recipes_initialized = false
    self._recipe_loading = false
    self._recipe_load_queue = nil
    self._recipe_load_queue_index = nil
    self._recipe_load_done = nil
    self._recipe_load_total = nil
    self._foreground_loading = false
end

function CraftingStore:get_scope_options()
    return self.scope_option_labels, self.scope_option_values
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
    local changed = false
    local recipe_refresh_needed = force == true or self._recipes_initialized ~= true or self.current_character_name ~= current_character

    if recipe_refresh_needed == true then
        self:_start_recipe_load(current_character)
        changed = true
    elseif self._recipe_loading == true and self:_step_recipe_load(recipe_batch_size or RECIPE_LOAD_BATCH_SIZE) == true then
        changed = true
    end

    local ownership_refresh_needed = force == true or recipe_refresh_needed == true or self._assets_token ~= assets_token

    if changed ~= true and ownership_refresh_needed ~= true then
        return false
    end

    self.current_character_name = current_character
    if ownership_refresh_needed == true then
        self.ownership = self:_build_ownership(current_character)
        self._status_cache = {}
        self._assets_token = assets_token
    end
    self.version = self.version + 1
    return true
end

function CraftingStore:get_recipe_status(recipe_or_id, scope_key)
    local scope = scope_key or SCOPE_PERSONAL
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
        cache[recipe.id] = self:evaluate_recipe(recipe, scope, 1)
    end
    return cache[recipe.id]
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

    local base_stock = _copy_counts(self.ownership[scope_key] or {})
    local evaluation = self:_evaluate_recipe_with_stock(recipe, count, base_stock)
    evaluation.scope_key = scope_key
    return evaluation
end

function CraftingStore:evaluate_plan(plan_entries, scope_key)
    local base_stock = _copy_counts(self.ownership[scope_key] or {})
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
            saved_entries[#saved_entries + 1] = {
                id = recipe.id,
                profession_key = recipe.profession_key,
                result_key = recipe.result_key,
                recipe_name_key = _normalize_name(recipe.name),
                category_name_key = _normalize_name(recipe.category_name),
                result_name = recipe.result_name,
                profession_name = recipe.profession_name,
                category_name = recipe.category_name,
                tier = tonumber(recipe.tier) or 0,
                count = count,
            }
        end
    end

    return saved_entries
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
            local resource = {
                key = key,
                name = requirement.name or "",
                item_info = requirement.item_info,
                icon_id = requirement.icon_id,
                background_image_id = requirement.background_image_id,
                quality = requirement.quality,
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

function CraftingStore:_build_ownership(current_character)
    local ownership = {
        [SCOPE_SERVER] = {},
        [SCOPE_INVENTORY] = {},
        [SCOPE_PERSONAL] = {},
        [SCOPE_SHARED] = {},
    }

    local entries
    if ASSETS_STORE ~= nil and ASSETS_STORE.get_entries ~= nil then
        entries = ASSETS_STORE:get_entries()
    else
        entries = _collect_asset_entries_from_cache()
    end

    if type(entries) ~= "table" then
        return ownership
    end

    for i = 1, #entries do
        local record = entries[i]
        local key = _normalize_name(record ~= nil and record.name or nil)
        local quantity = tonumber(record ~= nil and record.quantity or nil) or 0
        if key ~= "" and quantity > 0 then
            ownership[SCOPE_SERVER][key] = (ownership[SCOPE_SERVER][key] or 0) + quantity

            if record.owner == current_character and record.source_key == SOURCE_BACKPACK then
                ownership[SCOPE_INVENTORY][key] = (ownership[SCOPE_INVENTORY][key] or 0) + quantity
            end

            if record.owner == current_character and
                (record.source_key == SOURCE_BACKPACK or record.source_key == SOURCE_BANK or record.source_key == SOURCE_VAULT) then
                ownership[SCOPE_PERSONAL][key] = (ownership[SCOPE_PERSONAL][key] or 0) + quantity
            end

            if record.source_key == SOURCE_SHARED then
                ownership[SCOPE_SHARED][key] = (ownership[SCOPE_SHARED][key] or 0) + quantity
            end
        end
    end

    return ownership
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
    self.recipes = {}
    self.recipe_by_id = {}
    self.result_index = {}
    self.item_meta = {}
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
    _add_result_index_entry(self.result_index, record.result_key, record)
    if record.recipe_name_key ~= nil then
        _add_result_index_entry(self.result_index, record.recipe_name_key, record)
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
            self:_register_recipe_record(self:_build_recipe_record(recipe, profession, recipe_index, self.item_meta))
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
        table.sort(self.recipes, _recipe_sort_compare)
        self._recipe_token = table.concat({
            tostring(self.current_character_name or ""),
            tostring(#self.professions),
            tostring(#self.recipes),
        }, "\30")
        self._status_cache = {}
    end

    return changed
end

function CraftingStore:_build_recipe_record(recipe, profession, recipe_index, item_meta)
    local recipe_name = _trim(recipe:GetName())
    local recipe_name_key = _normalize_name(recipe_name)
    local result_info = recipe:GetResultItemInfo()
    local result_name = _trim(result_info ~= nil and result_info:GetName() or nil)
    local category_name = _trim(recipe:GetCategoryName())
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

    _remember_item_meta(item_meta, result_key, result_name, result_info)

    local ingredient_count = recipe:GetIngredientCount() or 0
    local ingredients = {}
    local filter_parts = {
        _lower(recipe_name),
        _lower(result_name),
        _lower(profession.name),
        _lower(category_name),
    }

    for ingredient_index = 1, ingredient_count do
        local ingredient = recipe:GetIngredient(ingredient_index)
        if ingredient ~= nil then
            local ingredient_info = ingredient:GetItemInfo()
            local ingredient_name = _trim(ingredient_info ~= nil and ingredient_info:GetName() or nil)
            local ingredient_key = _normalize_name(ingredient_name)
            if ingredient_key ~= "" then
                local ingredient_record = {
                    key = ingredient_key,
                    name = ingredient_name,
                    quantity = math.max(1, tonumber(ingredient:GetRequiredQuantity()) or 1),
                    icon_id = _item_info_icon_id(ingredient_info),
                    background_image_id = _item_info_background_id(ingredient_info),
                    quality = _item_info_quality(ingredient_info),
                    item_info = ingredient_info,
                }
                ingredients[#ingredients + 1] = ingredient_record
                filter_parts[#filter_parts + 1] = _lower(ingredient_name)
                _remember_item_meta(item_meta, ingredient_key, ingredient_name, ingredient_info)
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
        name = recipe_name ~= "" and recipe_name or result_name,
        category_name = category_name,
        tier = tonumber(recipe:GetTier()) or 0,
        cooldown = tonumber(recipe:GetCooldown()) or 0,
        result_name = result_name,
        result_key = result_key,
        recipe_name_key = recipe_name_key ~= "" and recipe_name_key ~= result_key and recipe_name_key or nil,
        result_quantity = math.max(1, tonumber(recipe:GetResultItemQuantity()) or 1),
        icon_id = _item_info_icon_id(result_info),
        background_image_id = _item_info_background_id(result_info),
        quality = _item_info_quality(result_info),
        required_level = _recipe_required_level(result_info, recipe_name, category_name),
        result_item_info = result_info,
        ingredients = ingredients,
        haystack_lower = table.concat(filter_parts, "\n"),
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
                    name = entry.name,
                    quantity = 0,
                    icon_id = entry.icon_id,
                    background_image_id = entry.background_image_id,
                    quality = entry.quality,
                    item_info = entry.item_info,
                }
            end
            if destination[key].item_info == nil then
                destination[key].item_info = entry.item_info
            end
            destination[key].quantity = (tonumber(destination[key].quantity) or 0) + (tonumber(entry.quantity) or 0)
        end
    end
end

function CraftingStore:_make_missing_entry(item_key, quantity)
    local meta = self.item_meta[item_key] or {}
    return {
        key = item_key,
        name = meta.name or item_key,
        quantity = quantity,
        icon_id = meta.icon_id,
        background_image_id = meta.background_image_id,
        quality = meta.quality,
        item_info = meta.item_info,
    }
end

function CraftingStore:_get_recipes_for_item(item_key)
    local list = self.result_index[item_key]
    if type(list) == "table" and #list > 0 then
        return list
    end

    return nil
end

function CraftingStore:_satisfy_item(stock, item_key, quantity, visiting)
    local needed = math.max(0, tonumber(quantity) or 0)
    local meta = self.item_meta[item_key] or {}
    local node = {
        key = item_key,
        name = meta.name or item_key,
        required = needed,
        from_stock = 0,
        produced = 0,
        craft_count = 0,
        expanded = false,
        ambiguous = false,
        missing = 0,
        recipe = nil,
        children = nil,
        icon_id = meta.icon_id,
        background_image_id = meta.background_image_id,
        quality = meta.quality,
        item_info = meta.item_info,
    }

    local next_stock = _copy_counts(stock)
    if needed <= 0 then
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
        return true, node, next_stock, {}
    end

    local recipes = self:_get_recipes_for_item(item_key)
    if recipes == nil or visiting[item_key] == true then
        node.missing = needed
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
                name = node.name,
                required = node.required,
                from_stock = node.from_stock,
                produced = 0,
                craft_count = crafts_needed,
                expanded = true,
                ambiguous = false,
                missing = 0,
                recipe = recipe,
                children = {},
                icon_id = node.icon_id,
                background_image_id = node.background_image_id,
                quality = node.quality,
                item_info = node.item_info,
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
                local leftover = produced - needed
                if leftover > 0 then
                    branch_stock[item_key] = (tonumber(branch_stock[item_key]) or 0) + leftover
                end
                return true, candidate_node, branch_stock, combined_missing
            end

            candidate_node.missing = needed
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
        recipe = recipe,
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
        node.icon_id = ingredient.icon_id
        node.background_image_id = ingredient.background_image_id
        node.quality = ingredient.quality
        node.item_info = ingredient.item_info
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
