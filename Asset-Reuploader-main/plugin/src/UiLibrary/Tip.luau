--!strict
local Tip = {}

local Theme = require("./Theme")

local assets = script.Parent.Assets
local tipAsset = assets.InfoButton
local tipBarAsset = assets.MainFrame.Frame.Tip

type TipBar = typeof(tipBarAsset)

export type Tip = {
    _tipBar: TipBar,

    instance: typeof(tipAsset),

    UpdateTheme: (self: Tip) -> (),
    Destroy: (self: Tip) -> ()
}

function Tip.new(tipBar: TipBar, text: string): Tip
    local instance = tipAsset:Clone()
    local tip = {
        _tipBar = tipBar,

        instance = instance
    } :: Tip

    instance.MouseEnter:Connect(function()
        local theme = Theme.get()
        instance.ImageColor3 = theme.TextColor

        tipBar.Frame.TipText.Text = text
        tipBar.Visible = true
    end)

    instance.MouseLeave:Connect(function()
        local theme = Theme.get()
        instance.ImageColor3 = theme.DimmedTextColor

        tipBar.Visible = false
    end)

    function tip.UpdateTheme(self: Tip)
        local theme = Theme.get()
        self.instance.ImageColor3 = theme.DimmedTextColor
    end

    function tip.Destroy(self: Tip)
        self.instance:Destroy()
        table.clear(self :: any)
    end

    tip:UpdateTheme()
    return tip
end

return Tip