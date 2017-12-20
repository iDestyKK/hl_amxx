/*
 * Killstreak Mechanism for Half-Life
 *
 * Description:
 *     Implements a killstreak system into Half-Life, inspired by Call of Duty
 *     Modern Warfare 2's mechanism. However, this one is a bit more strict in
 *     that unused streaks will be overwritten the moment that another is
 *     obtained. Also if you die, you lose any streaks you have (including ones
 *     that you have not used yet).
 *
 *     The streaks obtainable are as follows:
 *        3  - Full Health
 *        5  - Health Regeneration (Slow)
 *        7  - Airstrike (Fire wherever you are looking toward)
 *        9  - Double Damage (for 30 seconds)
 *        11 - Health Regeneration (Fast)
 *        15 - Quad Damage (for 30 seconds)
 *        25 - Nuke (Game Ender)
 *
 * Synopsis:
 *     The mod will add an extra console command (ks_use) which should be
 *     binded to a key. You will be notified in the game's chat if you have
 *     obtained a killstreak and can use it.
 *
 * Author:
 *     Clara Nguyen (@iDestyKK)
 */

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>

#define PLUGIN_NAME    "Killstreak Mechanism"
#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR  "iDestyKK"

//--------------------------------
// Globals {{{1

#define KS_REWARD_NUM  7
#define KS_FULL_HEALTH 100

new sKillstreak_name[KS_REWARD_NUM][] = {
	"Full Health",
	"Health Regen (Slow)",
	"Airstrike",
	"Double Damage",
	"Health Regen (Fast)",
	"Quad Damage",
	"Nuke"
};

new iKillstreak_goal[KS_REWARD_NUM] = {
	3, 5, 7, 9, 11, 15, 25
};

new iKillstreak[32], iKillstreak_at[32], iKillstreak_used[32];
new iKillstreak_slow_heal[32], iKillstreak_fast_heal[32], iKillstreak_2x[32], iKillstreak_4x[32];
new Float:nuke_delay = 0.0;
new nuke_ended = 0;
new nuke_issued = -1;
new Float:nuke_timelimit_before = -1.0;


//--------------------------------
// Helper Functions {{{1

public generate_flash() {
	new iEntity = create_entity("env_fade");

	new Float:pos[3];
	pos[0] = 0.0;
	pos[1] = pos[0];
	pos[2] = pos[0];
	entity_set_origin(iEntity, pos);
	
	DispatchKeyValue(iEntity, "duration", "5");
	DispatchKeyValue(iEntity, "holdtime", "1");
	DispatchKeyValue(iEntity, "renderamt", "255");
	DispatchKeyValue(iEntity, "rendercolor", "255 255 255");
	entity_set_int(iEntity, EV_INT_spawnflags, SF_FADE_IN);

	DispatchSpawn(iEntity);
	force_use(iEntity, iEntity);
	return iEntity;
}

stock generate_explosion(Float:fPos[3], iOwner, iMagnitude) {
	//Create the explosion
	new iEntity = create_entity("env_explosion");

	//Set the explosion to the user's location
	entity_set_origin(iEntity, fPos);

	//Set the magnitude
	new magnitude[8];
	formatex(magnitude, charsmax(magnitude), "%3d", iMagnitude);
	DispatchKeyValue(iEntity, "iMagnitude", magnitude);

	entity_set_int(iEntity, EV_INT_spawnflags, 0);

	//Spawn the explosion
	DispatchSpawn(iEntity);
	force_use(iOwner, iEntity);

	return iEntity;
}

public killstreak_init(id) {
	iKillstreak          [id] =  0;
	iKillstreak_at       [id] = -1;
	iKillstreak_used     [id] =  1;
	iKillstreak_slow_heal[id] =  0;
	iKillstreak_fast_heal[id] =  0;
	iKillstreak_2x       [id] =  0;
	iKillstreak_4x       [id] =  0;
}

//--------------------------------
// Functions {{{1

