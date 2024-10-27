local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Tween = game:GetService("TweenService")

local GameClass = require(script.Parent.modules.Game)
local soundModule = require(ReplicatedStorage.Shared.Sound)
local questionModule = require(ReplicatedStorage.Shared.Question)

-- Utility
local function sendSystemMessage(text: string)
	ReplicatedStorage.Events.System:FireAllClients(text)
end

local function createTween(card, speed, propertyTable)
	local tweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	return Tween:Create(card, tweenInfo, propertyTable)
end

local function playCardTween(card)
	card.Size = Vector3.new(0, 0, 0)
	card.CFrame = card.CFrame * CFrame.Angles(math.pi, 0, 0)

	local tween = createTween(card, 0.5, { Size = Vector3.new(0.5, 1, 0.01) })
	tween:Play()

	soundModule.play("CardSpawn", card, nil, nil, true)
end

local function spawnQA(Table)
	Table.QA:ClearAllChildren()

	for _, pos in pairs(Table.Positions:GetChildren()) do
		local isQuestion = (pos.Name == "Question")
		local itemModel = (isQuestion and ServerStorage.Question or ServerStorage.Card):Clone()
		itemModel:PivotTo(pos:GetPivot())
		itemModel.Parent = Table.QA

		if not isQuestion then
			playCardTween(itemModel)
		end
	end
end

local function sendQA(player: Player, Table, questionData)
	ReplicatedStorage.Events.Question:FireClient(
		player,
		Table,
		{ question = questionData.question, options = questionData.options }
	)
end

local function updateGameUI(Game)
	for _, player in ipairs(Game.players) do
		ReplicatedStorage.Events.Players:FireClient(player.player, "updatePlayer", Game.players)
	end
end

local function removeGameUI(Game, playerDatas)
	for _, player in ipairs(Game.players) do
		ReplicatedStorage.Events.Players:FireClient(player.player, "end", playerDatas)
	end
end

local function isPlayerAlive(player)
	return player.health > 0
		and player.player.Character
		and player.player.Character:FindFirstChild("Humanoid")
		and player.player.Character.Humanoid.Health > 0
end

