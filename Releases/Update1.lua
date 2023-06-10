local Global = (getgenv and getgenv()) or getfenv(0)
local ReanimSettings = Global.ReanimateSettings;
if not ReanimSettings then ReanimSettings = {}; Global.ReanimateSettings = ReanimSettings end

-- some settings into vars so will not break when changing while reanimated
local ExtraOptimization = ReanimSettings.ExtraOptimization or false
local AntiSleepParts = ReanimSettings.AntiSleep or false
local AntiVoid = ReanimSettings.AntiVoid or false

local isnetworkowner, sethiddenproperty, setsimulationradius
local CF = CFrame.new
local CA = CFrame.Angles
local V3 = Vector3.new
local IN = Instance.new
local TI = table.insert
local SUB = string.sub

local fspawn = task.spawn
local fdelay = task.delay
local fwait = task.wait

local V3_010 = V3(0,1,0)
local AntiSleep = CF()

local Events = {}
local Hats = {}
local Offsets = {}

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local function notification(Title, Text)
	StarterGui:SetCore("SendNotification", {
		Title = Title or "",
		Text = Text or "",
		Duration = 5
	})
end

local Stepped = RunService[ReanimSettings.NewRunServiceEvents and "PreSimulation" or "Stepped"]
local Heartbeat = RunService[ReanimSettings.NewRunServiceEvents and "PostSimulation" or "Heartbeat"]

local Camera = Workspace.CurrentCamera
local Client = Players.LocalPlayer
local Character, Humanoid = Client.Character, nil

do -- [[ Checks ]] --
	if not game:IsLoaded("Workspace") then
		notification("Game Not Loaded", "Game is still loading.")
		game.Loaded:Wait()
	end
	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if (not Character) or (Character and Character.Name == "𝔾𝕖𝕝𝕒𝕥𝕖𝕜ℝ𝕒𝕨"..tostring(game.PlaceId)) then
		notification("Error", "No Real Character found, or you are already reanimated")
		return
	end

	if (Humanoid.Health == 0) or (Humanoid.BreakJointsOnDeath == false) then 
		notification("Error", "Something is up with humanoid properties, or the game has patches.")
		return
	end
end


do -- [[ Functions / Data ]] --
	isnetworkowner = isnetworkowner or function(Part)
		return Part.ReceiveAge == 0
	end
	sethiddenproperty = sethiddenproperty or function(Instance, Property, Value)
		pcall(function() 
			Instance[Property] = Value
		end)
	end
	setsimulationradius = setsimulationradius or function(Value)
		sethiddenproperty(Client, "SimulationRadius", Value)
	end

	Global.ReanimateData = {
		ScriptStopped = false,
		FlingEnabled = false,
		FlingPart = nil,
		Connections = {},
		HatCache = Instance.new("Folder")
	}
end

local FlingPart = nil
local ReadyToAlign = false
local NoclipStatus = false
local WaitTime = Players.RespawnTime + 0.65
local FallenPartsDestroyHeight = Workspace.FallenPartsDestroyHeight
local CharDescendants = Character:GetDescendants()
local RootPart = Character:WaitForChild("HumanoidRootPart", 15)
local CFrameOffset = CF(RootPart.Position.X, FallenPartsDestroyHeight + 375, RootPart.Position.Z)
local SavedCFrame = RootPart.CFrame * CF(0, 10, 0)
local FakeRig, FakeHumanoid, FakeRoot, FakeRigDescendants;

if ReanimSettings.KeepCharacter and ReanimSettings.ToolFling then
	notification("Tip", "Try to reanimate near the void, then once you claim your hats knock the bodyparts to void to increase stability!")
end

if ReanimSettings.ToolFling then -- [[ Tool Flinging ]] --
	local Backpack = Client:FindFirstChildOfClass("Backpack")
	local Tool = Backpack:FindFirstChildOfClass("Tool")
	if Tool then
		Tool.Parent = Character
		Character:WaitForChild(Tool.Name)
		FlingPart = Tool:WaitForChild("Handle", 10)
		FlingPart.Transparency = 0.25

		local Highlight = IN("Highlight")
		Highlight.Adornee = FlingPart
		Highlight.FillTransparency = 0.1
		Highlight.FillColor = Color3.fromRGB(52, 235, 195)
		Global.ReanimateData.FlingPart = FlingPart

		fdelay(WaitTime+1, function()
			FlingPart.Massless = true
			Highlight.Parent = FlingPart
		end)
	else
		notification("Warning", "Player has no tools in Backpack, tool fling will be not enabled.")
	end
