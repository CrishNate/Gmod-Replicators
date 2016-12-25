AddCSLuaFile( )

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"

ENT.Editable		= false
ENT.PrintName		= "Replicator Gueen Swamp"
ENT.Spawnable 		= true
ENT.AdminSpawnable 	= false
ENT.Category		= "Stargate"
ENT.AutomaticFrameAdvance = true 

function ENT:Initialize()

	local m_Ent = ents.Create( "replicator_queen" )
	
	if ( !IsValid( m_Ent ) ) then return end
	m_Ent:SetPos( self:GetPos() )
	m_Ent:SetAngles( self:GetAngles() )
	m_Ent:SetOwner( self:GetOwner() )
	m_Ent:Spawn()

	m_Ent.rMode 			= 4
	m_Ent.rModeStatus		= 2
	m_Ent.rResearch			= false
	m_Ent.rMetalAmount		= 100
	
	m_Ent.rMove 			= false
	m_Ent.rDisableMovining 	= false
	m_Ent.rMoveStep			= 0
	m_Ent.rModeStatus		= 2

	self:Remove()
end