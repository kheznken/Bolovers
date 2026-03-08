if not game:IsLoaded() then game.Loaded:Wait() end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local roomFolder = nil
local preCloudPos = nil
local autoHideReturnPos = nil
local customSpeed = 16
local customJump = 50
local hitboxSize = 15
local tpTool = nil
local glideTool = nil
local savedLocation = nil
local playerPositions = {}
local xrayParts = {}
local targetPlayerName = ""
local fpsStoredMaterials = {}
local persistentTarget = nil
local targetOrigPos = nil
local spinAngle = 0

local origLight = {
	Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient
}

local toggles = {
	speed=false, jumpHigh=false, frozeAll=false, bringAll=false, bringNearby=false,
	hide=false, esp=false, hitbox=false, noclip=false, xray=false, infjump=false,
	autoHide=false, freezeAura=false, antiAfk=false, tptool=false, glidetool=false,
	fullbright=false, spinbot=false, instantInteract=false, bringTarget=false,
	freezeTarget=false, antifling=false, antisit=false, antistun=false,
	untouchable=false, fpsBoost=false, spectate=false, instantRespawn=false
}

local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(c) return c and c:FindFirstChild("Humanoid") end
local function GetPlayer(s)
	if not s or s == "" then return nil end
	s = s:lower()
	for _, v in pairs(Players:GetPlayers()) do
		if v.Name:lower():sub(1,#s) == s or v.DisplayName:lower():sub(1,#s) == s then return v end
	end
end

local function spawnRoom()
	if roomFolder then return roomFolder:GetAttribute("CenterCF") end
	roomFolder = Instance.new("Folder", workspace)
	roomFolder.Name = "Boloversal_Room"
	local cf = CFrame.new(math.random(-90000,90000), 40000, math.random(-90000,90000))
	roomFolder:SetAttribute("CenterCF", cf)
	local function qp(sz, pos, col, mat)
		local p = Instance.new("Part", roomFolder)
		p.Size=sz; p.CFrame=cf*pos; p.Anchored=true; p.Color=col
		p.Material = mat or Enum.Material.Plastic; return p
	end
	qp(Vector3.new(80,1,80), CFrame.new(0,0,0), Color3.fromRGB(255,255,255), Enum.Material.SmoothPlastic)
	qp(Vector3.new(80,25,1), CFrame.new(0,12.5,-40), Color3.fromRGB(240,240,240))
	local g = qp(Vector3.new(0.5,13,40), CFrame.new(40,12.5,0), Color3.fromRGB(180,225,255), Enum.Material.Glass)
	g.Transparency = 0.4
	return cf
end

local function ServerHop(sort)
	local ok, res = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(
			"https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder="..sort.."&limit=100"
		))
	end)
	if not ok then return end
	for _, v in pairs(res.data) do
		if v.playing < v.maxPlayers and v.id ~= game.JobId then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id); break
		end
	end
end

local function createGlideTool()
	local tool = Instance.new("Tool"); tool.Name="Glide Tool"; tool.RequiresHandle=true
	local handle = Instance.new("Part", tool); handle.Name="Handle"; handle.Size=Vector3.new(2,2,1); handle.CanCollide=false
	local mesh = Instance.new("SpecialMesh", handle)
	mesh.MeshId="rbxassetid://68203112"; mesh.TextureId="rbxassetid://68203091"; mesh.Scale=Vector3.new(1.5,1.5,1.5)
	local a0 = Instance.new("Attachment", handle); a0.Position=Vector3.new(0,0.5,0)
	local a1 = Instance.new("Attachment", handle); a1.Position=Vector3.new(0,-0.5,0)
	local tr = Instance.new("Trail", handle); tr.Attachment0=a0; tr.Attachment1=a1
	tr.Color=ColorSequence.new(Color3.new(0,1,1)); tr.Enabled=false
	local gliding = false
	tool.Activated:Connect(function()
		if gliding then return end
		local hrp = getHRP(player.Character); if not hrp then return end
		gliding=true; tr.Enabled=true
		local target = mouse.Hit.Position
		local nc = RunService.Stepped:Connect(function()
			if player.Character then for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end end
		end)
		local bv = Instance.new("BodyVelocity", hrp); bv.MaxForce=Vector3.new(1e6,1e6,1e6); bv.Velocity=(target-hrp.Position).Unit*120
		local bg = Instance.new("BodyGyro", hrp); bg.MaxTorque=Vector3.new(1e6,1e6,1e6); bg.CFrame=CFrame.new(hrp.Position, target)
		task.wait((target-hrp.Position).Magnitude/120)
		nc:Disconnect(); bv:Destroy(); bg:Destroy(); tr.Enabled=false; gliding=false
		if player.Character then for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=true end end end
	end)
	return tool
