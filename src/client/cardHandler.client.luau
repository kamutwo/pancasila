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

local function cardLabel(card: Part)
	return card.Front.container.label
end

local function cardHandler(card: Part, option: string)
	cardLabel(card).Text = option

	local originalPos = card.CFrame
	card:SetAttribute("originalPos", originalPos)

	table.insert(connections, card:WaitForChild("prompt").ProximityPrompt.Triggered:Once(function()
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
		local sCard: Part = args[2]
		local correctCard: Part = nil

		for _, card in pairs(sCard.Parent:GetChildren()) do
			if card.Name == "Question" then continue end
			local label = cardLabel(card)
			local color: Color3 = nil

			if label.Text == answer then
				correctCard = card
				color = sCard == card and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
			else
				color = sCard == card and Color3.fromRGB(255, 2, 2) or Color3.fromRGB(226, 30, 30)
			end
			card:SetAttribute("Color", color)

			local highlight = Instance.new("Highlight")
			highlight.FillTransparency = 1
			highlight.OutlineColor = color
			highlight.Enabled = false
			highlight.Parent = card
		end

		if correctCard == sCard then
			sCard.Highlight.Enabled = true

			local color = sCard:GetAttribute("Color")
			sCard.Front.container.ImageColor3 = color
			cardLabel(sCard).TextColor3 = color

			soundModule.play("Correct", sCard, nil, nil, true)
		else
			for _, card in pairs(sCard.Parent:GetChildren()) do
				if card.Name ~= "Card" then continue end
				card.Highlight.Enabled = true

				local color = card:GetAttribute("Color")
				card.Front.container.ImageColor3 = color
				cardLabel(card).TextColor3 = color

				local goal = card == correctCard and CFrame.lookAt(camera.CFrame.Position + camera.CFrame.LookVector * 1.5 + camera.CFrame.UpVector * -.1, camera.CFrame.Position) or CFrame.new(card:GetAttribute("originalPos").Position + Vector3.new(0, 0.8, 0), camera.CFrame.Position)
				local tween = createTween(card, .5, { CFrame = goal })
				tween:Play()
			end
			soundModule.play("Wrong", sCard, nil, nil, true)
		end
	elseif args[1] == nil then
		table.clear(cards)
		for _, c in pairs(connections) do c:Disconnect() end
	end
end)

RunService.RenderStepped:Connect(function()
	local nearest, card = 25, nil
	for _, c in ipairs(cards) do
		local cardPos, _ = camera:WorldToViewportPoint(c:GetAttribute("originalPos").Position)
		local dist = (Vector2.new(cardPos.X, cardPos.Y) - UIS:GetMouseLocation()).Magnitude

		if dist < nearest then
			nearest = dist
			card = c
		end
	end

	if not card then
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