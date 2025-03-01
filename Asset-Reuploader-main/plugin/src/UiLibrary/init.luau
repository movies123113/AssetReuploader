--!strict
local UiLibrary = {}

local Tab = require("./UiLibrary/Tab")
local Theme = require("./UiLibrary/Theme")
local Tip = require("./UiLibrary/Tip")

local mainFrameAsset = script.Assets.MainFrame

type ThemeManager = typeof(Theme)

export type Ui = {
	_currentTabIndex: number,
	_notificationClosed: RBXScriptConnection,
	_studioThemeChanged: RBXScriptConnection,
	_tabs: { Tab.Tab },

	theme: ThemeManager,
	instance: typeof(mainFrameAsset),

	CreateTab: (self: Ui, name: string) -> Tab.Tab,
	CreateTip: (self: Ui, text: string) -> Tip.Tip,
	Notify: (self: Ui, title: string, description: string) -> (),
	UpdateTheme: (self: Ui) -> (),
	Destroy: (self: Ui) -> ()
}

local function selectTab(self: Ui, tabIndex: number)
	if self._currentTabIndex ~= 0 then
		local tabToUnselect = self._tabs[self._currentTabIndex]
		tabToUnselect.button:ColorUnselected()
		tabToUnselect.instance.Visible = false
	end

	local tabToSelect = self._tabs[tabIndex]
	tabToSelect.button:ColorSelected()
	tabToSelect.instance.Visible = true

	self._currentTabIndex = tabIndex
end

function UiLibrary.new(parent: Instance, plugin: Plugin): Ui
	local instance = mainFrameAsset:Clone()

	local notificationFrame = instance.Frame.Notification
	local ui: Ui; ui = {
		_currentTabIndex = 0,
		_notificationClosed = notificationFrame.Main.Frame.Close.MouseButton1Down:Connect(function()
			notificationFrame.Visible = false
		end),
		_studioThemeChanged = settings().Studio.ThemeChanged:Connect(function()
			Theme.set(Theme.get().Id)
			ui:UpdateTheme()
		end),
		_tabs = {},

		theme = Theme,
		instance = instance,
	} :: Ui

	Theme.init(plugin)

	function ui.CreateTab(self: Ui, name: string): Tab.Tab
		local tabIndex = #self._tabs + 1
		local tab = Tab.new(self.instance.Frame :: any, function()
			if self._currentTabIndex == tabIndex then return end
			selectTab(self, tabIndex)
		end, name)
		table.insert(self._tabs, tab)

		local topbar = self.instance.Frame.Topbar
		local padding = topbar.Frame.UIPadding
		local gridLayout = topbar.Frame.UIGridLayout
		local tabCount = #topbar.Frame:GetChildren() - 2
		gridLayout.CellSize = UDim2.new(1 / tabCount, tabCount > 1 and -2 or 0, 1, 0)

		if tabCount % 2 == 0 then
			padding.PaddingRight = UDim.new(0, 3)
		else
			padding.PaddingRight = UDim.new(0, 2)
		end

		if self._currentTabIndex == 0 then
			selectTab(self, tabIndex)
		end
		return tab
	end

	function ui.CreateTip(self: Ui, text: string): Tip.Tip
		return Tip.new(self.instance.Frame.Tip :: any, text)
	end

	function ui.Notify(self: Ui, title: string, description: string)
		local notification = self.instance.Frame.Notification

		local mainFrame = notification.Main.Frame
		mainFrame.Description.Text = description
		mainFrame.Title.Text = title

		notification.Visible = true
	end

	function ui.UpdateTheme(self: Ui)
		local theme = Theme.get()
		
		local uiFrame = self.instance.Frame
		uiFrame.Back.BackgroundColor3 = theme.BackgroundColor

		local main = uiFrame.Main
		main.BackgroundColor3 = theme.BorderColor
		main.Frame.Image = theme.BackgroundImage
		main.Frame.BackgroundColor3 = theme.MainBackgroundColor

		local topBar = uiFrame.Topbar
		topBar.BackgroundColor3 = theme.BorderColor
		topBar.Frame.BackgroundColor3 = theme.MainBackgroundColor

		local notification = uiFrame.Notification
		notification.Image = theme.NotificationBackgroundImage
		notification.Main.BackgroundColor3 = theme.BorderColor
		notification.Main.Frame.Image = theme.NotificationImage
		notification.Main.Frame.BackgroundColor3 = theme.MainBackgroundColor

		local notificationMainFrame = notification.Main.Frame
		Theme.updateText(notificationMainFrame.Close, true)
		Theme.updateText(notificationMainFrame.Description, true)
		Theme.updateText(notificationMainFrame.Title, true)

		local tipbar = uiFrame.Tip
		tipbar.BackgroundColor3 = theme.BorderColor
		tipbar.Frame.BackgroundColor3 = theme.MainBackgroundColor

		Theme.updateText(tipbar.Frame.TipText)

		for _, tab in self._tabs do
			tab:UpdateTheme()
		end

		if self._currentTabIndex ~= 0 then
			self._tabs[self._currentTabIndex].button:ColorSelected() 
		end
	end

	function ui.Destroy(self: Ui)
		for _, tab in self._tabs do
			tab:Destroy()
		end

		self._studioThemeChanged:Disconnect()
		self._notificationClosed:Disconnect()

		self.instance:Destroy()

		table.clear(self :: any)
	end

	ui:UpdateTheme()
	instance.Parent = parent

	return ui
end

return UiLibrary