end

-- ══════════════════════════════════════
-- WINDOW
-- ══════════════════════════════════════
local Window = Rayfield:CreateWindow({
	Name = "Boloversal Hub",
	LoadingTitle = "Boloversal Hub",
	LoadingSubtitle = "by @khezn21",
	ConfigurationSaving = { Enabled = false },
	Discord = { Enabled = false },
	KeySystem = false
})

-- ══════════════════════════════════════
-- TABS
-- ══════════════════════════════════════
local MainTab     = Window:CreateTab("Main",     "zap")
local CombatTab   = Window:CreateTab("Combat",   "sword")
local TargetTab   = Window:CreateTab("Target",   "crosshair")
local VisualsTab  = Window:CreateTab("Visuals",  "eye")
local ItemTab     = Window:CreateTab("Items",    "package")
local UtilityTab  = Window:CreateTab("Utility",  "wrench")
local SettingsTab = Window:CreateTab("Settings", "settings")

-- ══════════════════════════════════════
-- MAIN
-- ══════════════════════════════════════
MainTab:CreateSection("Movement")
MainTab:CreateSlider({
	Name = "Walkspeed",
	Range = {16, 500}, Increment = 1, Suffix = "ws", CurrentValue = 16,
	Callback = function(V) customSpeed = V end
})
MainTab:CreateToggle({
	Name = "Enable Walkspeed", CurrentValue = false,
	Callback = function(V) toggles.speed = V end
})
MainTab:CreateSlider({
	Name = "Jump Power",
	Range = {50, 500}, Increment = 1, Suffix = "jp", CurrentValue = 50,
	Callback = function(V) customJump = V end
})
MainTab:CreateToggle({
	Name = "Enable Jump Power", CurrentValue = false,
	Callback = function(V)
		toggles.jumpHigh = V
		if not V then local h = getHum(player.Character) if h then h.JumpPower = 50 end end
	end
})
MainTab:CreateToggle({
	Name = "Infinite Jump", CurrentValue = false,
	Callback = function(V) toggles.infjump = V end
})
MainTab:CreateToggle({
	Name = "Noclip", CurrentValue = false,
	Callback = function(V)
		toggles.noclip = V
		if not V and player.Character then
			for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=true end end
		end
	end
})
MainTab:CreateToggle({
	Name = "Spinbot", CurrentValue = false,
	Callback = function(V) toggles.spinbot = V end
})
MainTab:CreateSection("Player")
MainTab:CreateToggle({
	Name = "God Mode", CurrentValue = false,
	Callback = function(V) toggles.untouchable = V end
})
MainTab:CreateToggle({
	Name = "FPS Booster", CurrentValue = false,
	Callback = function(V)
		toggles.fpsBoost = V
		if V then
			for _,v in pairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") then fpsStoredMaterials[v]=v.Material; v.Material=Enum.Material.SmoothPlastic end
			end
		else
			for p,m in pairs(fpsStoredMaterials) do if p and p.Parent then p.Material=m end end
			fpsStoredMaterials = {}
		end
	end
})
MainTab:CreateToggle({
	Name = "Instant Respawn", CurrentValue = false,
	Callback = function(V) toggles.instantRespawn = V end
})

