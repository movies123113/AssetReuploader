--!strict
local UiLibrary = require("../../UiLibrary")

local StudioService = game:GetService("StudioService")
local HttpService = game:GetService("HttpService")

return function(ui: UiLibrary.Ui, plugin: Plugin)
    local tab = ui:CreateTab("Settings")

    local split1 = tab:CreateSplit()
    split1:AddToggle("Search string values", function(state)
        plugin:SetSetting("StrVals", state)
    end, plugin:GetSetting("StrVals"))
    split1:AddToggle("Search scripts", function(state)
        plugin:SetSetting("Scripts", state)
    end, plugin:GetSetting("Scripts"))
    
    local split2 = tab:CreateSplit()
    split2:AddToggle("Search int/number values", function(state)
        plugin:SetSetting("NumVals", state)
    end, plugin:GetSetting("NumVals"))
    split2:AddToggle("Debug mode", function(state)
        plugin:SetSetting("Debug", state)
    end, plugin:GetSetting("Debug"))

    local split3 = tab:CreateSplit()
    split3:AddToggle("Export json when done", function(state)
        plugin:SetSetting("ExportJSON", state)
    end, plugin:GetSetting("ExportJSON"))

    local themeList = tab:CreateList()

    local function setThemeButton(oldTheme: string, newTheme: string)
        local theme = ui.theme.get()

        local oldElement = themeList.elements[oldTheme]
        oldElement.instance.BackgroundColor3 = theme.UnselectedColor
        oldElement.selected = false

        local newElement = themeList.elements[newTheme]
        newElement.instance.BackgroundColor3 = theme.SelectedColor
        newElement.selected = true
    end

    local function createThemeButton(themeId: string, themeName: string)
        local element = themeList:CreateElement(themeId)
            :OnClicked(function()
                local theme = ui.theme.get()
                if theme.Id == themeId then return end

                local oldThemeId = theme.Id

                ui.theme.set(themeId)
                ui:UpdateTheme()

                setThemeButton(oldThemeId, themeId)
            end)
            :AddRemoveButton(function()
                local theme = ui.theme.get()
                if theme.Id == themeId then 
                    ui.theme.set("Studio")
                    ui:UpdateTheme()
                    setThemeButton(themeId, "Studio")
                end

                ui.theme.remove(themeId)
            end)
        
        element.instance.TextLabel.Text = themeName
    end

    split3:AddButton("Import theme", function()
        local file: File = StudioService:PromptImportFile({"json"} :: any) :: File
        if not file then
            ui:Notify("Notification", "Failed to get file.")
            return
        end

        local success, rawTheme = pcall(HttpService.JSONDecode, HttpService, file:GetBinaryContents())
        if not success then
            ui:Notify("Notification", "Error parsing theme. Is it a valid JSON?")
            return
        end

        local result
        success, result = pcall(ui.theme.add, rawTheme)
        if not success then
            local splitMessage = string.split(result :: string, ": ")
            ui:Notify("Notification", `Failed to import theme: {splitMessage[#splitMessage]}`)
            return
        end
        
        createThemeButton(result :: string, (rawTheme :: any).Name :: string)
    end)

    themeList:CreateElement("Studio")
        :OnClicked(function()
            local theme = ui.theme.get()
            if theme.Id == "Studio" then return end

            local oldThemeId = theme.Id

            ui.theme.set("Studio")
            ui:UpdateTheme()

            setThemeButton(oldThemeId, "Studio")
        end)

    for id, theme in ui.theme.getThemes() do
        local name: string = theme.Name
        if name == "Studio" then continue end
        createThemeButton(id, name)
    end

    local currentTheme = ui.theme.get()
    local element = themeList.elements[currentTheme.Id]
    element.instance.BackgroundColor3 = currentTheme.SelectedColor
    element.selected = true
end
