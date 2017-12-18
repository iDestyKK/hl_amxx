/*
 * Quick-ass Instant Respawn Plugin for Half-Life
 *
 *  Description:
 *      Allows a player to instantly respawn (Well, 0.1 seconds apart) upon
 *      death. This is mainly to allow servers to have much faster paced games.
 *
 *  Author:
 *      Clara Nguyen (@iDestyKK)
 */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN_NAME    "Instant Respawn"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR  "iDestyKK"

public plugin_init() {
	register_plugin(
		PLUGIN_NAME,
		PLUGIN_VERSION,
		PLUGIN_AUTHOR
	);

    register_event("DeathMsg", "respawn_trigger", "a");
}

public respawn_trigger() {
    new iVictim;
    iVictim = read_data(2);

    if (is_user_connected(iVictim)) {
        //Make the engine think player is spawning
        set_pev(iVictim, pev_deadflag, DEAD_RESPAWNABLE);

        //Actual Spawn
        set_task(0.1, "respawn", iVictim);
    }
}

public respawn(id) {
    if (is_user_connected(id)) {
        dllfunc(DLLFunc_Spawn, id);
    }
}