-- ══════════════════════════════════════
-- COMBAT
-- ══════════════════════════════════════
CombatTab:CreateSection("Hitbox")
CombatTab:CreateToggle({
	Name = "Hitbox Expander", CurrentValue = false,
	Callback = function(V) toggles.hitbox = V end
})
CombatTab:CreateSlider({
	Name = "Hitbox Size",
	Range = {2, 100}, Increment = 1, CurrentValue = 15,
	Callback = function(V) hitboxSize = V end
})
CombatTab:CreateSection("Players")
CombatTab:CreateToggle({
	Name = "Freeze All", CurrentValue = false,
	Callback = function(V) toggles.frozeAll = V end
})
CombatTab:CreateToggle({
	Name = "Freeze Aura (35 studs)", CurrentValue = false,
	Callback = function(V) toggles.freezeAura = V end
})
CombatTab:CreateToggle({
	Name = "Bring All", CurrentValue = false,
	Callback = function(V) toggles.bringAll = V end
})
CombatTab:CreateToggle({
	Name = "Bring Nearby (70 studs)", CurrentValue = false,
	Callback = function(V) toggles.bringNearby = V end
})

-- ══════════════════════════════════════
-- TARGET
-- ══════════════════════════════════════
TargetTab:CreateSection("Target")
TargetTab:CreateInput({
	Name = "Player Name", PlaceholderText = "Enter username...", RemoveTextAfterFocusLost = false,
	Callback = function(T) targetPlayerName = T end
})
TargetTab:CreateToggle({
	Name = "Spectate", CurrentValue = false,
	Callback = function(V)
		toggles.spectate = V
		if V then
			task.spawn(function()
				while toggles.spectate do
					local t = GetPlayer(targetPlayerName)
					if t and t.Character and getHum(t.Character) then
						workspace.CurrentCamera.CameraSubject = t.Character.Humanoid
					elseif player.Character then
						workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid")
					end
					task.wait(0.1)
				end
			end)
		elseif player.Character then
			workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid")
		end
	end
})
TargetTab:CreateToggle({
	Name = "Bring Target", CurrentValue = false,
	Callback = function(V)
		toggles.bringTarget = V
		if V then
			local t = GetPlayer(targetPlayerName)
			if t and t.Character and getHRP(t.Character) then
				persistentTarget = t; targetOrigPos = getHRP(t.Character).CFrame
			end
		else
			if persistentTarget and persistentTarget.Character and getHRP(persistentTarget.Character) and targetOrigPos then
				getHRP(persistentTarget.Character).CFrame = targetOrigPos
			end
			persistentTarget = nil; targetOrigPos = nil
		end
	end
})
TargetTab:CreateToggle({
	Name = "Freeze Target", CurrentValue = false,
	Callback = function(V)
		toggles.freezeTarget = V
		local t = GetPlayer(targetPlayerName)
		if t and t.Character and getHRP(t.Character) then getHRP(t.Character).Anchored = V end
	end
})

-- ══════════════════════════════════════
-- VISUALS
-- ══════════════════════════════════════
VisualsTab:CreateSection("Visuals")
VisualsTab:CreateToggle({
	Name = "ESP", CurrentValue = false,
	Callback = function(V) toggles.esp = V end
})
VisualsTab:CreateToggle({
	Name = "Xray Vision", CurrentValue = false,
	Callback = function(V)
		toggles.xray = V
		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and not v:IsDescendantOf(player.Character) then
				if V then
					if not xrayParts[v] then xrayParts[v] = v.Transparency end
					v.Transparency = 0.6
				else
					if xrayParts[v] ~= nil then v.Transparency = xrayParts[v]; xrayParts[v] = nil end
				end
			end
		end
	end
})
VisualsTab:CreateToggle({
	Name = "Fullbright", CurrentValue = false,
	Callback = function(V)
		if V then
			Lighting.Brightness=2; Lighting.ClockTime=12
			Lighting.GlobalShadows=false; Lighting.Ambient=Color3.new(1,1,1)
		else
			Lighting.Brightness=origLight.Brightness; Lighting.ClockTime=origLight.ClockTime
			Lighting.GlobalShadows=origLight.GlobalShadows; Lighting.Ambient=origLight.Ambient
		end
	end
})

