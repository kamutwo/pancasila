local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local client = Players.LocalPlayer

RunService.RenderStepped:Connect(function()
	if not client.character or not client.Character:FindFirstChild("Head") then return end

	if UserInputService.MouseEnabled then
		if client.character.Head.LocalTransparencyModifier >= 8 then
			UserInputService.MouseIconEnabled = false
			client.PlayerGui.Cursor.Enabled = true
		else
			UserInputService.MouseIconEnabled = true
			client.PlayerGui.Cursor.Enabled = false
		end
	end
end)