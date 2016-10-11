--[[

	REPLICATORS
	
]]
AddCSLuaFile()

--------------------- Replicator soundscripts ----------------------------

local AcidSpit =
{
	channel	= CHAN_WEAPON,
	name	= "Replicator.AcidSpit",
	level	= 60,
	sound	= "acid/acid_spit.wav",
	volume	= 1.0,
	pitch	= {125, 175},
}
sound.Add(AcidSpit)

local ReplicatorStep =
{
	channel	= CHAN_BODY,
	name	= "Replicator.Footstep",
	level	= 65,
	sound	= {
		"replicators/replicatorstep1.wav",
		"replicators/replicatorstep2.wav",
		"replicators/replicatorstep3.wav",
		"replicators/replicatorstep4.wav",
	},
	volume	= 1.0,
	pitch	= {75, 125},
}
sound.Add(ReplicatorStep)

local ReplicatorCrafting =
{
	channel	= CHAN_ITEM,
	name	= "Replicator.Crafting",
	level	= 60,
	sound	= {
		"physics/metal/weapon_impact_soft1.wav",
		"physics/metal/weapon_impact_soft2.wav",
		"physics/metal/weapon_impact_soft3.wav",
	},
	volume	= 1.0,
	pitch	= {125, 175},
}
sound.Add(ReplicatorCrafting)

local ReplicatorReassemble =
{
	channel	= CHAN_BODY,
	name	= "Replicator.Reassamble",
	level	= 60,
	sound	= "replicators/repassembling.wav",
	volume	= 1.0,
	pitch	= {70, 80},
}
sound.Add(ReplicatorReassemble)

local ReplicatorReassembleQueen =
{
	channel	= CHAN_BODY,
	name	= "Replicator.ReassambleQueen",
	level	= 60,
	sound	= "replicators/repassembling.wav",
	volume	= 1.0,
	pitch	= {100, 110},
}
sound.Add(ReplicatorReassembleQueen)

local ReplicatorPhysicsCollide =
{
	channel	= CHAN_BODY,
	name	= "Replicator.PhysicsCollide",
	level	= 60,
	sound	= {
		"weapons/fx/tink/shotgun_shell1.wav",
		"weapons/fx/tink/shotgun_shell2.wav",
		"weapons/fx/tink/shotgun_shell3.wav",
	},
	volume	= 1.0,
	pitch	= {150, 175},
}
sound.Add(ReplicatorPhysicsCollide)

local ReplicatorBreak =
{
	channel	= CHAN_BODY,
	name	= "Replicator.Break",
	level	= 75,
	sound	= "npc/manhack/gib.wav",
	volume	= 1.0,
	pitch	= {125, 175},
}
sound.Add(ReplicatorReassemble)
