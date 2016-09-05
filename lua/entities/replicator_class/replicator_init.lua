AddCSLuaFile( )

if SERVER then

	function ReplicatorInitialize( self )
		
		local phys = self:GetPhysicsObject()

		self:CollisionRulesChanged()
		self:SetCustomCollisionCheck( true ) 	
		
		self.rMove = false
		self.rMoveMode = 1
		self.rDisableMovining = false
		
		self.rMoveTo = self:GetPos()
		self.rMoveStep = 0
		
		self.rTargetEnt = Entity( 0 )
		self.rTargetGueen = Entity( 0 )

		self.rTargetMetalId = "" 
		self.rTargetDarkId = ""
		
		self.rMetalAmount = 0
		
		self.rPrevPosition = { pos = self:GetPos(), angle = self:GetAngles() }

		// 1 Work
		// 2 Attack
		// 3 Defence
		// 4 Transform
		
		self.rMode = 0
		self.rResearch = true

		// Research 0 - Stay 1 - Walk
		// Work 0 - Moving 1 - Eating
		self.rModeStatus = 0
		self.rYawRot = 0
		
		phys:SetMaterial( "gmod_ice" )

		table.Add( m_workersCount, self )
		
		if  IsValid( phys ) and self.assemble then 
			
			phys:EnableGravity( true )
			
			self.rMode = -1
			self.rResearch = false
			
			timer.Simple( CNRPlaySequence( self, "assembling" ), function()

				self.rMode = 0
				self.rResearch = true
			
				if self:IsValid() then
					
					CNRPlaySequence( self, "stand" )
					
					if IsValid( phys ) then phys:Wake() end
				end
			end )
		else CNRPlaySequence( self, "stand" ) end

		
		self.rPrevPointId = { case = "", index = 0 }
		self.rPrevPos = self:GetPos()
		
		// ======== Spawning NPCTarget entity
		local target = ents.Create( "npc_bullseye" )
		target:SetPos( self:LocalToWorld( Vector( 0, 0, self:OBBMaxs().z ) ) )
		target:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
		target:SetMaterial( "models/shiny")
		target:Spawn()
		
		target.rReplicatorsNPCTarget = true
		target:SetMoveType( MOVETYPE_NONE )
		target:SetNotSolid( true )
		target:SetParent( self )
		
		
		target:SetKeyValue( "spawnflags", 65536 )
		target:SetHealth( 1000 )
		
		self.rReplicatorNPCTarget = target
		target.rParentReplicator = self
		
	end
end // SERVER

if CLIENT then

	function ReplicatorInitialize( self )
	
		self.cPoint = Vector()
		self.pPoint = Vector()
	
	end
end // CLIENT