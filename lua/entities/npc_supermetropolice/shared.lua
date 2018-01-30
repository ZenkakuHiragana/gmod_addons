
ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

ENT.PrintName = "Super Metropolice"
ENT.Author = "GreatZenkakuMan"
ENT.Contact = ""
ENT.Purpose = "A super metropolice"
ENT.Instruction = ""
ENT.Spawnable = false

ENT.AutomaticFrameAdvance = true
ENT.SearchAngle = 60
ENT.Radius = 16384
ENT.FarDistance = 4096
ENT.NearDistance = 800
ENT.MeleeDistance = 100
ENT.NearDistanceSqr = ENT.NearDistance^2
ENT.WalkSpeed = 70
ENT.RunSpeed = 200
ENT.JumpSpeed = 900
ENT.JumpHeight = 100
ENT.MaxHealth = 125
ENT.StepHeight = 24

ENT.Idle = ACT_IDLE
ENT.Walk = ACT_WALK
ENT.Run = ACT_RUN
ENT.StandRifle = ACT_IDLE_ANGRY_SMG1
ENT.StandPistol = ACT_IDLE_ANGRY_PISTOL
ENT.RunRifle = ACT_RUN_AIM_RIFLE
ENT.RunPistol = ACT_RUN_PISTOL
ENT.WalkRifle = ACT_WALK_RIFLE
ENT.WalkPistol = ACT_WALK

ENT.Primary = {} --Weapon for long distance
ENT.Secondary = {} --Weapon for short distance

ENT.Primary.Sound1 = "Weapon_357.Single"
ENT.Primary.Sound2 = "Weapon_Pistol.NPC_Single"
ENT.Primary.Reload1 = "Weapon_357.Spin"
ENT.Primary.Reload2 = "Weapon_Pistol.Reload"
ENT.Primary.ReloadSequence = "reload_pistol"
ENT.Primary.ReloadSequenceCrouched = "crouch_reload_pistol"
ENT.Primary.Act = ACT_GESTURE_RANGE_ATTACK_PISTOL
ENT.Primary.ReloadAct = ACT_GESTURE_RELOAD_PISTOL
ENT.Primary.ReloadActCrouched = ACT_RELOAD_PISTOL_LOW

ENT.Secondary.Sound1 = "Weapon_Shotgun.Single" --"Weapon_Shotgun.NPC_Single"
ENT.Secondary.Sound2 = "Weapon_SMG1.NPC_Single"
ENT.Secondary.Reload1 = "Weapon_Shotgun.Reload"
ENT.Secondary.Reload2 = "Weapon_SMG1.NPC_Reload"
ENT.Secondary.ReloadSequence = "reload_smg1"
ENT.Secondary.ReloadSequenceCrouched = "crouch_reload_smg1"
ENT.Secondary.Act = ACT_GESTURE_RANGE_ATTACK_SMG1
ENT.Secondary.ReloadAct = ACT_GESTURE_RELOAD_SMG1
ENT.Secondary.ReloadActCrouched = ACT_RELOAD_SMG1_LOW

util.PrecacheSound(ENT.Primary.Sound1)
util.PrecacheSound(ENT.Secondary.Sound1)
util.PrecacheSound(ENT.Primary.Reload1)
util.PrecacheSound(ENT.Secondary.Reload1)

util.PrecacheSound(ENT.Primary.Sound2)
util.PrecacheSound(ENT.Secondary.Sound2)
util.PrecacheSound(ENT.Primary.Reload2)
util.PrecacheSound(ENT.Secondary.Reload2)

CreateConVar("supermetropolice_showkillstreak", 0, FCVAR_ARCHIVE, 
	"Set 1 to show total kills of Super Metropolice when they die.")
CreateConVar("supermetropolice_burninghead", 1, FCVAR_ARCHIVE,
	"Set 0 to extinguish Super Metropolice's head.")

--Heights of muzzle. stand, lower cover, cover(smg1), crouch
ENT.Height = {
	Muzzle = {
		Primary = {59, 45, 54.5, 54.5, 35},
		Secondary = {45, 45, 53.5, 57, 35},
	},
	Eye = {65, 65, 57, 65, 35, 35}, --Lower cover eye position: pistol 56.5, smg 59.9
}

