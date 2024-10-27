local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextChatService")

local SystemChannel = TextService:FindFirstChild("RBXSystem", true)

ReplicatedStorage.Events.System.OnClientEvent:Connect(function(...: any)
	local args = {...}
	if type(args[1]) ~= "string" then return end

	SystemChannel:DisplaySystemMessage(args[1])
end)