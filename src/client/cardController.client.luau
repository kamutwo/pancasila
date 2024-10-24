local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Tween = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local soundModule = require(ReplicatedStorage.Shared.Sound)

local client = Players.LocalPlayer
local camera = workspace.CurrentCamera

local cards = {}
local selectedCard = nil
local connections = {}

local function createTween(instance, speed, propertyTable)
	local tweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	return Tween:Create(instance, tweenInfo, propertyTable)
end

local function cardHandler(card: Part, option: string)
	card.Front.container.label.Text = option

	local originalPos = card.CFrame
	card:SetAttribute("originalPos", originalPos)

	table.insert(connections, card.prompt.ProximityPrompt.Triggered:Once(function()
		table.clear(cards)
		card.prompt.ProximityPrompt.Enabled = false

		ReplicatedStorage.Events.Question:FireServer(card, option)		
		for _, c in pairs(connections) do c:Disconnect() end
	end))

	table.insert(connections, RunService.RenderStepped:Connect(function()
		if card ~= selectedCard then
			card:PivotTo(card.CFrame:Lerp(originalPos, .15))
			card.prompt.ProximityPrompt.Enabled = false
			return
		end
	end))

	table.insert(cards, card)

end

ReplicatedStorage.Events.Question.OnClientEvent:Connect(function(...: any)
	local args = table.pack(...)

	if typeof(args[1]) == "Instance" then
		local Table = args[1]
		local questionData = args[2]

		for _, qa in pairs (Table.QA:GetChildren()) do
			if qa.Name == "Question" then
				qa.Front.container.question.Text = questionData.question
				local tween = createTween(qa.Front.container.question, .5, { TextTransparency = 0 })
				tween:Play()
				continue
			end

			local randomIdx = math.random(1, #questionData.options)
			cardHandler(qa, questionData.options[randomIdx])

			table.remove(questionData.options, randomIdx)
		end
	elseif typeof(args[1]) == "string" then
		local answer = args[1]
		local cardM: Part = args[2]

		for _, card in pairs (cardM.Parent:GetChildren()) do
			if card.Name ~= "Card" then continue end

			local label = card.Front.container.label
			if label.Text ~= answer then
				local color = Color3.fromRGB(255, 42, 42)
				card.Front.container.ImageColor3 = color
				label.TextColor3 = color

				local highlight = Instance.new("Highlight")
				highlight.FillTransparency = 1
				highlight.OutlineColor = color
				highlight.Parent = card
			else
				local color = Color3.fromRGB(0, 255, 0)
				card.Front.container.ImageColor3 = color
				label.TextColor3 = color

				local highlight = Instance.new("Highlight")
				highlight.FillTransparency = 1
				highlight.OutlineColor = color
				highlight.Parent = card
			end

			if card ~= cardM then
				local tween = createTween(card, .5, { CFrame = CFrame.new(card.Position + Vector3.new(0, 0.8, 0), camera.CFrame.Position) })
				tween:Play()				
			end
		end

		if cardM.Front.container.label.Text ~= answer then
			print("yeah")
			soundModule.play("Wrong", cardM, nil, nil, true)
		else
			print("no")
			soundModule.play("Right", cardM, nil, nil, true)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local nearest, card = 25, nil
	for _, c in ipairs(cards) do
		local cardPos, onScreen = camera:WorldToViewportPoint(c:GetAttribute("originalPos").Position)
		local dist = (Vector2.new(cardPos.X, cardPos.Y) - UIS:GetMouseLocation()).Magnitude

		if dist < nearest then
			nearest = dist
			card = c
		end
	end

	if not card then
		client.PlayerGui:WaitForChild("Cursor").Enabled = true
		selectedCard = nil
		return
	end
	client.PlayerGui.Cursor.Enabled = false
	card.prompt.ProximityPrompt.Enabled = true

	if selectedCard ~= card then
		soundModule.play("CardTurn", card, nil, nil, true)
	end
	selectedCard = card

	local goal = CFrame.lookAt(camera.CFrame.Position + camera.CFrame.LookVector * 1.5 + camera.CFrame.UpVector * -.1, camera.CFrame.Position)
	card:PivotTo(card.CFrame:Lerp(goal, .15))
end)