local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Tween = game:GetService("TweenService")

local soundModule = require(ReplicatedStorage.Shared.Sound)
local questionModule = require(ReplicatedStorage.Shared.Question)

-- Utility
local function sendQA(player: Player, Table: Model, questionData: { question: string, options: {string} })
	ReplicatedStorage.Events.Question:FireClient(player, Table, questionData)
end

local function createTween(card, speed, propertyTable)
	local tweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	return Tween:Create(card, tweenInfo, propertyTable)
end

-- Game Logic
local function spawnQA(Table: Model)
	Table.QA:ClearAllChildren()

	for _, pos: Part in pairs(Table.Positions:GetChildren()) do
		local isQuestion = (pos.Name == "Question")
		local itemModel = isQuestion and ServerStorage.Question:Clone() or ServerStorage.Card:Clone()
		itemModel:PivotTo(pos:GetPivot())
		itemModel.Parent = Table.QA

		if not isQuestion then
			itemModel.Size = Vector3.new(0, 0, 0)
			itemModel.CFrame = pos.CFrame * CFrame.Angles(math.pi, 0, 0)

			local cardTween = createTween(itemModel, .5, {
				Size = Vector3.new(0.5, 1, 0.01)
			})
			cardTween:Play()
			soundModule.play("CardSpawn", itemModel, nil, nil, true)
		end
	end
end

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

	local function runQuiz(userId: number, Table: Model)
		local previousQuestions = {}

		task.spawn(function()
			while true do
				local questionData = questionModule.randQuestion(previousQuestions)
				if #previousQuestions > 1 then
					table.remove(previousQuestions, 1)
				end
				table.insert(previousQuestions, questionData.question)

				spawnQA(Table)
				task.wait(.1)

				local player = Players:GetPlayerByUserId(userId)
				sendQA(player, Table, questionData)

				local connection
				connection = ReplicatedStorage.Events.Question.OnServerEvent:Connect(function(player: Player, card: Part, playerAnswer: string)
					if player.UserId ~= userId then return end

					local correctAnswer = questionData.options[questionData.answerIdx]
					ReplicatedStorage.Events.Question:FireClient(player, correctAnswer, card)
					if playerAnswer ~= correctAnswer then
						settings.ScoreA -= 10

						task.wait(5)
					else
						settings.ScoreA += 5
					end

					task.wait(1)
					connection:Disconnect()
				end)

				repeat task.wait() until not connection.Connected
			end
		end)
	end

	local function setupPrompt(table)
		local prompt = table.Prompt
		prompt.Triggered:Connect(function(player)
			settings[table:GetAttribute("plrVar")] = player.UserId
			prompt.Enabled = false
		end)
		return prompt
	end

	local promptA = setupPrompt(this.TableA)
	while true do
		if settings.PlayerA then
			runQuiz(settings.PlayerA, this.TableA)
		else
			promptA.Enabled = true
		end
		task.wait()
	end
end

for _, tableModel in pairs(workspace.Tables:GetChildren()) do
	task.spawn(function()
		initGame(tableModel)
	end)
end