-- ══════════════════════════════════════
-- ITEMS
-- ══════════════════════════════════════
ItemTab:CreateSection("Tools")
ItemTab:CreateToggle({
	Name = "TP Tool", CurrentValue = false,
	Callback = function(V)
		toggles.tptool = V
		if V then
			tpTool = Instance.new("Tool"); tpTool.Name="Click TP"; tpTool.RequiresHandle=false
			tpTool.Parent = player.Backpack
			tpTool.Activated:Connect(function()
				local hrp = getHRP(player.Character)
				if hrp then hrp.CFrame = mouse.Hit * CFrame.new(0,3,0) end
			end)
		else
			if tpTool then tpTool:Destroy(); tpTool=nil end
		end
	end
})
ItemTab:CreateToggle({
	Name = "Glide Tool", CurrentValue = false,
	Callback = function(V)
		toggles.glidetool = V
		if V then glideTool = createGlideTool(); glideTool.Parent = player.Backpack
		else if glideTool then glideTool:Destroy(); glideTool=nil end end
	end
})

-- ══════════════════════════════════════
-- UTILITY
-- ══════════════════════════════════════
UtilityTab:CreateSection("Hiding")
UtilityTab:CreateToggle({
	Name = "Hide Room", CurrentValue = false,
	Callback = function(V)
		toggles.hide = V
		local hrp = getHRP(player.Character); if not hrp then return end
		if V then
			preCloudPos = hrp.CFrame; hrp.CFrame = spawnRoom() * CFrame.new(0,5,0)
		else
			if roomFolder then roomFolder:Destroy(); roomFolder=nil end
			if preCloudPos then hrp.CFrame = preCloudPos end
		end
	end
})
UtilityTab:CreateToggle({
	Name = "Auto Hide (< 30% HP)", CurrentValue = false,
	Callback = function(V) toggles.autoHide = V end
})
UtilityTab:CreateSection("Teleport")
UtilityTab:CreateToggle({
	Name = "Instant Interact", CurrentValue = false,
	Callback = function(V) toggles.instantInteract = V end
})
UtilityTab:CreateButton({
	Name = "Save Position",
	Callback = function()
		local hrp = getHRP(player.Character); if hrp then savedLocation = hrp.CFrame end
	end
})
UtilityTab:CreateButton({
	Name = "Teleport to Saved",
	Callback = function()
		if savedLocation then local hrp = getHRP(player.Character); if hrp then hrp.CFrame = savedLocation end end
	end
})

-- ══════════════════════════════════════
-- SETTINGS
-- ══════════════════════════════════════
SettingsTab:CreateSection("Anti")
SettingsTab:CreateToggle({
	Name = "Anti AFK", CurrentValue = false,
	Callback = function(V) toggles.antiAfk = V end
})
SettingsTab:CreateToggle({
	Name = "Anti Fling", CurrentValue = false,
	Callback = function(V) toggles.antifling = V end
})
SettingsTab:CreateToggle({
	Name = "Anti Sit", CurrentValue = false,
	Callback = function(V) toggles.antisit = V end
})
SettingsTab:CreateToggle({
	Name = "Anti Stun", CurrentValue = false,
	Callback = function(V) toggles.antistun = V end
})
SettingsTab:CreateSection("Servers")
SettingsTab:CreateButton({
	Name = "Smallest Server",
	Callback = function() ServerHop("Asc") end
})
SettingsTab:CreateButton({
	Name = "Biggest Server",
	Callback = function() ServerHop("Desc") end
})
SettingsTab:CreateButton({
	Name = "Rejoin",
	Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end
})

