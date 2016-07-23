AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Editable		= true
ENT.PrintName		= "Undertale Bone"
ENT.Spawnable 		= false
ENT.AdminSpawnable 	= false

if( CLIENT ) then killicon.Add( "ent_undertale_bone_throw", "undertale/killicon_bone", color_white ) end

function ENT:Initialize()
	if( SERVER ) then
		self:SetModel( "models/undertale/undertale_bone.mdl" )
		self:SetTrigger( true )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetModelScale( self:GetModelScale() / 2, 0 )
		self:SetVar( "hit", false )
		
		local phys = self:GetPhysicsObject()
		phys:EnableGravity( false )
	end
	
	if( CLIENT ) then
		local vec = self:GetPos()
		local emitter = ParticleEmitter( vec, false )
		
		//effects/fire_cloud1
		for cycles = 1, 10 do
			local particle = emitter:Add( Material( "effects/fire_cloud1" ), vec )
			if( particle ) then
				particle:SetVelocity( VectorRand() * 40 )
				particle:SetColor( 0, 100, 255 ) 
				particle:SetLifeTime( 0 )
				particle:SetDieTime( 1 )
				particle:SetAngles( Angle( math.Rand( 0, 360 ), 0, 0 ) )
				particle:SetAngleVelocity( Angle( math.Rand( -1, 1 ), 0, 0 ) )
				particle:SetStartSize( 20 )
				particle:SetEndSize( 10 )
				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 0 )
				particle:SetGravity( Vector( 0, 0, 60 ) )
			end
		end
		
		emitter:Finish()
	end
end

if( SERVER ) then
	function ENT:Think()
		local parent = self:GetParent()
		
		if( parent:IsValid() ) then
			if( parent:IsPlayer() ) then
				if( parent:Health() <= 0 ) then
					self:Remove()
				end
			end
		end
	end

	function ENT:PhysicsUpdate( )
		if( !self:GetVar( "hit", NULL ) ) then
			if( self:GetVelocity():Length() < 1000 ) then
				self:SetVar( "hit", true )
				self:Fire( "Kill", "", 10 )
				local phys = self:GetPhysicsObject()
				phys:EnableGravity( true )
			end
		end
	end

	function ENT:PhysicsCollide( data, phys )
		if( !self:GetVar( "hit", NULL ) ) then
			if( data.Speed > 100 ) then
				local hitEnt = data.HitEntity
				
				if( hitEnt:GetClass() != "ent_undertale_bone_throw" && hitEnt != self.Owner ) then
					self:SetMoveType( MOVETYPE_NONE )
					self:SetPos( data.HitPos )
					self:SetSolid( SOLID_NONE )
					
					if( hitEnt:IsValid()) then
						//if hitEnt:Health() > 0 then
							hitEnt:TakeDamage( 15, self.Owner, self )
							self:SetParent( hitEnt, -1 )
						//end
					end
					
					self:SetVar( "hit", true )
					self:Fire( "Kill", "", 10 )
					sound.Play( Sound( "undertale/sans/smash.wav" ), self:GetPos() )
				end
			end
		end
	end
end