ENT.SentenceLength = {7, 9, 10, 12, 13, 15}
--Metro Police sentence list
ENT.Sentence = {
	--Death sounds
	Dying = {name = "METROPOLICE_DIE", patterns = 8, probability = 1.0, vol = 140},
	--Pain sounds
	Pain = {name = "METROPOLICE_PAIN", patterns = 2, probability = 0.5, vol = 120},
	--Pain sounds (I'm still over 90% health, used only once)
	PainLight = {name = "METROPOLICE_PAIN_LIGHT", patterns = 0, probability = 0.7, vol = 100},
	--Pain sounds (I'm under 25% health for the first time, used only once)
	PainHeavy = {name = "METROPOLICE_PAIN_HEAVY", patterns = 3, probability = 0.7, vol = 110},
	--Simple idle sound, always used when not in squad, sometimes used when in squad
	Idle = {name = "METROPOLICE_IDLE_CR", patterns = 18, probability = 0.4, vol = 100},
	--Check with squadmates
	IdleSquad = {name = "METROPOLICE_IDLE_CHECK_CR", patterns = 7, squad = true, vol = 100},
	--Response to the check with squadmates
	IdleClear = {name = "METROPOLICE_IDLE_CLEAR_CR", patterns = 4, squad = true, vol = 100},
	--Ask a question to squadmates
	IdleQuestion = {name = "METROPOLICE_IDLE_QUEST_CR", patterns = 4, squad = true, vol = 100},
	--Answer to a question asked
	IdleAnswer = {name = "METROPOLICE_IDLE_ANSWER_CR", patterns = 6, squad = true, vol = 100},
	--I heard something
	Heard = {name = "METROPOLICE_HEARD_SOMETHING", patterns = 3, vol = 100},
	--The player is significantly hurt
	EnemyHurt = {name = "METROPOLICE_PLAYERHIT", patterns = 8, squad = true, vol = 100},
	--Taking cover because I have no ammo
	CoverNoAmmo = {name = "METROPOLICE_COVER_NO_AMMO", patterns = 1, squad = true, vol = 110},
	--Taking cover because I have low ammo
	CoverLowAmmo = {name = "METROPOLICE_COVER_LOW_AMMO", patterns = 0, squad = true, vol = 110},
	--Taking cover because I have taken heavy damage recently
	CoverHeavyDamage = {name = "METROPOLICE_COVER_HEAVY_DAMAGE", patterns = 5, squad = true, vol = 100},
	--(UNDONE?) I lost my enemy under 10 seconds ago
	LostEnemyShort = {name = "METROPOLICE_LOST_SHORT", patterns = 2, squad = true, vol = 100},
	--(UNDONE?) I lost my enemy over 10 seconds ago
	LostEnemyLong = {name = "METROPOLICE_LOST_LONG", patterns = 5, squad = true, vol = 100},
	--(UNDONE?) Just found enemy after lost long
	RefindEnemy = {name = "METROPOLICE_REFIND_ENEMY", patterns = 2, squad = true, vol = 100},
	--A squadmate died
	DyingMate = {name = "METROPOLICE_MAN_DOWN", patterns = 2, probability = 0.9, vol = 120},
	--My last squadmate died; I'm all that's left!
	DyingMateLast = {name = "METROPOLICE_LAST_OF_SQUAD", patterns = 3, probability = 1.0, vol = 130},
	
	--Monster Alert - first contact and I'm the squad leader
	----monster
	AlertMonster = {name = "METROPOLICE_MONST", patterns = 1, squad = true, vol = 100},
	----player
	AlertPlayer = {name = "METROPOLICE_MONST_PLAYER", patterns = 6, squad = true, vol = 100},
	----player with vehicle
	AlertPlayerVehicle = {name = "METROPOLICE_MONST_PLAYER_VEHICLE", patterns = 3, squad = true, vol = 100},
	----bugs
	AlertBugs = {name = "METROPOLICE_MONST_BUGS", patterns = 3, squad = true, vol = 100},
	----citizen
	AlertCitizen = {name = "METROPOLICE_MONST_CITIZENS", patterns = 2, squad = true, vol = 100},
	----other character
	AlertCharacter = {name = "METROPOLICE_MONST_CHARACTER", patterns = 2, squad = true, vol = 100},
	----zombies
	AlertZombies = {name = "METROPOLICE_MONST_ZOMBIES", patterns = 1, squad = true, vol = 100},
	----parasites
	AlertParasites = {name = "METROPOLICE_MONST_PARASITES", patterns = 1, squad = true, vol = 100},
	
	--I killed a monster - by type
	----monster
	KillMonster = {name = "METROPOLICE_KILL_MONST", patterns = 2, squad = true, vol = 100},
	----bugs(headcrab?)
	KillBugs = {name = "METROPOLICE_KILL_BUGS", patterns = 1, squad = true, vol = 100},
	----player
	KillPlayer = {name = "METROPOLICE_KILL_PLAYER", patterns = 9, squad = true, vol = 100},
	----citizen
	KillCitizen = {name = "METROPOLICE_KILL_CITIZENS", patterns = 3, squad = true, vol = 100},
	----other character
	KillCharacter = {name = "METROPOLICE_KILL_CHARACTER", patterns = 2, squad = true, vol = 100},
	----zombies
	KillZombies = {name = "METROPOLICE_KILL_ZOMBIES", patterns = 1, squad = true, vol = 100},
	----parasites
	KillParasites = {name = "METROPOLICE_KILL_PARASITES", patterns = 1, squad = true, vol = 100},
	
	--Danger sounds - by type
	----grenade
	DangerGrenade = {name = "METROPOLICE_DANGER_GREN", patterns = 2, squad = true, vol = 125},
	----manhack
	DangerManHack = {name = "METROPOLICE_DANGER_MANHACK", patterns = 1, squad = true, vol = 125},
	----vehicle
	DangerVehicle = {name = "METROPOLICE_DANGER_VEHICLE", patterns = 2, squad = true, vol = 125},
	----other
	DangerGeneral = {name = "METROPOLICE_DANGER", patterns = 1, squad = true, vol = 125},
	
	--First cop who finds you tells you to freeze
	FreezeFirst = {name = "METROPOLICE_FREEZE", patterns = 1, squad = true, probability = 1.0, vol = 130},
	--First cop then tells his buddies to come over
	FreezeSecond = {name = "METROPOLICE_OVER_HERE", patterns = 2, squad = true, vol = 100},
	--First cop tells his buddies the player is fleeing if he does
	FreezeFleeing = {name = "METROPOLICE_HES_RUNNING", patterns = 1, squad = true, vol = 100},
	--Other squad cops signal when they get in position
	FreezeReady = {name = "METROPOLICE_ARREST_IN_POS", patterns = 1, squad = true, vol = 100},
	--First cop tells his buddies to fire once they are all in position
	FreezeFire = {name = "METROPOLICE_TAKE_HIM_DOWN", patterns = 2, squad = true, vol = 110},
}
--Prevents the bot who requested report from reporting
ENT.Sentence.IdleReport = nil
--Prevents the questioner from answering
ENT.Sentence.IdleQuestioner = nil

--Returns the attachment of my eyes.
function ENT:GetEye()
	return self:GetAttachment(self:LookupAttachment("eyes"))
end

--Returns a table with information og what I am looking at.
function ENT:GetEyeTrace(dist)
	return util.QuickTrace(self:GetEye().Pos,
		self:GetEye().Ang:Forward() * (dist or 80), self)
end

--For Half Life Renaissance Reconstructed
function ENT:GetNoTarget()
	return false
end

--For Half Life Renaissance Reconstructed
function ENT:PercentageFrozen()
	return 0
end

--I am an NPC.  not a nextbot, really.
function ENT:IsNPC()
	return true
end

--Returns citizen class
function ENT:Classify()
	return CLASS_CITIZEN_REBEL
end

--Gets a position for aiming at the enemy
function ENT:GetTargetPos(aiming, target)
--	for k, v in pairs(ents.FindInSphere(self:GetPos(), 200)) do
--		if v:GetClass() == "npc_grenade_frag" then
--			return v:GetPos()
--		end
--	end
	
    local e = target
    if not IsValid(e) then e = self:GetEnemy() end
    if not IsValid(e) then 
    	return self:GetEye().Pos + self:GetForward() * self.NearDistance
    end
	local dir, attach, bone = e:GetPos(), 0, nil
	
	if e:GetClass():find("headcrab") then
		return e:GetPos() + Vector(0, 0, 8)
	end
	
	if e:LookupAttachment("head") and e:LookupAttachment("head") > 0 then --for zombie
		attach = e:LookupAttachment("head")
		dir = e:GetAttachment(attach).Pos
	
	elseif e:LookupBone("ValveBiped.Bip01_Head1") then
		attach = nil
		bone = e:LookupBone("ValveBiped.Bip01_Head1")
		dir = e:GetBonePosition(bone)
	elseif e:LookupBone("ValveBiped.Bip01_Neck1") then
		attach = nil
		bone = e:LookupBone("ValveBiped.Bip01_Neck1")
		dir = e:GetBonePosition(bone)
	elseif e:LookupBone("Antlion.Head_Bone") then --for Antlion
		attach = nil
		bone = e:LookupBone("Antlion.Head_Bone")
		dir = e:GetBonePosition(bone)
	elseif e:LookupBone("Bip01 Head") then --for Half-Life Source NPCs
		attach = nil
		bone = e:LookupBone("Bip01 Head")
		dir = e:GetBonePosition(bone)
	elseif e:LookupBone("Bip01 Neck") then --for Half-Life Source NPCs
		attach = nil
		bone = e:LookupBone("Bip01 Neck")
		dir = e:GetBonePosition(bone)
	elseif e:LookupBone("TorSkel Head") then --for Half-Life: Renaissance Tor
		attach = nil
		bone = e:LookupBone("TorSkel Head")
		dir = e:GetBonePosition(bone)
	elseif e:LookupBone("Combine_Strider.Head_Bone") then --for Striders
		attach = nil
		bone = e:LookupBone("Combine_Strider.Head_Bone")
		dir = e:GetBonePosition(bone)
	
	elseif e:LookupAttachment("eyes") and e:LookupAttachment("eyes") > 0 then --for most human
		attach = e:LookupAttachment("eyes")
		dir = e:GetAttachment(attach).Pos
	elseif e:LookupAttachment("light") and e:LookupAttachment("light") > 0 then --for manhack
		attach = e:LookupAttachment("light")
		dir = e:GetAttachment(attach).Pos
	elseif e:LookupAttachment("eye") and e:LookupAttachment("eye") > 0 then --for combine assassin
		attach = e:LookupAttachment("eye")
		dir = e:GetAttachment(attach).Pos
	elseif e:LookupAttachment("head_center") and e:LookupAttachment("head_center") > 0 then --for hunter
		attach = e:LookupAttachment("head_center")
		dir = e:GetAttachment(attach).Pos
	elseif e:LookupAttachment("mouth") and e:LookupAttachment("mouth") > 0 then --for antlion worker
		attach = e:LookupAttachment("mouth")
		dir = e:GetAttachment(attach).Pos
	elseif e:LookupAttachment("innards") and e:LookupAttachment("innards") > 0 then --for barnacle
		attach = e:LookupAttachment("innards")
		dir = e:GetAttachment(attach).Pos
	elseif e:GetAttachments() and #e:GetAttachments() > 0 then
		if aiming then
			self.aimattach = self.aimattach + 1
			if self.aimattach > #e:GetAttachments() then
				self.aimattach = 1
			end
		end
		attach = self.aimattach
		dir = e:GetAttachment(attach or 1).Pos
	end
	return dir
end

--Determines whether given entity is targetable or not.
function ENT:Validate(e)
	if not IsValid(e) or e == self then return -1 end
	
	local c = e:GetClass()
	if c == "npc_rollermine" or c == "npc_turret_floor" then
		return 0
	elseif c ~= "npc_supermetropolice" or IsAlone then
		if e.Health and e:Health() > 0 then
			if not c:find("bullseye") and c ~= "env_flare" and
			c ~= "npc_combinegunship" and c ~= "npc_helicopter" and c ~= "npc_strider" then
				if e:IsNPC() or e.Type == "nextbot" or
				(e:IsPlayer() and not (GetConVar("ai_ignoreplayers"):GetInt() ~= 0 or e:IsFlagSet(FL_NOTARGET))) then
						return 0
				end
			end
		end
	elseif e:GetPos():DistToSqr(self:GetPos()) < self.NearDistanceSqr * 64 then
		return 1
	end
	
	return -1
end

function ENT:IsHearingSound(t)
	return not IsValid(self:GetEnemy()) and
		math.log10(t.Entity:GetPos():DistToSqr(self:GetEye().Pos)) < t.SoundLevel * 0.08
end

 local x, y, z, w = 123456789, 362436069, 521288629, 88675123
function ENT:XorInit(seed)
	x = bit.bxor(x, seed)
	y = bit.bxor(y, bit.rol(seed, 17))
	z = bit.bxor(z, bit.rol(seed, 31))
	w = bit.bxor(w, bit.rol(seed, 18))
end

function ENT:XorRand(min, max)
	local min, max = min or 0, max or 1
	local t = bit.bxor(x, bit.lshift(x, 11))
	x, y, z = y, z, w
	w = bit.bxor(bit.bxor(w, bit.rshift(w, 19)), bit.bxor(t, bit.rshift(t, 8)))
	return math.Remap(w, -(2^31), 2^31 - 1, min, max)
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Look")
	self:NetworkVar("Entity", 0, "NetworkedEnemy")
end

list.Set("NPC", "npc_supermetropolice", {
	Name = "Super Metropolice",
	Class = "npc_supermetropolice",
	Category = "GreatZenkakuMan's NPCs"
})

--[[
--{{ Sequence list:
0	Unknown
1	body_rot_z
2	spine_rot_z
3	neck_trans_x
4	head_rot_z
5	head_rot_y
6	head_rot_x
7	batonidle1
8	batonidle2
9	smg1idle1
10	smg1idle2
11	pistolidle1
12	pistolidle2
13	Idle_Baton
14	BlockEntry
15	buttonright
16	buttonfront
17	buttonleft
18	busyidle1
19	busyidle2
20	harassfront1
21	harassfront2
22	pickup
23	point
24	idleonfire
25	moveonfire
26	rappelloop
27	rappelland
28	dummy1
29	dummy2
30	pushplayer
31	activatebaton
32	deactivatebaton
33	cower
34	flinch_head1
35	flinch_head2
36	flinch_stomach1
37	flinch_stomach2
38	flinch_leftarm1
39	flinch_rightarm1
40	flinch_back1
41	flinch1
42	flinch2
43	flinch_gesture
44	flinchheadgest1
45	flinchheadgest2
46	flinchgutgest1
47	flinchgutgest2
48	flinchlarmgest
49	flinchrarmgest
50	physflinch1
51	physflinch2
52	deathpose_front
53	deathpose_back
54	deathpose_right
55	deathpose_left
56	deploy
57	grenadethrow
58	pistolangryidle2
59	Crouch_idle_pistol
60	drawpistol
61	shootp1
62	gesture_shoot_pistol
63	reload_pistol
64	crouch_reload_pistol
65	gesture_reload_pistolspine
66	gesture_reload_pistolarms
67	gesture_reload_pistol
68	lowcover_shoot_pistol
69	lowcover_aim_pistol
70	smg1angryidle1
71	Crouch_idle_smg1
72	shoot_smg1
73	gesture_shoot_smg1
74	reload_smg1
75	crouch_reload_smg1
76	gesture_reload_smg1spine
77	gesture_reload_smg1arms
78	gesture_reload_smg1
79	lowcover_shoot_smg1
80	lowcover_aim_smg1
81	batonangryidle1
82	swing
83	thrust
84	swinggesturespine
85	swinggesturearms
86	swinggesture
87	pistol_Aim_all
88	WalkN_pistol_Aim_all
89	SMG1_Aim_all
90	WalkN_SMG1_Aim_all
91	Crouch_all
92	walk_all
93	layer_walk_hold_baton_angry
94	walk_hold_baton_angry
95	Pistol_aim_walk_all_delta
96	layer_walk_aiming_pistol
97	walk_aiming_pistol_all
98	layer_walk_hold_pistol
99	walk_hold_pistol
100	SMG1_aim_walk_all_delta
101	layer_walk_aiming_SMG1
102	walk_aiming_SMG1_all
103	layer_walk_hold_smg1
104	walk_hold_smg1
105	run_all
106	Pistol_aim_run_all_delta
107	layer_run_hold_pistol
108	run_hold_pistol
109	layer_run_aiming_pistol
110	run_aiming_pistol_all
111	smg1_aim_run_all_delta
112	layer_run_hold_smg1
113	run_hold_smg1
114	layer_run_aiming_smg1
115	run_aiming_smg1_all
116	Stand_to_crouchpistol
117	Crouch_to_standpistol
118	Shoot_to_crouchpistol
119	Crouch_to_shootpistol
120	shoottostandpistol
121	standtoshootpistol
122	crouch_to_lowcoverpistol
123	lowcover_to_crouchpistol
124	Stand_to_crouchsmg1
125	Crouch_to_standsmg1
126	Shoot_to_crouchsmg1
127	Crouch_to_shootsmg1
128	crouch_to_lowcoversmg1
129	lowcover_to_crouchsmg1
130	turnleft
131	turnright
132	gesture_turn_left_45default
133	gesture_turn_left_45inDelta
134	gesture_turn_left_45outDelta
135	gesture_turn_left_45
136	gesture_turn_left_90default
137	gesture_turn_left_90inDelta
138	gesture_turn_left_90outDelta
139	gesture_turn_left_90
140	gesture_turn_right_45default
141	gesture_turn_right_45inDelta
142	gesture_turn_right_45outDelta
143	gesture_turn_right_45
144	gesture_turn_right_90default
145	gesture_turn_right_90inDelta
146	gesture_turn_right_90outDelta
147	gesture_turn_right_90
148	jump_holding_jump
149	jump_holding_glide
150	jump_holding_land
151	Neutral_to_Choked_Barnacle
152	Choked_Barnacle
153	Crushed_Barnacle
154	Dropship_Deploy
155	Man_Gun_Aim_all
156	Man_Gun
157	local_reference
158	shootflare
159	jumpdown128
160	canal3jump1
161	canal3jump2
162	canal1jump1
163	barrelpushidle
164	barrelpush
165	canal5bidle1
166	canal5bidle2
167	canal5breact1
168	canal5breact2
169	forcescanner
170	plazalean
171	plazahalt
172	plazathreat1
173	plazathreat2
174	dooridle
175	dooropen
176	itemhit
177	adoorenter
178	adoorkick
179	kickdoorbaton
180	adooridle
181	adoorknock
182	adoorcidle
183	harrassidle
184	harrassapcidle
185	harrassapcslam
186	luggagewarn
187	luggagepush
188	ts_luggageShove_All
189	harrassalert
190	APCidle
191	SMGcover
192	Spreadwall
193	motionright
194	motionleft
195	arrestpreidle
196	arrestpunch
197	stopwomanpre
198	stopwoman


--{{ Activities:
0	ACT_DIERAGDOLL
1	
2	
3	
4	
5	
6	
7	ACT_IDLE
8	ACT_IDLE
9	ACT_IDLE_SMG1
10	ACT_IDLE_SMG1
11	ACT_IDLE_PISTOL
12	ACT_IDLE_PISTOL
13	
14	
15	
16	
17	
18	ACT_BUSY_LEAN_BACK
19	ACT_BUSY_STAND
20	ACT_POLICE_HARASS1
21	ACT_POLICE_HARASS2
22	ACT_PICKUP_GROUND
23	ACT_METROPOLICE_POINT
24	ACT_IDLE_ON_FIRE
25	ACT_RUN_ON_FIRE
26	ACT_RAPPEL_LOOP
27	ACT_RAPPEL_LAND
28	
29	
30	ACT_PUSH_PLAYER
31	ACT_ACTIVATE_BATON
32	ACT_DEACTIVATE_BATON
33	ACT_COWER
34	ACT_FLINCH_HEAD
35	ACT_FLINCH_HEAD
36	ACT_FLINCH_STOMACH
37	ACT_FLINCH_STOMACH
38	ACT_FLINCH_LEFTARM
39	ACT_FLINCH_RIGHTARM
40	ACT_METROPOLICE_FLINCH_BEHIND
41	ACT_SMALL_FLINCH
42	ACT_BIG_FLINCH
43	ACT_GESTURE_SMALL_FLINCH
44	ACT_GESTURE_FLINCH_HEAD
45	ACT_GESTURE_FLINCH_HEAD
46	ACT_GESTURE_FLINCH_STOMACH
47	ACT_GESTURE_FLINCH_STOMACH
48	ACT_GESTURE_FLINCH_LEFTARM
49	ACT_GESTURE_FLINCH_RIGHTARM
50	ACT_FLINCH_PHYSICS
51	ACT_FLINCH_PHYSICS
52	ACT_DIE_FRONTSIDE
53	ACT_DIE_BACKSIDE
54	ACT_DIE_RIGHTSIDE
55	ACT_DIE_LEFTSIDE
56	ACT_METROPOLICE_DEPLOY_MANHACK
57	ACT_COMBINE_THROW_GRENADE
58	ACT_IDLE_ANGRY_PISTOL
59	ACT_COVER_PISTOL_LOW
60	ACT_METROPOLICE_DRAW_PISTOL
61	ACT_RANGE_ATTACK_PISTOL
62	ACT_GESTURE_RANGE_ATTACK_PISTOL
63	ACT_RELOAD_PISTOL
64	ACT_RELOAD_PISTOL_LOW
65	
66	
67	ACT_GESTURE_RELOAD_PISTOL
68	ACT_RANGE_ATTACK_PISTOL_LOW
69	ACT_RANGE_AIM_PISTOL_LOW
70	ACT_IDLE_ANGRY_SMG1
71	ACT_COVER_SMG1_LOW
72	ACT_RANGE_ATTACK_SMG1
73	ACT_GESTURE_RANGE_ATTACK_SMG1
74	ACT_RELOAD_SMG1
75	ACT_RELOAD_SMG1_LOW
76	
77	
78	ACT_GESTURE_RELOAD_SMG1
79	ACT_RANGE_ATTACK_SMG1_LOW
80	ACT_RANGE_AIM_SMG1_LOW
81	ACT_IDLE_ANGRY_MELEE
82	ACT_MELEE_ATTACK_SWING
83	ACT_MELEE_ATTACK_THRUST
84	
85	
86	ACT_MELEE_ATTACK_SWING_GESTURE
87	
88	
89	
90	
91	ACT_WALK_CROUCH
92	ACT_WALK
93	
94	ACT_WALK_ANGRY
95	
96	
97	ACT_WALK_AIM_PISTOL
98	
99	ACT_WALK_PISTOL
100	
101	
102	ACT_WALK_AIM_RIFLE
103	
104	ACT_WALK_RIFLE
105	ACT_RUN
106	
107	
108	ACT_RUN_PISTOL
109	
110	ACT_RUN_AIM_PISTOL
111	
112	
113	ACT_RUN_RIFLE
114	
115	ACT_RUN_AIM_RIFLE
116	ACT_TRANSITION
117	ACT_TRANSITION
118	ACT_TRANSITION
119	ACT_TRANSITION
120	ACT_TRANSITION
121	ACT_TRANSITION
122	ACT_TRANSITION
123	ACT_TRANSITION
124	ACT_TRANSITION
125	ACT_TRANSITION
126	ACT_TRANSITION
127	ACT_TRANSITION
128	ACT_TRANSITION
129	ACT_TRANSITION
130	ACT_GESTURE_TURN_LEFT
131	ACT_GESTURE_TURN_RIGHT
132	
133	
134	
135	ACT_GESTURE_TURN_LEFT45
136	
137	
138	
139	ACT_GESTURE_TURN_LEFT90
140	
141	
142	
143	ACT_GESTURE_TURN_RIGHT45
144	
145	
146	
147	ACT_GESTURE_TURN_RIGHT90
148	ACT_JUMP
149	ACT_GLIDE
150	ACT_LAND
151	
152	
153	
154	
155	
156	ACT_IDLE_MANNEDGUN
157	
158	
159	
160	
161	
162	
163	
164	
165	
166	
167	
168	
169	
170	
171	
172	ACT_BUSY_THREAT
173	ACT_BUSY_THREAT
174	
175	
176	
177	
178	
179	
180	
181	
182	
183	
184	
185	
186	
187	
188	
189	
190	
191	
192	
193	
194	
195	
196	
197	
198	


--{{ Pose parameters:
body_yaw: -29.734262466431 / 29.734231948853
spine_yaw: -30.708503723145 / 30.708478927612
neck_trans: -0.20750752091408 / 0.25939956307411
head_yaw: -66.70654296875 / 66.706314086914
head_pitch: -34.866584777832 / 25.376663208008
head_roll: -10.931429862976 / 10.852429389954
move_yaw: -180 / 180
aim_pitch: -86.324005126953 / 56.203525543213
aim_yaw: -60 / 60
]]
