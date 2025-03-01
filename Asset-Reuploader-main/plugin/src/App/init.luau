--!strict
local App = {}

local UiLibrary = require("./UiLibrary")

local tabOrder = {
    "Animation",
    "Sound",
    "Replace",
    "Settings"
}

function App.init(ui: UiLibrary.Ui, plugin: Plugin)
    for i, tabName in tabOrder do
        local tab = script.Tabs:FindFirstChild(tabName)
        assert(tab, "Tab not found.")
        require(tab)(ui, plugin)
    end
end

return App