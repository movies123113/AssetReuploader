--!strict
local AssetIdFilter = require("../AssetIdFilter")
local getFilterOptions = require("../GetFilterOptions")
local UiLibrary = require("../../UiLibrary")

local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")

return function(ui: UiLibrary.Ui, plugin: Plugin)
    local tab = ui:CreateTab("Replace")

    local fileLabel = tab:CreateLabel("Current file:")
    fileLabel.instance.LayoutOrder = 1
    local currentFileContents

    local importButton = tab:CreateButton("Import json", function()
        local file: File? = StudioService:PromptImportFile({"json"} :: any) :: File
        if not file then
            ui:Notify("Notification", "Failed to get file.")
            return
        end

        fileLabel:ChangeText(`Current file: {file.Name}`)
        currentFileContents = file:GetBinaryContents()
    end)
    importButton.instance.LayoutOrder = 0

    local replaceButton = tab:CreateButton("Replace ids", function()
        local success, rawIds = pcall(HttpService.JSONDecode, HttpService, currentFileContents)
        if not success then
            ui:Notify("Notification", "Can't parse JSON")
            return
        end

        local idsToReplace = {}
        for i, idInfo in rawIds :: any do
            if type(idInfo) == "table" then
                local oldId = idInfo["oldId"]
                local newId = idInfo["newId"]
                local isOldIdValid = oldId and type(oldId) == "number"
                local isNewIdValid = newId and type(newId) == "number"
                if isOldIdValid and isNewIdValid then
                    idsToReplace[oldId] = newId
                    continue
                end
            end

            ui:Notify("Notification", `Invalid index: {i}`)
            return
        end

        local filterOptions = getFilterOptions(plugin, game:GetDescendants())
        local instancesArray = filterOptions.WhitelistedInstances
        for _, className in {"Animation", "Sound"} do
            table.insert(instancesArray, className)
        end
        
        local filteredIds = AssetIdFilter.filterInstances(filterOptions)
        AssetIdFilter.replaceIds(filteredIds, idsToReplace)

        warn("Finished replacing Ids")
    end)
    replaceButton.instance.LayoutOrder = 2
end
