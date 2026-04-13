-- Place ID Check
if game.PlaceId == 3095204897 then
	print("ok")
	return
end

local env = getgenv()
if env.LastExecuted and tick() - env.LastExecuted < 5 then return end
env.LastExecuted = tick()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Clean up old GUI
if CoreGui:FindFirstChild("CustomEmoteHub") then
	CoreGui.CustomEmoteHub:Destroy()
end

local Emotes = {}
local FavoritedEmotes = {}
local catalogPages = nil
local isLoadingMore = false
local FetchDebounce = false

-- Rate Limit Protection Cache
local EmoteCache = {} 

-- Load Favorites
if isfile and isfile("FavoritedEmotes.txt") then
	local succ, res = pcall(function()
		return HttpService:JSONDecode(readfile("FavoritedEmotes.txt"))
	end)
	if succ and type(res) == "table" then
		FavoritedEmotes = res
	end
end

local function SaveFavorites()
	if writefile then
		writefile("FavoritedEmotes.txt", HttpService:JSONEncode(FavoritedEmotes))
	end
end

-------------------------------------------------------------------------------
-- UI CONSTRUCTION
-------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomEmoteHub"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = (get_hidden_gui and get_hidden_gui()) or CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 450, 0, 350)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Top Bar & Dragging
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.Text = "Emote Hub | <font color='#FFD700'>HeavenlyReminiscence</font>"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = TopBar

-- Drag Logic
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)
TopBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Tabs
local CatalogTabBtn = Instance.new("TextButton")
CatalogTabBtn.Size = UDim2.new(0.5, 0, 0, 30)
CatalogTabBtn.Position = UDim2.new(0, 0, 0, 30)
CatalogTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CatalogTabBtn.Text = "Catalog"
CatalogTabBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
CatalogTabBtn.Font = Enum.Font.GothamBold
CatalogTabBtn.TextSize = 14
CatalogTabBtn.BorderSizePixel = 0
CatalogTabBtn.Parent = MainFrame

local FavTabBtn = Instance.new("TextButton")
FavTabBtn.Size = UDim2.new(0.5, 0, 0, 30)
FavTabBtn.Position = UDim2.new(0.5, 0, 0, 30)
FavTabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
FavTabBtn.Text = "Favorites"
FavTabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
FavTabBtn.Font = Enum.Font.GothamBold
FavTabBtn.TextSize = 14
FavTabBtn.BorderSizePixel = 0
FavTabBtn.Parent = MainFrame

-- Tab Containers
local CatalogContainer = Instance.new("Frame")
CatalogContainer.Size = UDim2.new(1, 0, 1, -60)
CatalogContainer.Position = UDim2.new(0, 0, 0, 60)
CatalogContainer.BackgroundTransparency = 1
CatalogContainer.Parent = MainFrame

local FavContainer = Instance.new("Frame")
FavContainer.Size = UDim2.new(1, 0, 1, -60)
FavContainer.Position = UDim2.new(0, 0, 0, 60)
FavContainer.BackgroundTransparency = 1
FavContainer.Visible = false
FavContainer.Parent = MainFrame

-- Tab Switching Logic
CatalogTabBtn.MouseButton1Click:Connect(function()
	CatalogContainer.Visible = true
	FavContainer.Visible = false
	CatalogTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	CatalogTabBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
	FavTabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	FavTabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
end)

FavTabBtn.MouseButton1Click:Connect(function()
	CatalogContainer.Visible = false
	FavContainer.Visible = true
	FavTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	FavTabBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
	CatalogTabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	CatalogTabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
end)

-- Search & Random Bar
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(0.7, -10, 0, 25)
SearchBox.Position = UDim2.new(0, 10, 0, 10)
SearchBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.PlaceholderText = " Search Catalog (Press Enter)..."
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.BorderSizePixel = 0
SearchBox.Parent = CatalogContainer
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 4)

local RandomCatBtn = Instance.new("TextButton")
RandomCatBtn.Size = UDim2.new(0.3, -20, 0, 25)
RandomCatBtn.Position = UDim2.new(0.7, 10, 0, 10)
RandomCatBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
RandomCatBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
RandomCatBtn.Text = "🎲 Random"
RandomCatBtn.Font = Enum.Font.GothamBold
RandomCatBtn.TextSize = 13
RandomCatBtn.BorderSizePixel = 0
RandomCatBtn.Parent = CatalogContainer
Instance.new("UICorner", RandomCatBtn).CornerRadius = UDim.new(0, 4)

