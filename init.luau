local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

local RagDoll = {}
RagDoll.__index = RagDoll

function RagDoll.new(character: Model)
	local self = setmetatable({}, RagDoll)
	self.Character = character
	self.created = {}
	self.motors = {}
	self.collisionModified = {}

	self.Character:SetAttribute("IsRagDoll", true)

	for _, instance: Instance in pairs(character:GetDescendants()) do
		if instance:IsA("Humanoid") then
			self.Humanoid = instance
			self.Humanoid.EvaluateStateMachine = true
			self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			self.Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
		elseif instance:IsA("Motor6D") then
			table.insert(self.motors, instance)
		end
	end

	for _, motor in pairs(self.motors) do
		local ballSocket = self:replaceConstraint(motor)
		table.insert(self.created, ballSocket)
	end

	return self
end

function RagDoll:replaceConstraint(motor: Motor6D): BallSocketConstraint
	local ballSocketConstraint = Instance.new("BallSocketConstraint")
	local attachment0 = Instance.new("Attachment")
	local attachment1 = Instance.new("Attachment")
	table.insert(self.created, attachment0)
	table.insert(self.created, attachment1)

	self.collisionModified[motor.Part0] = motor.Part0.CanCollide

	motor.Part0.CanCollide = false
	-- motor.Part1.CanCollide = false

	attachment0.Parent = motor.Part0
	attachment1.Parent = motor.Part1

	ballSocketConstraint.Parent = motor.Parent
	ballSocketConstraint.Attachment0 = attachment0
	ballSocketConstraint.Attachment1 = attachment1

	attachment0.CFrame = motor.C0
	attachment1.CFrame = motor.C1

	ballSocketConstraint.MaxFrictionTorque = 50
	ballSocketConstraint.LimitsEnabled = true
	ballSocketConstraint.TwistLimitsEnabled = true

	motor.Enabled = false
	return ballSocketConstraint
end

function RagDoll:Destroy()
	self.Humanoid.EvaluateStateMachine = true
	for instance, default in pairs(self.collisionModified) do
		instance.CanCollide = default
	end
	for _, motor: Motor6D in pairs(self.motors) do
		motor.Enabled = true
	end
	for _, instance: BallSocketConstraint | Attachment in pairs(self.created) do
		instance:Destroy()
	end
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)

	self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	self.Character:SetAttribute("IsRagDoll", nil)

	local humanoidRoot: BasePart = self.Character:FindFirstChild("HumanoidRootPart")
	if humanoidRoot then
		humanoidRoot.CanCollide = true
	end

	table.clear(self)
end

return RagDoll