end

do -- [[ Improve Claiming / Disabling Things / Extra Settings. ]] --
	local SpawnPoint = Workspace:FindFirstChildOfClass("SpawnLocation",true) and Workspace:FindFirstChildOfClass("SpawnLocation",true) or CF(0,20,0)
	local Physics = settings()['Physics']
	local Rendering = settings()['Rendering']
	local WakeOffset = 0.008
	local Cos = math.cos

	for _, Instance in pairs(CharDescendants) do
		if Instance:IsA("Script") or Instance:IsA("LocalScript") then
			Instance.Disabled = true
		elseif Instance:IsA("BasePart") then
			Instance.RootPriority = 127
			Instance.Massless = Instance.Parent:IsA("Accessory") and true or false
			Instance.CastShadow = not ExtraOptimization
		elseif Instance:IsA("Accessory") then
			local Handle = Instance:FindFirstChild("Handle")
			if Handle then TI(Hats, Handle) end
		end
	end

	for _, Track in pairs(Humanoid:GetPlayingAnimationTracks()) do
		Track:Stop()
	end

	Workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Disabled
	Workspace.Retargeting = "Disabled"
	Client.ReplicationFocus = Workspace

	sethiddenproperty(Client, "MaximumSimulationRadius", 2763000)
	sethiddenproperty(Client, "SimulationRadius", 2763000)
	sethiddenproperty(Humanoid, "InternalBodyScale", V3(9e9,9e9,9e9))
	sethiddenproperty(Workspace, "SignalBehavior", "Immediate")
	sethiddenproperty(Workspace, "StreamingMinRadius", 1/0)
	sethiddenproperty(Workspace, "StreamingEnabled", true)
	sethiddenproperty(Workspace, "StreamOutBehavior", Enum.StreamOutBehavior.Opportunistic)

	pcall(function()	
		Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
		Physics.AllowSleep = false
		Physics.ThrottleAdjustTime = math.huge
		Rendering.EagerBulkExecution = ReanimSettings.EagerBulkExecution
		if ExtraOptimization then Rendering.QualityLevel = 2 end
	end)

	TI(Events, Stepped:Connect(function()
		setsimulationradius(2763000)
		if AntiSleepParts then
			WakeOffset = 0.008 * Cos(tick()*10)
			AntiSleep = CA(WakeOffset, 0, WakeOffset)
		end

		if (FakeRoot and FakeHumanoid) and FakeHumanoid.MoveDirection.Magnitude < 0.1 then 
			FakeRoot.CFrame = FakeRoot.CFrame * CF(0.004 * Cos(tick()*8), 0, 0)
		end

		if (FakeRoot and FakeRoot.Position.Y <= FallenPartsDestroyHeight + 60) then
			if AntiVoid then
				FakeRig:MoveTo(SpawnPoint.Position)
				FakeRoot.Velocity = V3(0, 0, 0)
			else
				FakeRoot.Anchored = true
				FakeHumanoid:ChangeState(15)
			end
		end

		if FlingPart then
			FlingPart.CanCollide = false
			FlingPart.CanTouch = false
			FlingPart.CanQuery = false
		end
	end))
end