-- Scrolling Frames
local function CreateScrollFrame(parent)
	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Size = UDim2.new(1, -20, 1, -55)
	Scroll.Position = UDim2.new(0, 10, 0, 45)
	Scroll.BackgroundTransparency = 1
	Scroll.ScrollBarThickness = 4
	Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Scroll.Parent = parent

	local Grid = Instance.new("UIGridLayout")
	Grid.CellSize = UDim2.new(0, 80, 0, 100)
	Grid.CellPadding = UDim2.new(0, 5, 0, 5)
	Grid.SortOrder = Enum.SortOrder.LayoutOrder
	Grid.Parent = Scroll
	return Scroll
end

local CatScroll = CreateScrollFrame(CatalogContainer)
local FavScroll = CreateScrollFrame(FavContainer)

local RandomFavBtn = RandomCatBtn:Clone()
RandomFavBtn.Parent = FavContainer
RandomFavBtn.Position = UDim2.new(0, 10, 0, 10)
RandomFavBtn.Size = UDim2.new(1, -20, 0, 25)

-------------------------------------------------------------------------------
-- FUNCTIONALITY
-------------------------------------------------------------------------------
local function PlayEmote(id, name)
	local Character = LocalPlayer.Character
	if not Character then return end
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")
	if not Animator then return end

	-- Stop old custom emotes to prevent bizarre body blending
	for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
		if track:GetAttribute("IsCustomEmote") then
			track:Stop()
		end
	end

	if Humanoid.RigType == Enum.HumanoidRigType.R6 then return end

	-- Bypass rate limits via internal Cache
	if EmoteCache[id] then
		local customTrack = Animator:LoadAnimation(EmoteCache[id])
		customTrack.Priority = Enum.AnimationPriority.Action4 -- Overrides Animate script
		customTrack:SetAttribute("IsCustomEmote", true)
		customTrack:Play()
		return
	end

	local Description = Humanoid:FindFirstChildOfClass("HumanoidDescription")
	if not Description then return end

	-- Initial load: Add to description and secretly extract the Animation Track
	local success, r1, r2 = pcall(function()
		Description:AddEmote(name or "Emote", id)
		return Humanoid:PlayEmoteAndGetAnimTrackById(id)
	end)

	local nativeTrack = nil
	if typeof(r1) == "Instance" and r1:IsA("AnimationTrack") then
		nativeTrack = r1
	elseif typeof(r2) == "Instance" and r2:IsA("AnimationTrack") then
		nativeTrack = r2
	end

	if success and nativeTrack then
		local animId = nativeTrack.Animation.AnimationId
		nativeTrack:Stop() -- Assassinate the native track instantly

		-- Resurrect it as a custom track the Animate script has no authority over
		local customAnim = Instance.new("Animation")
		customAnim.AnimationId = animId
		EmoteCache[id] = customAnim 

		local customTrack = Animator:LoadAnimation(customAnim)
		customTrack.Priority = Enum.AnimationPriority.Action4
		customTrack:SetAttribute("IsCustomEmote", true)
		customTrack:Play()
	end
end

