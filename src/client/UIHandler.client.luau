local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local client = Players.LocalPlayer

ReplicatedStorage.Events.Players.OnClientEvent:Connect(function(...: any)
	local args = {...}

	if args[1] == "initPlayers" then
		local playerDatas = args[2]
		for _, playerData in playerDatas do
			local ui = ReplicatedStorage.UI.player:Clone()
			ui.Name = playerData.player.Name
			ui.name.Text = playerData.player.Name
			ui.avatar.Image = Players:GetUserThumbnailAsync(playerData.player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
			ui.Parent = client.PlayerGui.Game.container

			if playerData.player ~= client then
				ui.health.bar.BackgroundColor3 = Color3.fromRGB(210, 66, 53)
			end
		end
	elseif args[1] == "updatePlayer" then
		local playerDatas = args[2]
		for _, playerData in playerDatas do
			local ui = client.PlayerGui.Game.container:FindFirstChild(playerData.player.Name)
			if not ui then continue end
			ui:SetAttribute("score", playerData.score)
			ui:SetAttribute("health", playerData.health)
		end
	elseif args[1] == "end" then
		local playerDatas = args[2]
		for _, playerData in playerDatas do
			local ui = client.PlayerGui.Game.container:FindFirstChild(playerData.player.Name)
			if not ui then continue end
			ui:Destroy()
		end
	end
end)