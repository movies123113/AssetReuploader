--!strict
local Input = {}

local BaseButton = require("../../BaseButton")
local Theme = require("../../Theme")
local Tip = require("../../Tip")

local inputAsset = script.Parent.Parent.Parent.Assets.TextInput

export type Input = {
    _button: BaseButton.BaseButton<typeof(inputAsset.Button)>,
    _tip: Tip.Tip,

    instance: typeof(inputAsset),

    UpdateTheme: (self: Input) -> (),
    AddTip: (self: Input, tip: Tip.Tip) -> (),
    Destroy: (self: Input) -> ()
}

function Input.new(parent: GuiObject, placeholderText: string, callback: (input: string) -> ()): Input
    local instance = inputAsset:Clone()
    local inputBox = instance.TextBox
    inputBox.PlaceholderText = placeholderText

    local input = {
        _button = BaseButton.new(instance.Button, true, function()
            local text = inputBox.Text
            if text == "" then return end
            inputBox.Text = ""
            callback(text)
        end),

        instance = instance
    } :: Input

    function input.UpdateTheme(self: Input)
        local theme = Theme.get()

        local button = self.instance
        button.BackgroundColor3 = theme.UnselectedColor
        button.BorderColor3 = theme.BorderColor

        local addButton = button.Button
        addButton.BackgroundColor3 = theme.UnselectedColor
        addButton.BorderColor3 = theme.BorderColor
        addButton.ImageColor3 = theme.TextColor

        Theme.updateText(button.TextBox, true)

        if self._tip then
            self._tip:UpdateTheme()
        end
    end

    function input.AddTip(self: Input, tip: Tip.Tip)
        local textBox = self.instance.TextBox
        textBox.Position = UDim2.new(0, 25, 0.5, 0)
        textBox.Size = UDim2.new(1, -45, 1, -2)

        local tipFrame = tip.instance
        tipFrame.Position = UDim2.new(0, 5, 0.5, 0)
        tipFrame.Parent = self.instance

        self._tip = tip
    end

    function input.Destroy(self: Input)
        if self._tip then self._tip:Destroy() end
        self._button:Destroy()
        self.instance:Destroy()

        table.clear(self :: any)
    end

    input:UpdateTheme()
    instance.Parent = parent

    return input
end

return Input