do -- [[ Rig ]] --
	FakeRig = IN("Model")
	local Limbs = {}
	local Attachments = {}
	local function CreateJoint(Name,Part0,Part1,C0,C1)
		local Joint = IN("Motor6D")
		Joint.Name = Name
		Joint.Part0 = Part0
		Joint.Part1 = Part1
		Joint.C0 = C0
		Joint.C1 = C1
		Joint.Parent = Part0
	end

	for i = 0,18 do
		local Attachment = IN("Attachment")
		Attachment.Axis = V3(1,0,0)
		Attachment.SecondaryAxis = V3(0,1,0)
		TI(Attachments, Attachment)
	end

	for i = 0,3 do
		local Limb = IN("Part")
		Limb.Size = V3(1, 2, 1)
		Limb.Transparency = 1
		Limb.BottomSurface = Enum.SurfaceType.Smooth
		Limb.FormFactor = Enum.FormFactor.Symmetric
		Limb.Locked = true
		Limb.CanCollide = false
		Limb.CastShadow = not ExtraOptimization
		Limb.Parent = FakeRig
		TI(Limbs, Limb)
	end

	Limbs[1].Name = "Right Arm"
	Limbs[2].Name = "Left Arm"
	Limbs[3].Name = "Right Leg"
	Limbs[4].Name = "Left Leg"

	local Head = IN("Part"); do
		Head.Size = V3(2,1,1)
		Head.TopSurface = Enum.SurfaceType.Smooth
		Head.FormFactor = Enum.FormFactor.Symmetric
		Head.Locked = true
		Head.CanCollide = false
		Head.CastShadow = not ExtraOptimization
		Head.Transparency = 1
		Head.Name = "Head"
		Head.Parent = FakeRig
	end
	local Torso = IN("Part"); do
		Torso.Size = V3(2, 2, 1)
		Torso.BottomSurface = Enum.SurfaceType.Smooth
		Torso.FormFactor = Enum.FormFactor.Symmetric
		Torso.Locked = true
		Torso.CanCollide = false
		Torso.Transparency = 1
		Torso.Name = "Torso"
		Torso.CastShadow = not ExtraOptimization
		Torso.Parent = FakeRig
	end
	FakeRoot = Torso:Clone(); do
		FakeRoot.Transparency = 1
		FakeRoot.Name = "HumanoidRootPart"
		FakeRoot.CanCollide = false
		FakeRoot.CastShadow = not ExtraOptimization
		FakeRoot.Parent = FakeRig
	end

	CreateJoint("Neck", Torso, Head, CF(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0), CF(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
	CreateJoint("RootJoint", FakeRoot, Torso, CF(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0), CF(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
	CreateJoint("Right Shoulder", Torso, Limbs[1], CF(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0), CF(-0.5, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
	CreateJoint("Left Shoulder", Torso, Limbs[2], CF(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CF(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	CreateJoint("Right Hip", Torso, Limbs[3], CF(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0), CF(0.5, 1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
	CreateJoint("Left Hip", Torso, Limbs[4], CF(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CF(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

	FakeHumanoid = IN("Humanoid"); do
		FakeHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		FakeHumanoid.Parent = FakeRig
	end
	local Animator = IN("Animator"); do
		Animator.Parent = FakeHumanoid
	end
	local HumanoidDescription = IN("HumanoidDescription"); do
		HumanoidDescription.Parent = FakeHumanoid
	end
	local HeadMesh = IN("SpecialMesh") do
		HeadMesh.Scale = V3(1.25, 1.25, 1.25)
		HeadMesh.Parent = Head
	end
	local Face = IN("Decal"); do
		Face.Name = "face"
		Face.Texture = "rbxasset://textures/face.png"
		Face.Transparency = 1
		Face.Parent = Head
	end
	local Animate = IN("LocalScript"); do
		Animate.Name = "Animate" -- Later
		Animate.Parent = FakeRig
	end
	local Health = IN("Script"); do -- not neccessary to fill
		Health.Name = "Health"
		Health.Parent = FakeRig
	end

	FakeRig.Name = "𝔾𝕖𝕝𝕒𝕥𝕖𝕜ℝ𝕒𝕨"..tostring(game.PlaceId)
	FakeRig.PrimaryPart = Head
	FakeRig.Parent = Workspace:FindFirstChildOfClass("Terrain") or Workspace
	FakeRoot.CFrame = RootPart.CFrame * CF(0, 5, 0)

	Attachments[1].Name = "FaceCenterAttachment"
	Attachments[1].Position = V3(0, 0, 0)
	Attachments[2].Name = "FaceFrontAttachment"
	Attachments[2].Position = V3(0, 0, -0.6)
	Attachments[3].Name = "HairAttachment"	
	Attachments[3].Position = V3(0, 0.6, 0)
	Attachments[4].Name = "HatAttachment"
	Attachments[4].Position = V3(0, 0.6, 0)
	Attachments[5].Name = "RootAttachment"
	Attachments[5].Position = V3(0, 0, 0)
	Attachments[6].Name = "RightGripAttachment"
	Attachments[6].Position = V3(0, -1, 0)
	Attachments[7].Name = "RightShoulderAttachment"
	Attachments[7].Position = V3(0, 1, 0)
	Attachments[8].Name = "LeftGripAttachment"
	Attachments[8].Position = V3(0, -1, 0)
	Attachments[9].Name = "LeftShoulderAttachment"
	Attachments[9].Position = V3(0, 1, 0)
	Attachments[10].Name = "RightFootAttachment"
	Attachments[10].Position = V3(0, -1, 0)
	Attachments[11].Name = "LeftFootAttachment"
	Attachments[11].Position = V3(0, -1, 0)
	Attachments[12].Name = "BodyBackAttachment"
	Attachments[12].Position = V3(0, 0, 0.5)
	Attachments[13].Name = "BodyFrontAttachment"
	Attachments[13].Position = V3(0, 0, -0.5)
	Attachments[14].Name = "LeftCollarAttachment"
	Attachments[14].Position = V3(-1, 1, 0)
	Attachments[15].Name = "NeckAttachment"
	Attachments[15].Position = V3(0, 1, 0)
	Attachments[16].Name = "RightCollarAttachment"
	Attachments[16].Position = V3(1, 1, 0)
	Attachments[17].Name = "WaistBackAttachment"
	Attachments[17].Position = V3(0, -1, 0.5)
	Attachments[18].Name = "WaistCenterAttachment"
	Attachments[18].Position = V3(0, -1, 0)
	Attachments[19].Name = "WaistFrontAttachment"
	Attachments[19].Position = V3(0, -1, -0.5)
	Attachments[1].Parent = Head
	Attachments[2].Parent = Head
	Attachments[3].Parent = Head
	Attachments[4].Parent = Head
	Attachments[5].Parent = FakeRoot
	Attachments[6].Parent = Limbs[1]
	Attachments[7].Parent = Limbs[1]
	Attachments[8].Parent = Limbs[2]
	Attachments[9].Parent = Limbs[2]
	Attachments[10].Parent = Limbs[3]
	Attachments[11].Parent = Limbs[4]
	for i = 0,7 do Attachments[12 + i].Parent = Torso end

	FakeRigDescendants = FakeRig:GetDescendants()

	for _, Accessory in pairs(CharDescendants) do
		if Accessory:IsA("Accessory") then
			TI(Hats, Accessory:FindFirstChild("Handle"))

			local FakeAccessory = Accessory:Clone()
			local Handle = FakeAccessory:WaitForChild("Handle")
			local Attachment = Handle:FindFirstChildOfClass("Attachment")
			pcall(function() Handle:FindFirstChildOfClass("Weld"):Destroy() end)
			local Weld = IN("Weld")
			Weld.Name = "AccessoryWeld"
			Weld.Part0 = Handle

			if Attachment then
				Weld.C0 = Attachment.CFrame
				Weld.C1 = FakeRig:FindFirstChild(tostring(Attachment), true).CFrame
				Weld.Part1 = FakeRig:FindFirstChild(tostring(Attachment), true).Parent
			else
				Weld.Part1 = Head
				Weld.C1 = CF(0, Head.Size.Y / 2, 0) * FakeAccessory.AttachmentPoint:Inverse()
			end
			Handle.CFrame = Weld.Part1.CFrame * Weld.C1 * Weld.C0:Inverse()
			Handle.Transparency = 1

			Weld.Parent = Handle
			FakeAccessory.Parent = FakeRig

			local CachedAccessory = FakeAccessory:Clone()
			CachedAccessory.Parent = Global.ReanimateData.HatCache
		end
	end
end

do -- [[ Hat Alignment ]] --
	local DynamicalVelocityEnabled = ReanimSettings.DynamicalVelocity
	local OsClock = os.clock
	local Random = math.random
	local Rad = math.rad
	local Sin = math.sin

	local function GetHatFromId(AccessoryID, Check)
		for _, Target in pairs(CharDescendants) do
			if Target:IsA("Accessory") then
				local Handle = Target:FindFirstChild("Handle")
				local Mesh = Handle:FindFirstChild("SpecialMesh") or Handle:FindFirstChild("Mesh") or Handle
				local PropertyName = Check and "MeshId" or pcall(function() Mesh.TextureID = Mesh.TextureID end) and "TextureID" or "TextureId"
				if (Mesh[PropertyName] == AccessoryID) or (Mesh[PropertyName] == "rbxassetid://"..AccessoryID) then
					table.remove(Hats, table.find(Hats, Target.Handle))
					FakeRig:FindFirstChild(Target.Name):Destroy()
					return Handle
				end
			end
		end
	end

	local function Randomizer(Value)
		return tonumber(Value..".".. Random(0, 9).. Random(0, 9))
	end
	local function GetMass(Part)
		return (Part.Size.X + Part.Size.Y + Part.Size.Z) / (Part.Size.Magnitude / 4.3219)
	end

	local function PullVelocity(Part0, Part1)
		if Part0 and Part1 then
			local Velocity = Part1.Velocity
			local Mass = GetMass(Part0)	
			Part0.Velocity = not DynamicalVelocityEnabled and V3(Randomizer(-23), 0, Randomizer(-23)) or V3(Velocity.X * Mass, Randomizer(-27), Velocity.Z * Mass)
		end
	end
	local function LinkParts(Part0, Part1, CFrame)
		if Part0 and Part1 and isnetworkowner(Part0) then
			Part0.RotVelocity = V3_010*Sin(OsClock()*29)
			Part0.CFrame = Part1.CFrame * CFrame * AntiSleep
		end
	end

	local DefinedHats = ReanimSettings.DefinedHats

	local FakeTorso = FakeRig:WaitForChild("Torso")
	local FakeRA = FakeRig:WaitForChild("Right Arm")
	local FakeLA = FakeRig:WaitForChild("Left Arm")
	local FakeRL = FakeRig:WaitForChild("Right Leg")
	local FakeLL = FakeRig:WaitForChild("Left Leg")

	local Torso = GetHatFromId(DefinedHats['Torso1'][1], DefinedHats['Torso1'][4])
	local TorsoAlt = GetHatFromId(DefinedHats['Torso2'][1], DefinedHats['Torso2'][4])
	local LeftArm = GetHatFromId(DefinedHats['Left Arm'][1], DefinedHats['Left Arm'][4])
	local RightArm = GetHatFromId(DefinedHats['Right Arm'][1], DefinedHats['Right Arm'][4])
	local LeftLeg = GetHatFromId(DefinedHats['Left Leg'][1], DefinedHats['Left Leg'][4])
	local RightLeg = GetHatFromId(DefinedHats['Right Leg'][1], DefinedHats['Right Leg'][4])

	local TorsoCF = DefinedHats['Torso1'][2] * DefinedHats['Torso1'][3]
	local TorsoAltCF = DefinedHats['Torso2'][2] * DefinedHats['Torso2'][3]
	local LeftArmCF = DefinedHats['Left Arm'][2] * DefinedHats['Left Arm'][3]
	local RightArmCF = DefinedHats['Right Arm'][2] * DefinedHats['Right Arm'][3]
	local LeftLegCF = DefinedHats['Left Leg'][2] * DefinedHats['Left Leg'][3]
	local RightLegCF = DefinedHats['Right Leg'][2] * DefinedHats['Right Leg'][3]

	fspawn(function()
		repeat fwait() until ReadyToAlign == true
		TI(Events, Heartbeat:Connect(function()
			PullVelocity(Torso, FakeTorso); LinkParts(Torso, FakeTorso, TorsoCF)
			PullVelocity(LeftArm, FakeLA); LinkParts(LeftArm, FakeLA, LeftArmCF)
			PullVelocity(RightArm, FakeRA); LinkParts(RightArm, FakeRA, RightArmCF)
			PullVelocity(LeftLeg, FakeLL); LinkParts(LeftLeg, FakeLL, LeftLegCF)
			PullVelocity(RightLeg, FakeRL); LinkParts(RightLeg, FakeRL, RightLegCF)

			if TorsoAlt and TorsoAlt.Parent then
				PullVelocity(TorsoAlt, FakeTorso); LinkParts(TorsoAlt, FakeTorso, TorsoAltCF)
			end

			if FlingPart then
				PullVelocity(FlingPart, FakeRoot)
				if not Global.ReanimateData.FlingEnabled then
					LinkParts(FlingPart, FakeRoot, CF(0, -1.5, 0))
				end
			end

			for i, Hat in pairs(Hats) do
				if Hat and Hat.Parent and FakeRig:FindFirstChild(Hat.Parent.Name) then
					local HatTo = FakeRig:FindFirstChild(Hat.Parent.Name).Handle
					PullVelocity(Hat, HatTo)
					LinkParts(Hat, HatTo, CF())
				end
			end
		end))
	end)
end

do -- [[ Loading Reanimation ]] --
	if not ReanimSettings.KeepCharacter then
		local Random = math.random
		local TempEvent; TempEvent = Heartbeat:Connect(function()
			RootPart.CFrame = CFrameOffset
			for i, Hat in pairs(Hats) do
				Hat.Velocity = V3(-50, 500, -50)
			end
		end)

		FakeRoot.CFrame = CFrameOffset + V3(10, 0, 0)

		fspawn(function()
			repeat fwait() until not Character:FindFirstChild("Head")
			repeat fwait() until not Character:FindFirstChild("HumanoidRootPart")
			fwait(1.5)
			TempEvent:Disconnect()
			FakeRoot.Anchored = false

			FakeRoot.Velocity = V3()
			FakeRoot.CFrame = SavedCFrame * CF(0, 5, 0)

			NoclipStatus = ReanimSettings.NoClip
			FakeHumanoid:ChangeState(2)
			FakeHumanoid:ChangeState(7)
		end)
	end

	FakeRoot.Anchored = true
	Client.Character = nil
	Client.Character = FakeRig
	fwait(WaitTime)

	RootPart.Velocity = V3()
	Character.Parent = FakeRig
	Character:BreakJoints()
	Camera.CameraSubject = FakeHumanoid
	ReadyToAlign = true

	fwait(0.75)
	if ReanimSettings.KeepCharacter then
		FakeRoot.Anchored = false
		FakeRoot.CFrame = FakeRoot.CFrame * CF(0, 5, 0)
		FakeRoot.Velocity = V3()

		FakeHumanoid:ChangeState(2)
		FakeHumanoid:ChangeState(7)
		fdelay(1.5, function()
			NoclipStatus = ReanimSettings.NoClip
		end)
	end
end

do -- [[ Reset System ]] --
	local function ClearVariables()
		Global.ReanimateData.ScriptStopped = true
		Global.ReanimateData.FlingEnabled = false
		Global.ReanimateData.FlingPart = nil
		Global.ReanimateData.HatCache:Destroy()
		for _, GlobalSignal in pairs(Global.ReanimateData.Connections) do
			GlobalSignal:Disconnect()
		end

		fdelay(0.25, function()
			Global.ReanimateData.ScriptStopped = false
		end)
	end

	FakeHumanoid.Died:Once(function()
		for _, Signal in pairs(Events) do
			Signal:Disconnect()
		end

		ClearVariables()
		Client.Character = Character
		Character.Parent = Workspace

		if FakeRig then FakeRig:Destroy() end
		Character:BreakJoints()
	end)

	TI(Events, Character:GetPropertyChangedSignal("Parent"):Connect(function(Parent)
		if Parent == nil then
			for _, Signal in pairs(Events) do
				Signal:Disconnect()
			end

			ClearVariables()
			if FakeRig then FakeRig:Destroy() end
		end
	end))
end

do -- [[ Finishing Touches ]] --
	if ReanimSettings.NoClip then
		TI(Events, Stepped:Connect(function()
			for _, Part in pairs(FakeRigDescendants) do
				if NoclipStatus and Part and Part.Parent and Part:IsA("BasePart") then
					Part.CanCollide = false
					Part.CanTouch = false
					Part.CanQuery = false
				end
			end
		end))
	end

	if ReanimSettings.Animations then
		loadstring(game:HttpGet("https://raw.githubusercontent.com/toldblock/GelatekReanimateV2/main/bin/Animations.lua"))()
	end

	fwait(1)

	local Credit = IN("Message")
	Credit.Text = [[Reanimation Loaded! If something fails try again. 
	https://discord.gg/A7VexVaZDA | Version: 1.1.0
	Made by Gelatek, Lay and TimedMarch]]
	Credit.Parent = workspace.Camera
	fdelay(5, function()
		Credit:Destroy()
	end)
end