public plugin_init() {
	register_plugin(
		PLUGIN_NAME,
		PLUGIN_VERSION,
		PLUGIN_AUTHOR
	);

	//Set up killstreak data
	for (new i = 0; i < 32; i++) {
		killstreak_init(i);
	}

	//Register events
	register_event("DeathMsg", "killstreak_handle", "a");
	RegisterHam(Ham_TakeDamage, "player", "killstreak_damage");

	//Register commands
	register_concmd(
		"ks_use",
		"killstreak_use",
		-1,
		"Uses a killstreak (if earned and available)"
	);

	//Test Function to make the nuke work without streak requirement
	//register_concmd("ks_nuke", "nuke_init", -1, "");
	//register_concmd("ks_flash", "generate_flash", -1, "");
}

public nuke_init(id) {
	if (nuke_issued == -1) {
		nuke_issued = id;
		nuke_delay = 1.0;
		nuke_timelimit_before = get_cvar_float("mp_timelimit");
		set_cvar_float("mp_timelimit", 0.0);
		set_task(nuke_delay, "nuke_generate_explosions");
		set_task(15.0, "nuke_endgame");
		set_task(10.0, "generate_flash");
	}
	else {
		client_print(
			id,
			print_chat,
			"[STREAK] Sorry! A nuke is already going off..."
		);
	}
}

public nuke_generate_explosions() {
	if (nuke_ended == 0) {
		for (new i = 0; i < 32; i++) {
			if (is_user_connected(i)) {
				//Get User Coordinates
				new origin[3];
				get_user_origin(i, origin, 0);

				new Float:forigin[3];
				IVecFVec(origin, forigin);

				forigin[0] += (-150 + random(300));
				forigin[1] += (-150 + random(300));
				forigin[2] += (-150 + random(300));

				generate_explosion(forigin, i, 150);
			}
		}

		if (nuke_delay > 0.5) {
			nuke_delay -= (0.0075 + (1.0 - nuke_delay) * 0.75);
			if (nuke_delay < 0.5)
				nuke_delay = 0.5;
		}
		else
			nuke_delay -= 0.025;

		//Ensure that it doesn't go below 0.1
		if (nuke_delay < 0.1)
			nuke_delay = 0.1;

		set_task(nuke_delay, "nuke_generate_explosions");
	}
}

public nuke_endgame() {
	//Set the match time limit to 0.001 minutes, ending it.
	nuke_ended = 1;
	new Float:time_val = 0.001;
	set_cvar_float("mp_timelimit", time_val);
	set_task(0.1, "nuke_reset_time");
}

public nuke_reset_time() {
	set_cvar_float("mp_timelimit", nuke_timelimit_before);
}

public killstreak_handle() {
	//Argument parsing
	new iKiller = read_data(1),
	    iVictim = read_data(2);

	if (iKiller != 0) {
		//Check if the player suicided or not
		if (iKiller != iVictim) {
			iKillstreak[iKiller]++;

			if (iKillstreak[iKiller] >= iKillstreak_goal[iKillstreak_at[iKiller] + 1]) {
				iKillstreak_at  [iKiller]++;
				iKillstreak_used[iKiller] = 0;
				
				new sUser[64];
				get_user_name(iKiller, sUser, 64);

				client_print(
					0,
					print_chat,
					"[STREAK] %s is on a %d Kill Streak! They can use %s!",
					sUser,
					iKillstreak[iKiller],
					sKillstreak_name[iKillstreak_at[iKiller]]
				);
			}
		}
	}

	//Set the victim's streak down
	killstreak_init(iVictim);
}

