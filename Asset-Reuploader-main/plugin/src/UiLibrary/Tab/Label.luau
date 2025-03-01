--!strict
local Label = {}

local Theme = require("../Theme")

local assets = script.Parent.Parent.Assets
local buttonAsset = assets.Button
local listAsset = assets.List

export type Label = {
    instance: typeof(buttonAsset),
    
    UpdateTheme: (self: Label) -> (),
    ChangeText: (self: Label, text: string) -> (),
    Destroy: (self: Label) -> ()
}

function Label.new(parent: typeof(listAsset), text: string): Label
    local instance = buttonAsset:Clone()
    instance.Text = text

    local label = {
        instance = instance
    } :: Label

    function label.UpdateTheme(self: Label)
        Theme.updateText(self.instance, true)
    end

    function label.ChangeText(self: Label, newText: string)
        self.instance.Text = newText
    end

    function label.Destroy(self: Label)
        self.instance:Destroy()

        table.clear(self :: any)
    end

    label:UpdateTheme()
    instance.Parent = parent

    return label
end

return Label