local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Tween = game:GetService("TweenService")

local soundModule = require(ReplicatedStorage.Shared.Sound)
local questionModule = require(ReplicatedStorage.Shared.Question)

function initGame(this: Model)
	-- Table to handle settings retrieval and updates
	local settings = setmetatable({}, {
		__index = function(_, k)
			return this.Settings:GetAttribute(k)
		end,

		__newIndex = function(_, k, v)
			return this.Settings:SetAttribute(k, v)
		end,
	})

	-- Utility function to send question and options to a player
	local function sendQA(player: Player, Table: Model, questionData: { question: string, options: {string} })
		ReplicatedStorage.Events.Question:FireClient(player, Table, questionData)
	end

	local function createTween(card, speed, propertyTable)
		local tweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		return Tween:Create(card, tweenInfo, propertyTable)
	end

	-- Function to spawn a question and its corresponding cards
	local function spawnQA(Table: Model)
		Table.QA:ClearAllChildren()

		for _, pos: Part in pairs(Table.Positions:GetChildren()) do
			local isQuestion = (pos.Name == "Question")
			local itemModel = isQuestion and ServerStorage.Question:Clone() or ServerStorage.Card:Clone()
			itemModel:PivotTo(pos:GetPivot())
			itemModel.Parent = Table.QA

			if not isQuestion then
				itemModel.Size = Vector3.new(0, 0, 0)
				local questionPos = Table.Positions.Question.Position
				itemModel.CFrame = pos.CFrame * CFrame.Angles(math.pi, 0, 0)

				local cardTween = createTween(itemModel, .5, {
					Size = Vector3.new(0.5, 1, 0.01) 
				})
				cardTween:Play()
				soundModule.play("CardSpawn", itemModel, nil, nil, true)
			end
		end
	end

	-- Main quiz game logic
	local function runQuiz()
		local previousQuestions = {}

		while true do
			local questionData = questionModule.randQuestion(previousQuestions)
			if #previousQuestions > 1 then
				table.remove(previousQuestions, 1)
			end
			table.insert(previousQuestions, questionData.question)

			spawnQA(this.TableA)
			task.wait(.1)

			local playerA = Players:GetPlayerByUserId(settings.PlayerA)
			sendQA(playerA, this.TableA, questionData)

			local connection
			connection = ReplicatedStorage.Events.Question.OnServerEvent:Connect(function(player: Player, card: Part, playerAnswer: string)
				if player.UserId ~= settings.PlayerA then return end

				ReplicatedStorage.Events.Question:FireClient(player, questionData.options[questionData.answerIdx], card)
				if playerAnswer ~= questionData.options[questionData.answerIdx] then
					task.wait(5)
				end

				task.wait(1)
				connection:Disconnect()
			end)

			repeat task.wait() until not connection.Connected
		end
	end

	local promptA = this.TableA.Prompt
	promptA.Triggered:Connect(function(player: Player)
		if not settings.PlayerA then
			settings.PlayerA = player.UserId
			promptA.Enabled = false
		end
	end)

	while true do
		if settings.PlayerA then
			runQuiz()
		else
			promptA.Enabled = true
		end
		task.wait()
	end
end

for _, gameModel in pairs(workspace.Tables:GetChildren()) do
	task.spawn(function()
		initGame(gameModel)
	end)
end