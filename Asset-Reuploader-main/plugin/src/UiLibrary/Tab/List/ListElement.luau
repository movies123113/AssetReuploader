--!strict
local ListElement = {}

local Theme = require("../../Theme")

local assets = script.Parent.Parent.Parent.Assets
local listButton = assets.XButton
local elementAsset = assets.ListElement
local listAsset = assets.List

export type ListElement = {
    _clickedConnection: RBXScriptConnection?,
    _remove: () -> (),
    _removedConnection: RBXScriptConnection?,

    instance: typeof(elementAsset),
    selected: boolean,

    AddRemoveButton: (self: ListElement, callback: () -> ()?) -> ListElement,
    OnClicked: (self: ListElement, callback: () -> ()) -> ListElement,
    UpdateTheme: (self: ListElement) -> (),
    Destroy: (self: ListElement) -> (),
}

function ListElement.new(parent: typeof(listAsset.ScrollingFrame), remove: () -> ()?, value: string): ListElement
    local instance = elementAsset:Clone()
    instance.TextLabel.Text = value

    local listElement: ListElement; listElement = {
        _remove = remove,

        instance = instance
    } :: ListElement

    function listElement.AddRemoveButton(self: ListElement, callback: () -> ()?): ListElement
        local button = listButton:Clone()
        button.Parent = instance

        listElement._removedConnection =  button.MouseButton1Down:Connect(function()
            if callback then
                callback()
            end

            self._remove()
            self:Destroy()
        end)

        listElement:UpdateTheme()
        return listElement
    end

    function listElement.OnClicked(self: ListElement, callback: () -> ()): ListElement
        local element = self.instance
        self._clickedConnection = element.MouseButton1Down:Connect(function()
            callback()
        end)

        local theme = Theme.get()
        element.BackgroundColor3 = theme.UnselectedColor

        return listElement
    end

    function listElement.UpdateTheme(self: ListElement)
        local theme = Theme.get()
        
        local element = self.instance
        Theme.updateFrame(element)
        if self._clickedConnection then
            element.BackgroundColor3 = self.selected and theme.SelectedColor or theme.UnselectedColor
        end

        if self._removedConnection then
            local elementButton = (element :: any).XButton
            Theme.updateFrame(elementButton)
            elementButton.ImageColor3 = theme.TextColor
            elementButton.BackgroundColor3 = theme.UnselectedColor
        end

        Theme.updateText(element.TextLabel, false)
    end

    function listElement.Destroy(self: ListElement)
        if self._removedConnection then self._removedConnection:Disconnect() end
        if self._clickedConnection then self._clickedConnection:Disconnect() end

        self.instance:Destroy()

        table.clear(self :: any)
    end

    listElement:UpdateTheme()
    instance.Parent = parent

    return listElement
end

return ListElement