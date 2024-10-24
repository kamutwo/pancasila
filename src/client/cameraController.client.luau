local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local camera = workspace.CurrentCamera
local client = Players.LocalPlayer

local TransparencyModule = require(client.PlayerScripts:WaitForChild("PlayerModule").CameraModule.TransparencyController)
local controller = TransparencyModule.new()

local currentAngle = Vector2.new(0, 0)
local fpsMode = false

local function updateMouseBehavior()
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		client.PlayerGui.Cursor.Enabled = false
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		client.PlayerGui.Cursor.Enabled = true
	end
end

local function clampMnx(n: number, mnx: number)
	return math.clamp(n, -math.rad(mnx), math.rad(mnx))
end

local function setTransparency(transparency: number, exceptTransparency: number?, ...: BasePart)
	local except = {...}
	exceptTransparency = exceptTransparency or 0

	for i, _ in pairs(controller.cachedParts) do
		if table.find(except, i) then
			i.LocalTransparencyModifier = exceptTransparency
			continue
		end
		i.LocalTransparencyModifier = transparency
	end
end

function Render(character: Model)
	local hum: Humanoid = character:FindFirstChild("Humanoid")
	if not hum then return end

	updateMouseBehavior()
	camera.CameraSubject = hum
	camera.CameraType = Enum.CameraType.Scriptable

	local delta = UserInputService:GetMouseDelta()
	currentAngle -= (delta / camera.ViewportSize) * 4
	currentAngle = Vector2.new(currentAngle.X, clampMnx(currentAngle.Y, 75))

	local goal
	if fpsMode then
		local head = character:FindFirstChild("Head")
		goal = CFrame.new(head.Position) * CFrame.fromOrientation(currentAngle.Y, currentAngle.X, 0)
		setTransparency(1)
	else
		local hrp = character:FindFirstChild("HumanoidRootPart")
		goal = (CFrame.new(hrp.Position) + hrp.CFrame.LookVector * -5 + Vector3.new(0, 3, 0)) 
			* CFrame.fromOrientation(currentAngle.Y, currentAngle.X, 0)
		setTransparency(0)
	end
	camera.CFrame = camera.CFrame:Lerp(goal, 0.2)
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then return end

	if input.KeyCode == Enum.KeyCode.R then
		fpsMode = not fpsMode
	end
end)

local runConnection = nil
client.CharacterAdded:Connect(function(character)
	controller:SetupTransparency(character)
	runConnection = RunService.RenderStepped:Connect(function()
		Render(character)
	end)
end)

client.CharacterRemoving:Connect(function(character)
	runConnection:Disconnect()
end)