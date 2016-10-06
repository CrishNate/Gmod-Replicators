--[[

	REPLICATORS Data
	
]]

AddCSLuaFile( )

//=================== Replicators settings ============================

REPLICATOR.Convars = {}
REPLICATOR.Convars["tr_replicators_limit"] = CreateConVar("tr_replicators_limit", "30", FCVAR_NONE, "Limit for Replicator count")
REPLICATOR.Convars["tr_replicators_collection_speed"] = CreateConVar("tr_replicators_collection_speed", "5", FCVAR_NONE, "Speed at which Replicators collect metal")
REPLICATOR.Convars["tr_replicators_giving_speed"] = CreateConVar("tr_replicators_giving_speed", "10", FCVAR_NONE, "Sets the speed at which Replicators give metal")
REPLICATOR.Convars["tr_replicators_dark_level"] = CreateConVar("tr_replicators_dark_level", "20", FCVAR_NONE, "Sets the light level that underwhich is considered dark for Replicators")
REPLICATOR.Convars["tr_replicators_blocks_multiplier"] = CreateConVar("tr_replicators_blocks_multiplier", "1", FCVAR_NONE, "Multiplier for number of blocks required to (dis)assemble Replicators")

function REPLICATOR:IsValid()
	return true
end

function REPLICATOR:UpdateParameters()
	g_replicator_limit = self.Convars["tr_replicators_limit"]:GetInt()
	g_replicator_collection_speed = self.Convars["tr_replicators_collection_speed"]:GetInt()
	g_replicator_giving_speed = self.Convars["tr_replicators_giving_speed"]:GetInt()
	g_replicator_min_dark_level = self.Convars["tr_replicators_dark_level"]:GetInt()

	local x = self.Convars["tr_replicators_blocks_multiplier"]:GetFloat()
	g_segments_to_assemble_replicator = 30 * x
	g_segments_to_assemble_queen = 90 * x
end
hook.Add("Think", REPLICATOR, REPLICATOR.UpdateParameters)

//========================= Replicators data ===========================
g_PathPoints 		= { }
g_MetalPoints 		= { } g_MetalPointsAssigned = { }
g_DarkPoints 		= { }

g_PointIsInvalid 	= { }
g_Attackers 		= { }

g_QueenCount 		= { }
g_WorkersCount 		= { }
g_Replicators		= { }