local function initGame(this)
	local Game = GameClass.new()

	local function initPlayerPrompt(v)
		local prompt: ProximityPrompt = v.Prompt.Prompt
		local seat: Seat = v.Chair.Seat.Seat

		local prevPlayer = nil
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local newOccupant = seat.Occupant
			if not newOccupant then
				if prevPlayer then
					removeGameUI(Game, { prevPlayer })
					ReplicatedStorage.Events.Question:FireClient(prevPlayer.player, nil)
					prevPlayer.spot.QA:ClearAllChildren()
					for index, plr in ipairs(Game.players) do
						if plr.player.Name ~= prevPlayer.player.Name then
							continue
						end

						if not Game.inSession then
							table.remove(Game.players, index)
						else
							Game.players[index].health = 0
						end
					end
					Game.alivePlayer -= 1
					prevPlayer = nil
				end
				prompt.Enabled = true
			else
				prevPlayer = Game:addPlayer({ player = Players:GetPlayerFromCharacter(newOccupant.Parent), spot = v })
				Game.alivePlayer += 1

				prompt.Enabled = false
			end
		end)

		prompt.Triggered:Connect(function(player)
			local character = player.Character
			if not character or not character:FindFirstChild("Humanoid") then
				return
			end

			local humanoid = character.Humanoid
			seat:Sit(humanoid)
		end)
		Game.spotAmount += 1
	end

	local function updatePlayersHealth(player, playerIsCorrect, damage, heal)
		for _, opponent in ipairs(Game.players) do
			if opponent == player or not isPlayerAlive(opponent) then
				continue
			end

			if playerIsCorrect then
				opponent.health = math.clamp(opponent.health - damage, 0, 100)
			else
				if not isPlayerAlive(opponent) then
					continue
				end
				opponent.health = math.clamp(opponent.health + heal, 0, 100)
			end
		end
	end

	local function handlePlayerAnswer(player, questionData)
		local correctAnswer = questionData.options[questionData.answerIdx]
		local playerIsCorrect = nil
		local connection = nil
		connection = ReplicatedStorage.Events.Question.OnServerEvent:Connect(function(sender, card, playerAnswer)
			if sender.UserId ~= player.player.UserId then
				return
			end

			ReplicatedStorage.Events.Question:FireClient(player.player, correctAnswer, card)
			playerIsCorrect = playerAnswer == correctAnswer
			connection:Disconnect()
		end)

		repeat
			task.wait()
		until not connection.Connected
			or Game.alivePlayer <= (Game.spotAmount > 1 and 1 or 0)
			or not isPlayerAlive(player)
		if playerIsCorrect ~= nil then
			if not playerIsCorrect then
				player.health = math.clamp(player.health - questionData.selfDamage, 0, 100)
			else
				player.health = math.clamp(player.health + questionData.heal * 0.85, 0, 100)
				player.score += questionData.score
			end
			updatePlayersHealth(player, playerIsCorrect, questionData.damage, questionData.heal)
			print(#Game.players, Game.alivePlayer)
		end

		if connection.Connected then
			connection:Disconnect()
		end
		return playerIsCorrect
	end

	local function quiz(player, Table, questionHistory)
		local questionData = questionModule.randQuestion(questionHistory)

		if #questionHistory > 3 then
			table.remove(questionHistory, 1)
		end
		table.insert(questionHistory, questionData.question)

		spawnQA(Table)
		task.wait(0.5)

		sendQA(player.player, Table, questionData)

		local playerIsCorrect = handlePlayerAnswer(player, questionData)
		return questionHistory, playerIsCorrect
	end

	local function runGameSession()
		for _, player in ipairs(Game.players) do
			local character = player.player.Character
			if not character or not character:FindFirstChild("Humanoid") then
				continue
			end

			character.Humanoid.JumpHeight = 0
			ReplicatedStorage.Events.Players:FireClient(player.player, "initPlayers", Game.players)

			task.spawn(function()
				while Game.alivePlayer > (Game.spotAmount > 1 and 1 or 0) and isPlayerAlive(player) do
					local questionHistory, _ = quiz(player, player.spot, player.questionHistory)
					player.questionHistory = questionHistory
					updateGameUI(Game)

					task.wait(1)
				end

				character.Humanoid.Jump = true
				character.Humanoid.JumpHeight = 7.2
			end)
		end
	end

	-- Initialize all tables and player prompts
	for _, v in pairs(this:GetChildren()) do
		if v.Name == "Spot" then
			initPlayerPrompt(v, Game)
		end
	end

	while true do
		task.wait()

		local success, response = pcall(function()
			-- Check if game should start
			if #Game.players < Game.spotAmount or Game.inSession then
				return
			end
			Game.inSession = true
			runGameSession()

			repeat
				task.wait(1)
			until Game.alivePlayer <= (Game.spotAmount > 1 and 1 or 0)

			local lastStanding = nil
			local names = {}
			local highestScore
			for _, player in ipairs(Game.players) do
				table.insert(names, player.player.Name)
				if isPlayerAlive(player) then
					lastStanding = player
				end

				if highestScore == nil or player.score > highestScore.score then
					highestScore = player
				end
			end

			if Game.spotAmount > 1 then
				if lastStanding == highestScore then
					sendSystemMessage(
						string.format(
							"[SYSTEM] %s adalah pemain terakhir yang bertahan mengalahkan %s pemain lain dengan skor tertinggi %s.",
							lastStanding.player.Name,
							Game.spotAmount - 1,
							table.concat(names, ", "),
							lastStanding.score
						)
					)
				else
					table.remove(names, table.find(names, lastStanding.player.Name))
					sendSystemMessage(
						string.format(
							"[SYSTEM] %s adalah permain terakhir yang bertahan mengalahkan %s pemain lain dengan skor %s. Skor tertinggi dipegang oleh %s sebesar %s",
							lastStanding.player.Name,
							Game.spotAmount - 1,
							lastStanding.score,
							highestScore.player.Name,
							highestScore.score
						)
					)
				end

				for _, player in ipairs(Game.players) do
					if player == lastStanding or player == highestScore then
						continue
					end

					ReplicatedStorage.Events.System:FireClient(
						player.player,
						string.format("[SYSTEM] Skor mu: %s", player.score)
					)
				end
			else
				sendSystemMessage(
					string.format(
						"[SYSTEM] %s telah menyelesaikan sesi solonya dengan skor %s",
						Game.players[1].player.Name,
						Game.players[1].score
					)
				)
			end

			Game.inSession = false
			removeGameUI(Game, Game.players)
			table.clear(Game.players)
		end)

		if not success then
			print(response)
		end
	end
end

-- Initialize game for each table model
for _, tableModel in pairs(workspace.Tables:GetChildren()) do
	task.spawn(function()
		initGame(tableModel)
	end)
end