-- ══════════════════════════════════════
-- CORE LOOP
-- ══════════════════════════════════════
RunService.Heartbeat:Connect(function()
	local char = player.Character; if not char then return end
	local hrp, hum = getHRP(char), getHum(char); if not hrp or not hum then return end

	if toggles.speed and hum.MoveDirection.Magnitude > 0 then
		hrp.Velocity = Vector3.new(hum.MoveDirection.X*customSpeed, hrp.Velocity.Y, hum.MoveDirection.Z*customSpeed)
	end
	if toggles.jumpHigh then hum.JumpPower = customJump end
	if toggles.spinbot then
		spinAngle = (spinAngle + 4) % 360
		hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
	end
	if toggles.antisit then hum.Sit = false end
	if toggles.antistun then hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end
	if toggles.antifling then hrp.RotVelocity = Vector3.new(0,0,0) end
	if toggles.untouchable then
		for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanTouch=false end end
	else
		for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanTouch=true end end
	end
	if toggles.bringTarget and persistentTarget and persistentTarget.Character then
		local th = getHRP(persistentTarget.Character); if th then th.CFrame = hrp.CFrame * CFrame.new(0,0,-3) end
	end
	if toggles.autoHide then
		local hp = (hum.Health / math.max(hum.MaxHealth,1)) * 100
		if hp < 30 and not toggles.hide then
			autoHideReturnPos = hrp.CFrame; hrp.CFrame = spawnRoom() * CFrame.new(0,5,0); toggles.hide = true
		elseif hp >= 50 and toggles.hide and autoHideReturnPos then
			hrp.CFrame = autoHideReturnPos; autoHideReturnPos = nil; toggles.hide = false
			if roomFolder then roomFolder:Destroy(); roomFolder = nil end
		end
	end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local ph = getHRP(p.Character)
			if ph then
				local dist = (ph.Position - hrp.Position).Magnitude
				local bring = toggles.bringAll or (toggles.bringNearby and dist < 70)
				local freeze = toggles.frozeAll or (toggles.freezeAura and dist < 35)
				if bring or freeze then
					if not playerPositions[p.UserId] then playerPositions[p.UserId] = ph.CFrame end
					ph.Anchored = true
					if bring then ph.CFrame = hrp.CFrame * CFrame.new(0,0,-5) end
				else
					if playerPositions[p.UserId] then
						ph.Anchored = false; ph.CFrame = playerPositions[p.UserId]; playerPositions[p.UserId] = nil
					end
				end
				if toggles.hitbox then ph.Size=Vector3.new(hitboxSize,hitboxSize,hitboxSize); ph.Transparency=0.6
				else ph.Size=Vector3.new(2,2,1); ph.Transparency=0 end
				if toggles.esp then
					local h = p.Character:FindFirstChild("T_ESP")
					if not h then h = Instance.new("Highlight", p.Character); h.Name="T_ESP" end
					h.Enabled = true
				elseif p.Character:FindFirstChild("T_ESP") then
					p.Character.T_ESP.Enabled = false
				end
			end
		end
	end
end)

player.CharacterAdded:Connect(function(char)
	if toggles.instantRespawn then
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then hum.Died:Connect(function() task.wait(0.05); player:LoadCharacter() end) end
	end
end)

RunService.Stepped:Connect(function()
	if toggles.noclip and player.Character then
		for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end
	end
end)

player.Idled:Connect(function()
	if toggles.antiAfk then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

UserInputService.JumpRequest:Connect(function()
	if toggles.infjump then local h = getHum(player.Character) if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	if toggles.instantInteract then pcall(function() fireproximityprompt(prompt) end) end
end)