public killstreak_use(id) {
	//Get the name of the user
	new sUser[64];
	get_user_name(id, sUser, 64);

	//Print out info
	if (iKillstreak[id] < iKillstreak_goal[0]) {
		//We haven't earned a streak yet...
		client_print(
			id,
			print_chat,
			"[STREAK] %s, you do not have a streak to use!",
			sUser
		);
	}
	else
	if (iKillstreak_used[id] != 0) {
		//We earned a streak but we already used it.
		client_print(
			id,
			print_chat,
			"[STREAK] %s, you already used your %s!",
			sUser,
			sKillstreak_name[iKillstreak_at[id]]
		);
	}
	else {
		//We haven't used our streak yet... let's take action.
		client_print(
			0,
			print_chat,
			"[STREAK] %s used their %s!",
			sUser,
			sKillstreak_name[iKillstreak_at[id]]
		);

		//Actually perform the stuff we just said about in the chat...
		iKillstreak_used[id] = 1;

		switch (iKillstreak_at[id]) {
			case 0: {
				//Full Health
				set_user_health(id, KS_FULL_HEALTH);
			}
			case 1: {
				//Health Regen (Slow)
				iKillstreak_slow_heal[id] = 1;
				killstreak_slow_heal(id);
				set_task(30.0, "killstreak_stop_slow_heal", id);
			}
			case 2: {
				//Airstrike

				//Get User Coordinates
				new origin[3];
				get_user_origin(id, origin, 3);

				new Float:forigin[3];
				IVecFVec(origin, forigin);

				//Generate explosion
				generate_explosion(forigin, id, 150);
			}
			case 3: {
				//Double Damage
				iKillstreak_2x[id] = 1;
				set_task(30.0, "killstreak_stop_2x", id);
			}
			case 4: {
				//Health Regen (Fast)
				iKillstreak_fast_heal[id] = 1;
				killstreak_fast_heal(id);
				set_task(30.0, "killstreak_stop_fast_heal", id);
			}
			case 5: {
				//Quad Damage
				iKillstreak_4x[id] = 1;
				set_task(30.0, "killstreak_stop_4x", id);
			}
			case 7: {
				//Nuke
				nuke_init(id);
			}
			default: {
				//Killstreak not available
			}
		}
	}
}

//--------------------------------
// Hamsandwich Functions {{{1

public killstreak_damage(iVictim, Useless, iAttacker, Float:damage, damagebits) {
	//Handle damage multipliers... if any.
	//TODO: Make this look cleaner.
	//TODO: Implement Auras? (Aura can withstand all damage under XXX)
	
	//If there is a nuke going off, the person who issued it is invincible.
	if (nuke_issued == iVictim) {
		SetHamParamFloat(4, 0.0);
		return HAM_HANDLED;
	}

	if (iAttacker != 0) {
		//Hitmaker sound
		client_cmd(iAttacker, "spk ^"%s^"", "custom/mp_hit_indication_3c.wav");

		if (iKillstreak_4x[iAttacker] == 1 && iKillstreak_2x[iAttacker] == 1) {
			SetHamParamFloat(4, damage * 8.0);
			return HAM_HANDLED;
		}
		if (iKillstreak_4x[iAttacker] == 1) {
			SetHamParamFloat(4, damage * 4.0);
			return HAM_HANDLED;
		}
		if (iKillstreak_2x[iAttacker] == 1) {
			SetHamParamFloat(4, damage * 2.0);
			return HAM_HANDLED;
		}
	}

	return HAM_IGNORED;
}

//--------------------------------
// Activation Functions {{{1

public killstreak_slow_heal(id) {
	new iHealth = get_user_health(id);
	iHealth += 5;

	//Enforce that the health is going to be 100 max
	if (iHealth >= 100)
		iHealth = 100;

	//Set health
	set_user_health(id, iHealth);
	if (iKillstreak_slow_heal[id])
		set_task(1.0, "killstreak_slow_heal", id);
}

public killstreak_fast_heal(id) {
	new iHealth = get_user_health(id);
	iHealth += 5;

	//Enforce that the health is going to be 100 max
	if (iHealth >= 100)
		iHealth = 100;

	//Set health
	set_user_health(id, iHealth);
	if (iKillstreak_fast_heal[id])
		set_task(0.01, "killstreak_fast_heal", id);
}

//--------------------------------
// Stopper Functions {{{1

public killstreak_stop_slow_heal(id) {
	iKillstreak_slow_heal[id] = 0;
}

public killstreak_stop_fast_heal(id) {
	iKillstreak_fast_heal[id] = 0;
}

public killstreak_stop_2x(id) {
	iKillstreak_2x[id] = 0;
}

public killstreak_stop_4x(id) {
	iKillstreak_4x[id] = 0;
}