local function CreateEmoteCard(emote, parentScroll)
	local Card = Instance.new("Frame")
	Card.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	Card.BorderSizePixel = 0
	Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)

	local Icon = Instance.new("ImageButton")
	Icon.Size = UDim2.new(1, 0, 0, 75)
	Icon.BackgroundTransparency = 1
	Icon.Image = "rbxthumb://type=Asset&id=" .. emote.id .. "&w=150&h=150"
	Icon.Parent = Card
	
	local NameLabel = Instance.new("TextLabel")
	NameLabel.Size = UDim2.new(1, 0, 0, 25)
	NameLabel.Position = UDim2.new(0, 0, 0, 75)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = emote.name
	NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	NameLabel.Font = Enum.Font.Gotham
	NameLabel.TextSize = 11
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.Parent = Card

	local FavToggle = Instance.new("TextButton")
	FavToggle.Size = UDim2.new(0, 20, 0, 20)
	FavToggle.Position = UDim2.new(1, -22, 0, 2)
	FavToggle.BackgroundTransparency = 1
	FavToggle.TextSize = 14
	FavToggle.Font = Enum.Font.GothamBold
	FavToggle.Parent = Card

	local isFav = table.find(FavoritedEmotes, emote.id)
	FavToggle.Text = isFav and "⭐" or "☆"
	FavToggle.TextColor3 = isFav and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 150, 150)

	Icon.MouseButton1Click:Connect(function()
		PlayEmote(emote.id, emote.name)
	end)

	FavToggle.MouseButton1Click:Connect(function()
		local idx = table.find(FavoritedEmotes, emote.id)
		if idx then
			table.remove(FavoritedEmotes, idx)
			FavToggle.Text = "☆"
			FavToggle.TextColor3 = Color3.fromRGB(150, 150, 150)
		else
			table.insert(FavoritedEmotes, emote.id)
			FavToggle.Text = "⭐"
			FavToggle.TextColor3 = Color3.fromRGB(255, 215, 0)
		end
		SaveFavorites()
		RefreshFavorites()
	end)

	Card.Parent = parentScroll
end

function RefreshFavorites()
	for _, child in ipairs(FavScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for _, id in ipairs(FavoritedEmotes) do
		local emoteData = {id = id, name = "Saved Emote"}
		for _, e in ipairs(Emotes) do
			if e.id == id then emoteData.name = e.name; break end
		end
		CreateEmoteCard(emoteData, FavScroll)
	end
end

local function ProcessCatalogPage(pageData)
	for _, item in ipairs(pageData) do
		local exists = false
		for _, e in ipairs(Emotes) do
			if e.id == item.Id then exists = true; break end
		end
		if not exists then
			local eData = {name = item.Name, id = item.Id}
			table.insert(Emotes, eData)
			CreateEmoteCard(eData, CatScroll)
		end
	end
end

local function FetchCatalog(keyword)
	if FetchDebounce then return end
	FetchDebounce = true

	for _, child in ipairs(CatScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	Emotes = {}
	
	task.spawn(function()
		local success, pages = pcall(function()
			local params = CatalogSearchParams.new()
			params.AssetTypes = {Enum.AvatarAssetType.EmoteAnimation}
			params.SortType = keyword and Enum.CatalogSortType.Relevance or Enum.CatalogSortType.RecentlyUpdated
			if keyword and keyword ~= "" then params.SearchKeyword = keyword end
			params.Limit = 120
			return AvatarEditorService:SearchCatalog(params)
		end)

		if success and pages then
			catalogPages = pages
			ProcessCatalogPage(pages:GetCurrentPage())
			RefreshFavorites()
		end
		
		task.wait(1.5) -- Throttle to prevent SearchCatalog rate limiting
		FetchDebounce = false
	end)
end

-- Safely Load More
CatScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	local maxScroll = CatScroll.AbsoluteCanvasSize.Y - CatScroll.AbsoluteWindowSize.Y
	if CatScroll.CanvasPosition.Y >= maxScroll - 50 and not isLoadingMore then
		if catalogPages and not catalogPages.IsFinished then
			isLoadingMore = true
			local success = pcall(function() catalogPages:AdvanceToNextPageAsync() end)
			if success then
				ProcessCatalogPage(catalogPages:GetCurrentPage())
			end
			task.wait(1.2) -- Breather for API rate limits
			isLoadingMore = false
		end
	end
end)

SearchBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		FetchCatalog(SearchBox.Text)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Comma then
		MainFrame.Visible = not MainFrame.Visible
	end
end)

RandomCatBtn.MouseButton1Click:Connect(function()
	if #Emotes > 0 then
		local rand = Emotes[math.random(1, #Emotes)]
		PlayEmote(rand.id, rand.name)
	end
end)

RandomFavBtn.MouseButton1Click:Connect(function()
	if #FavoritedEmotes > 0 then
		local randId = FavoritedEmotes[math.random(1, #FavoritedEmotes)]
		PlayEmote(randId, "Emote")
	end
end)

FetchCatalog()
