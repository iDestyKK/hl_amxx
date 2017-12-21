/*
 * Force Demo recording for Half-Life
 *
 * Description:
 *     Allows an admin (well, for now it allows anyone) to force all clients to
 *     demo record the moment they join the server. The filename will be based
 *     on the current date and time, as well as the current map. This is
 *     because I get pissed off whenever my client fails to start demo
 *     recording for one reason or another.
 *
 *     The plugin takes advantage of the "record" command, built straight into
 *     the engine. When called multiple times, it will refuse to work if the
 *     game is already recording. So we can call it as many times as we want
 *     to ensure recording and it'll only count the earliest call.
 *
 *     Generates files like "2017_12_21_11_51_23_crossfire.dem".
 *
 * Author:
 *     Clara Nguyen (@iDestyKK)
 */

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>

#define PLUGIN_NAME    "Force Demo Recording"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR  "iDestyKK"

public plugin_init() {
	register_plugin(
		PLUGIN_NAME,
		PLUGIN_VERSION,
		PLUGIN_AUTHOR
	);

	RegisterHam(Ham_Spawn, "player", "force_record", 1);
}

public force_record(id) {
	new current_time[9], current_date[11], current_map[33];

	get_time("%H_%M_%S", current_time, 8);
	get_time("%Y_%m_%d", current_date, 10);
	get_mapname(current_map, 32);

	client_cmd(0, "record %s_%s_%s", current_date, current_time, current_map);
}

public client_putinserver(id) {
	//Yes
	force_record(id);
}

public client_connect(id) {
	//Yes
	for (new Float:i = 0.1; i < 5.0; i += 0.1)
		set_task(i, "force_record");
}
