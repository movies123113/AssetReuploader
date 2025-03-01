--!strict
local Button = {}

local BaseButton = require("../BaseButton")
local Theme = require("../Theme")

local buttonAsset = script.Parent.Parent.Assets.Button

type ButtonAsset = typeof(buttonAsset)

export type Button = BaseButton.BaseButton<ButtonAsset> & {
    _destroy: (self: BaseButton.BaseButton<ButtonAsset>) -> (),

    UpdateTheme: (self: Button) -> (),
    Destroy: (self: Button) -> ()
}

function Button.new(parent: GuiObject, text: string, autoColor: boolean, callback: () -> ()): Button
    local instance = buttonAsset:Clone()
    instance.Text = text

    local button = BaseButton.new(instance, autoColor, callback) :: Button
    button._destroy = button.Destroy

    function button.UpdateTheme(self: Button)
        Theme.updateText(self.instance, true)

        local theme = Theme.get()
        self.instance.BackgroundColor3 = theme.UnselectedColor
    end

    function button.Destroy(self: Button)
        self.instance:Destroy()
        self._destroy(self)
    end

    button:UpdateTheme()
    instance.Parent = parent

    return button
end

return Button