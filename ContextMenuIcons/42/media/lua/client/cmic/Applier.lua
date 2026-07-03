require "cmic/Initialization"
require "cmic/Utils"
require "cmic/IconHandler"
require "cmic/ConfigurationList"
require "cmic/ModPreferences"

local utils = ContextMenuIcons.Utils
local iconHandler = ContextMenuIcons.IconHandler

local staticNamedInventoryIcons = {}
local staticNamedWorldIcons = {}
local dynamicNamedInventoryIcons = {}
local dynamicNamedWorldIcons = {}

local function resetIconTables()
    iconHandler.resetIconTexturesCache()

    staticNamedInventoryIcons = {}
    staticNamedWorldIcons = {}
    dynamicNamedInventoryIcons = {}
    dynamicNamedWorldIcons = {}
end

local function createIconTables(options, staticNamedIcons, dynamicNamedIcons)
    for optionName, details in pairs(options) do
        local localizedText = getText(optionName)

        -- Finding a "%" symbol as a placeholder for dynamic strings.
        if not string.find(localizedText, "%", 1, true) then
            -- No "%"
            staticNamedIcons[localizedText] = details
        else
            -- "%" found. Logic to handle that type strings.
            local pattern = localizedText:gsub("%%%d%$%w+", "DYNMARKER"):gsub("%%%d", "DYNMARKER")
            pattern = pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
            pattern = pattern:gsub("DYNMARKER", ".*")
            
            dynamicNamedIcons["^" .. pattern .. "$"] = details
        end
    end
end

local function createAllIconTables()
    if ContextMenuIcons.isNoneIconPackSelected then return end

    local iconPack = ContextMenuIcons.iconPacksList[ContextMenuIcons.preferences.iconPackName]

    -- utils.log("createAllIconTables()")
    resetIconTables()
    createIconTables(iconPack.options.inventory, staticNamedInventoryIcons, dynamicNamedInventoryIcons)
    createIconTables(iconPack.options.world, staticNamedWorldIcons, dynamicNamedWorldIcons)
end

local function applyIcons(context, staticNamedIcons, dynamicNamedIcons)
    if not context or not context.options or ContextMenuIcons.isNoneIconPackSelected then return end

    local iconPackName = ContextMenuIcons.preferences.iconPackName
    local iconsColor = ContextMenuIcons.preferences.iconsColor

    for i = 1, #context.options do
        local option = context.options[i]
        local details

        if option.name then
            details = staticNamedIcons[option.name]

            if not details then
                for pattern, data in pairs(dynamicNamedIcons) do
                    if string.match(option.name, pattern) then
                        details = data
                        break
                    end
                end
            end

            if details then
                if type(details) == "string" then
                    iconHandler.setIcon(option, iconPackName, details, iconsColor)
                elseif type(details) == "table" then
                    if details.iconTextureName then
                        iconHandler.setIcon(option, iconPackName, details.iconTextureName, iconsColor)
                    end

                    if details.subOptions and option.subOption then
                        local subContext = context:getSubMenu(option.subOption)
                        if subContext then
                            local subStatic = {}
                            local subDynamic = {}
                            createIconTables(details.subOptions, subStatic, subDynamic)
                            applyIcons(subContext, subStatic, subDynamic)
                        end
                    end
                end
            elseif not details and option.subOption then
                -- Pass through world object option like "Sink", "Bed" and etc.
                local subContext = context:getSubMenu(option.subOption)
                if subContext then
                    applyIcons(subContext, staticNamedIcons, dynamicNamedIcons)
                end
            end
        end
    end
end

local function applyInventoryIcons(player, context)
    applyIcons(context, staticNamedInventoryIcons, dynamicNamedInventoryIcons)
end

local function applyWorldIcons(player, context)
    applyIcons(context, staticNamedWorldIcons, dynamicNamedWorldIcons)
end

Events.OnFillInventoryObjectContextMenu.Add(applyInventoryIcons)
Events.OnFillWorldObjectContextMenu.Add(applyWorldIcons)

ContextMenuIcons.Events.OnPreferencesApplied(createAllIconTables)
Events.OnGameStart.Add(createAllIconTables)
-- Events.OnMainMenuEnter.Add(safeInitIconTables) -- Для отображения в главном меню / настройках
