#define AIRLOCK_WIRE_IDSCAN 1
#define AIRLOCK_WIRE_MAIN_POWER1 2
#define AIRLOCK_WIRE_MAIN_POWER2 3
#define AIRLOCK_WIRE_DOOR_BOLTS 4
#define AIRLOCK_WIRE_BACKUP_POWER1 5
#define AIRLOCK_WIRE_BACKUP_POWER2 6
#define AIRLOCK_WIRE_POWER_ASSIST 7
#define AIRLOCK_WIRE_AI_CONTROL 8
#define AIRLOCK_WIRE_ELECTRIFY 9

/*
 *	Airlock -- an airlock door.
 *
 */

/*
	New methods:
	pulse - sends a pulse into a wire for hacking purposes
	cut - cuts a wire and makes any necessary state changes
	mend - mends a wire and makes any necessary state changes
	isWireColorCut - returns 1 if that color wire is cut, or 0 if not
	isWireCut - returns 1 if that wire (e.g. AIRLOCK_WIRE_DOOR_BOLTS) is cut, or 0 if not
	canAIControl - 1 if the AI can control the airlock, 0 if not (then check canAIHack to see if it can hack in)
	canAIHack - 1 if the AI can hack into the airlock to recover control, 0 if not. Also returns 0 if the AI does not *need* to hack it.
	arePowerSystemsOn - 1 if the main or backup power are functioning, 0 if not. Does not check whether the power grid is charged or an APC has equipment on or anything like that. (Check (stat & NOPOWER) for that)
	acceptsIDs - 1 if the airlock is accepting IDs, 0 if not
	isAllPowerCut - 1 if the main and backup power both have cut wires.
	regainMainPower - handles the effects of main power coming back on.
	loseMainPower - handles the effects of main power going offline. Usually (if one isn't already running) spawn a thread to count down how long it will be offline - counting down won't happen if main power was completely cut along with backup power, though, the thread will just sleep.
	loseBackupPower - handles the effects of backup power going offline.
	regainBackupPower - handles the effects of main power coming back on.
	canBoltsBeRaisedManually - 1 if bolts can be raised with a wrench. 
	shock - has a chance of electrocuting its target.
*/

//This generates the randomized airlock wire assignments for the game.
/proc/RandomAirlockWires()
	//to make this not randomize the wires, just set index to 1 and increment it in the flag for loop (after doing everything else).
	var/list/wires = list(0, 0, 0, 0, 0, 0, 0, 0, 0)
	airlockIndexToFlag = list(0, 0, 0, 0, 0, 0, 0, 0, 0)
	airlockIndexToWireColor = list(0, 0, 0, 0, 0, 0, 0, 0, 0)
	airlockWireColorToIndex = list(0, 0, 0, 0, 0, 0, 0, 0, 0)
	var/flagIndex = 1
	for (var/flag=1, flag<512, flag+=flag)
		var/valid = 0
		while (!valid)
			var/colorIndex = rand(1, 9)
			if (wires[colorIndex]==0)
				valid = 1
				wires[colorIndex] = flag
				airlockIndexToFlag[flagIndex] = flag
				airlockIndexToWireColor[flagIndex] = colorIndex
				airlockWireColorToIndex[colorIndex] = flagIndex
		flagIndex+=1
	return wires

/* Example:
Airlock wires color -> flag are { 64, 128, 256, 2, 16, 4, 8, 32, 1 }.
Airlock wires color -> index are { 7, 8, 9, 2, 5, 3, 4, 6, 1 }.
Airlock index -> flag are { 1, 2, 4, 8, 16, 32, 64, 128, 256 }.
Airlock index -> wire color are { 9, 4, 6, 7, 5, 8, 1, 2, 3 }.
*/

obj/machinery/door/airlock
	name = "airlock"
	icon = 'Door1.dmi'
	var
		blocked = null			// true if door is welded shut
		powered = 1.0			// true if the test light is on
		locked = 0.0			// true if the door bolts are down (locked)
		wires = 511				// bitmask representing the 9 internal wires. Defaults to all connected
								// The wire conditions effect the "powered" and "locked" variables.
		
		aiControlDisabled = 0 			//If 1, AI control is disabled until the AI hacks back in and disables the lock. If 2, the AI has bypassed the lock. If -1, the control is enabled but the AI had bypassed it earlier, so if it is disabled again the AI would have no trouble getting back in.
		secondsMainPowerLost = 0 		//The number of seconds until power is restored.
		secondsBackupPowerLost = 0 		//The number of seconds until power is restored.
		spawnPowerRestoreRunning = 0 	//tells us if the power-restore thread is already running, so we don't start more than one.
		aiDisabledIdScanner = 0 		//Did the AI disable the ID scanner?
		aiDisabledPowerAssist = 0 		//Did the AI disable power assist?
		aiHacking = 0 					//Is the AI hacking back into the airlock after having its access blocked?
		secondsElectrified = 0			//How many seconds remain until the door is no longer electrified. -1 if it is permanently electrified until someone fixes it.

/*
About the new airlock wires panel:
*	An airlock wire dialog can be accessed by the normal way or by using wirecutters or a multitool on the door while the wire-panel is open. This would show the following wires, which you can either wirecut/mend or send a multitool pulse through. There are 9 wires.
*		one wire from the ID scanner. Sending a pulse through this flashes the red light on the door (if the door has power). If you cut this wire, the door will stop recognizing valid IDs. (If the door has 0000 access, it still opens and closes, though)
*		two wires for power. Sending a pulse through either one causes a breaker to trip, disabling the door for 10 seconds if backup power is connected, or 1 minute if not (or until backup power comes back on, whichever is shorter). Cutting either one disables the main door power, but unless backup power is also cut, the backup power re-powers the door in 10 seconds. While unpowered, the door may be crowbarred open, but bolts-raising will not work. Cutting these wires may electrocute the user.
*		one wire for door bolts. Sending a pulse through this drops door bolts (whether the door is powered or not). Cutting this wire also drops the door bolts, and mending it does not raise them. If the wire is cut, trying to raise the door bolts will not work.
*		two wires for backup power. Sending a pulse through either one causes a breaker to trip, but this does not disable it unless main power is down too (in which case it is disabled for 1 minute or however long it takes main power to come back, whichever is shorter). Cutting either one disables the backup door power (allowing it to be crowbarred open, but disabling bolts-raising), but may electocute the user.
*		one wire for power assist. Sending a pulse through this while the door has power makes it raise the door bolts. Cutting this prevents manual bolts-raising with a wrench from working.
*		one wire for AI control. Sending a pulse through this blocks AI control for a second or so (which is enough to see the AI control light on the panel dialog go off and back on again). Cutting this prevents the AI from controlling the door unless it has hacked the door through the power connection (which takes about a minute). If both main and backup power are cut, as well as this wire, then the AI cannot operate or hack the door at all.
*		one wire for electrifying the door. Sending a pulse through this electrifies the door for 30 seconds. Cutting this wire electrifies the door, so that the next person to touch the door without insulated gloves gets electrocuted. (Currently it is also STAYING electrified until someone mends the wire)
*/

	
	proc/pulse(var/wireColor)
		//var/wireFlag = airlockWireColorToFlag[wireColor] //not used in this function
		var/wireIndex = airlockWireColorToIndex[wireColor]
		switch(wireIndex)
			if(AIRLOCK_WIRE_IDSCAN)
				//Sending a pulse through this flashes the red light on the door (if the door has power).
				if ((src.arePowerSystemsOn()) && (!(stat & NOPOWER)))
					flick("door_deny", src)
			if (AIRLOCK_WIRE_MAIN_POWER1 || AIRLOCK_WIRE_MAIN_POWER2)
				//Sending a pulse through either one causes a breaker to trip, disabling the door for 10 seconds if backup power is connected, or 1 minute if not (or until backup power comes back on, whichever is shorter). 
				src.loseMainPower()
			if (AIRLOCK_WIRE_DOOR_BOLTS)
				//one wire for door bolts. Sending a pulse through this drops door bolts (whether the door is powered or not).
				if (src.locked!=1)
					src.locked = 1
				else
					usr << "You hear a click from the bottom of the door."
			if (AIRLOCK_WIRE_BACKUP_POWER1 || AIRLOCK_WIRE_BACKUP_POWER2)
				//two wires for backup power. Sending a pulse through either one causes a breaker to trip, but this does not disable it unless main power is down too (in which case it is disabled for 1 minute or however long it takes main power to come back, whichever is shorter). 
				src.loseBackupPower()
			if (AIRLOCK_WIRE_AI_CONTROL)
				if (src.aiControlDisabled == 0)
					src.aiControlDisabled = 1
				else if (src.aiControlDisabled == -1)
					src.aiControlDisabled = 2
				src.updateDialog()
				spawn(10)
					if (src.aiControlDisabled == 1)
						src.aiControlDisabled = 0
					else if (src.aiControlDisabled == 2)
						src.aiControlDisabled = -1
					src.updateDialog()
			if (AIRLOCK_WIRE_POWER_ASSIST)
				//one wire for power assist. Sending a pulse through this while the door has power makes it raise the door bolts. Cutting this prevents manual bolts-raising with a wrench from working.
				if (arePowerSystemsOn())
					if (src.locked==1)
						src.locked=0
						src.updateDialog()
					else
						usr << "You hear a click or thump sound from inside the door."
			if (AIRLOCK_WIRE_ELECTRIFY)
				//one wire for electrifying the door. Sending a pulse through this electrifies the door for 30 seconds.
				if (src.secondsElectrified!=-1)
					if (src.secondsElectrified==0)
						src.secondsElectrified = 30
						spawn(10)
							while (src.secondsElectrified>0)
								src.secondsElectrified-=1
								if (src.secondsElectrified<0)
									src.secondsElectrified = 0
								src.updateDialog()
								sleep(10)
						
				

	proc/cut(var/wireColor)
		var/wireFlag = airlockWireColorToFlag[wireColor]
		var/wireIndex = airlockWireColorToIndex[wireColor]
		wires &= ~wireFlag
		switch(wireIndex)
			if(AIRLOCK_WIRE_MAIN_POWER1 || AIRLOCK_WIRE_MAIN_POWER2)
				//Cutting either one disables the main door power, but unless backup power is also cut, the backup power re-powers the door in 10 seconds. While unpowered, the door may be crowbarred open, but bolts-raising will not work. Cutting these wires may electocute the user.
				src.loseMainPower()
				src.shock(usr, 50)
				src.updateDialog()
			if (AIRLOCK_WIRE_DOOR_BOLTS)
				//Cutting this wire also drops the door bolts, and mending it does not raise them. (This is what happens now, except there are a lot more wires going to door bolts at present)
				if (src.locked!=1)
					src.locked = 1
				src.updateDialog()
			if (AIRLOCK_WIRE_BACKUP_POWER1 || AIRLOCK_WIRE_BACKUP_POWER2)
				//Cutting either one disables the backup door power (allowing it to be crowbarred open, but disabling bolts-raising), but may electocute the user.
				src.loseBackupPower()
				src.shock(usr, 50)
				src.updateDialog()
			if (AIRLOCK_WIRE_AI_CONTROL)
				//one wire for AI control. Cutting this prevents the AI from controlling the door unless it has hacked the door through the power connection (which takes about a minute). If both main and backup power are cut, as well as this wire, then the AI cannot operate or hack the door at all.
				//aiControlDisabled: If 1, AI control is disabled until the AI hacks back in and disables the lock. If 2, the AI has bypassed the lock. If -1, the control is enabled but the AI had bypassed it earlier, so if it is disabled again the AI would have no trouble getting back in.
				if (src.aiControlDisabled == 0)
					src.aiControlDisabled = 1
				else if (src.aiControlDisabled == -1)
					src.aiControlDisabled = 2
				src.updateDialog()
			if (AIRLOCK_WIRE_ELECTRIFY)
				//Cutting this wire electrifies the door, so that the next person to touch the door without insulated gloves gets electrocuted.
				if (src.secondsElectrified != -1)
					src.secondsElectrified = -1
					
			
	proc/mend(var/wireColor)
		var/wireFlag = airlockWireColorToFlag[wireColor]
		var/wireIndex = airlockWireColorToIndex[wireColor] //not used in this function
		wires |= wireFlag
		switch(wireIndex)
			if(AIRLOCK_WIRE_MAIN_POWER1 || AIRLOCK_WIRE_MAIN_POWER2)
				if ((!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER2)))
					src.regainMainPower()
					src.shock(usr, 50)
					src.updateDialog()
			if (AIRLOCK_WIRE_BACKUP_POWER1 || AIRLOCK_WIRE_BACKUP_POWER2)
				if ((!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER2)))
					src.regainBackupPower()
	
	
	
	
	
					src.shock(usr, 50)
					src.updateDialog()
			if (AIRLOCK_WIRE_AI_CONTROL)
				//one wire for AI control. Cutting this prevents the AI from controlling the door unless it has hacked the door through the power connection (which takes about a minute). If both main and backup power are cut, as well as this wire, then the AI cannot operate or hack the door at all.
				//aiControlDisabled: If 1, AI control is disabled until the AI hacks back in and disables the lock. If 2, the AI has bypassed the lock. If -1, the control is enabled but the AI had bypassed it earlier, so if it is disabled again the AI would have no trouble getting back in.
				if (src.aiControlDisabled == 1)
					src.aiControlDisabled = 0
				else if (src.aiControlDisabled == 2)
					src.aiControlDisabled = -1
				src.updateDialog()
			if (AIRLOCK_WIRE_ELECTRIFY)
				if (src.secondsElectrified == -1)
					src.secondsElectrified = 0
					
	proc/isElectrified()
		return src.secondsElectrified!=0
			
	proc/isWireColorCut(var/wireColor)
		var/wireFlag = airlockWireColorToFlag[wireColor]
		return ((src.wires & wireFlag) == 0)

	proc/isWireCut(var/wireIndex)
		var/wireFlag = airlockIndexToFlag[wireIndex]
		return ((src.wires & wireFlag) == 0)

	proc/canAIControl()
		return ((src.aiControlDisabled!=1) && (!src.isAllPowerCut()));
			
	proc/canAIHack()
		return ((src.aiControlDisabled==1) && (!src.isAllPowerCut()));

	proc/arePowerSystemsOn()
		return (src.secondsMainPowerLost==0 || src.secondsBackupPowerLost==0)
	
	acceptsIDs()
		return !(src.isWireCut(AIRLOCK_WIRE_IDSCAN) || aiDisabledIdScanner)
	
	proc/isAllPowerCut()
		var/retval=0
		if (src.isWireCut(AIRLOCK_WIRE_MAIN_POWER1) || src.isWireCut(AIRLOCK_WIRE_MAIN_POWER2))
			if (src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER1) || src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER2))
				retval=1
		return retval
	
	proc/regainMainPower()
		if (src.secondsMainPowerLost > 0)
			src.secondsMainPowerLost = 0
	
	proc/loseMainPower()
		if (src.secondsMainPowerLost <= 0)
			src.secondsMainPowerLost = 60
			if (src.secondsBackupPowerLost < 10)
				src.secondsBackupPowerLost = 10
		if (!src.spawnPowerRestoreRunning)
			src.spawnPowerRestoreRunning = 1
			spawn(0)
				var/cont = 1
				while (cont)
					sleep(10)
					cont = 0
					if (src.secondsMainPowerLost>0)
						if ((!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER2)))
							src.secondsMainPowerLost -= 1
							src.updateDialog()
						cont = 1
						
					if (src.secondsBackupPowerLost>0)
						if ((!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER2)))
							src.secondsBackupPowerLost -= 1
							src.updateDialog()
						cont = 1
				src.spawnPowerRestoreRunning = 0
				src.updateDialog()
				
	proc/loseBackupPower()
		if (src.secondsBackupPowerLost < 60)
			src.secondsBackupPowerLost = 60
	
	proc/regainBackupPower()
		if (src.secondsBackupPowerLost > 0)
			src.secondsBackupPowerLost = 0
	
	proc/canBoltsBeRaisedManually()
		return (!src.isWireCut(AIRLOCK_WIRE_POWER_ASSIST)) && arePowerSystemsOn() && (!isWireCut(AIRLOCK_WIRE_DOOR_BOLTS))
	
	//borrowed from the grille's get_connection
	proc/get_connection()
		var/turf/T = src.loc
		if(!istype(T, /turf/station/floor))
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
			return
	
		for(var/obj/cable/C in T)
			if(C.d1 == 0)
				return C.netnum
	
		return 0
			
	// shock user with probability prb (if all connections & power are working)
	// returns 1 if shocked, 0 otherwise
	// The preceding comment was borrowed from the grille's shock script
	proc/shock(mob/user, prb, bypassPowerCheck)
	
		if(!prob(prb))
			return 0
		var/net = null
		if (!bypassPowerCheck)
			net = get_connection()		// find the powernet of the connected cable
	
			if(!net)		// cable is unpowered
				return 0
	
		return src.electrocute(user, prb, net)
	
	proc/updateIconState()
		var/d = src.density
		if (src.blocked)			// true if welded shut
			d = "l"
		src.icon_state = text("[]door[]", (src.p_open ? "o_" : null), d)
		return
	
	attack_ai(mob/user as mob)
		if (!src.canAIControl())
			if (src.canAIHack())
				src.hack(user)
				return
		
		//Separate interface for the AI.
		user.machine = src
		var/t1 = text("<B>Airlock Control</B><br>\n")
		if (src.secondsMainPowerLost > 0)
			if ((!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER2)))
				t1 += text("Main power is offline for [] seconds.<br>\n", src.secondsMainPowerLost)
			else
				t1 += text("Main power is offline indefinitely.<br>\n")
		else
			t1 += text("Main power is online.")
		
		if (src.secondsBackupPowerLost > 0)
			if ((!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER2)))
				t1 += text("Backup power is offline for [] seconds.<br>\n", src.secondsBackupPowerLost)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
			else
				t1 += text("Backup power is offline indefinitely.<br>\n")
		else if (src.secondsMainPowerLost > 0)
			t1 += text("Backup power is online.")
		else
			t1 += text("Backup power is offline, but will turn on if main power fails.")
		t1 += "<br>\n"
		
		if (src.isWireCut(AIRLOCK_WIRE_IDSCAN))
			t1 += text("IdScan wire is cut.<br>\n")
		else if (src.arePowerSystemsOn() && (!(stat & NOPOWER)))
			if (src.aiDisabledIdScanner)
				t1 += text("IdScan disabled. <A href='?src=\ref[];aiEnable=1'>Enable?</a><br>\n", src)
			else
				t1 += text("IdScan enabled. <A href='?src=\ref[];aiDisable=1'>Disable?</a><br>\n", src)
		else
			if (src.aiDisabledIdScanner)
				t1 += text("IdScan disabled. Cannot enable - power is off.<br>\n")
			else
				t1 += text("IdScan enabled. Cannot disable - power is off.<br>\n")
		if (src.isWireCut(AIRLOCK_WIRE_MAIN_POWER1))
			t1 += text("Main Power Input wire is cut.<br>\n")
		if (src.isWireCut(AIRLOCK_WIRE_MAIN_POWER2))
			t1 += text("Main Power Output wire is cut.<br>\n")
		if (src.secondsMainPowerLost == 0)
			t1 += text("<A href='?src=\ref[];aiDisable=2'>Temporarily disrupt main power?</a>.<br>\n", src)
		if (src.secondsBackupPowerLost == 0)
			t1 += text("<A href='?src=\ref[];aiDisable=3'>Temporarily disrupt backup power?</a>.<br>\n", src)
			
		if (src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER1))
			t1 += text("Backup Power Input wire is cut.<br>\n")
		if (src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER2))
			t1 += text("Backup Power Output wire is cut.<br>\n")
		if (src.isWireCut(AIRLOCK_WIRE_DOOR_BOLTS))
			t1 += text("Door bolt drop wire is cut.<br>\n")
		else if (!src.locked)
			t1 += text("Door bolts are up. <A href='?src=\ref[];aiDisable=4'>Drop them?</a><br>\n", src)
		else if (src.isWireCut(AIRLOCK_WIRE_POWER_ASSIST))
			t1 += text("Power assist wire is cut.<br>\n")
		else
			t1 += text("Door bolts are down.")
			if (src.arePowerSystemsOn() && (!(stat & NOPOWER)))
				t1 += text(" <A href='?src=\ref[];aiEnable=4'>Raise?</a><br>\n", src)
			else
				t1 += text(" Cannot raise door bolts due to power failure.<br>\n")
		if (src.isWireCut(AIRLOCK_WIRE_ELECTRIFY))
			t1 += text("Electrification wire is cut.<br>\n")
		if (src.secondsElectrified==-1)
			t1 += text("Door is electrified indefinitely. <A href='?src=\ref[];aiDisable=5'>Un-electrify it?</a><br>\n", src)
		else if (src.secondsElectrified>0)
			t1 += text("Door is electrified temporarily ([] seconds). <A href='?src=\ref[];aiDisable=5'>Un-electrify it?</a><br>\n", src.secondsElectrified, src)
		else
			t1 += text("Door is not electrified. <A href='?src=\ref[];aiEnable=5'>Electrify it for 30 seconds?</a> Or, <A href='?src=\ref[];aiEnable=6'>Electrify it indefinitely until someone cancels the electrification?</a><br>\n", src, src)
		
		if (src.blocked)
			t1 += text("Door appears to have been welded shut.<br>\n")
		else if (!src.locked)
			if (src.density)
				if (src.arePowerSystemsOn() && (!(stat & NOPOWER)))
					t1 += text("<A href='?src=\ref[];aiEnable=7'>Open door</a><br>\n", src)
				else
					t1 += text("Cannot open door due to power failure.<br>\n")
			else
				if (src.arePowerSystemsOn() && (!(stat & NOPOWER)))
					t1 += text("<A href='?src=\ref[];aiDisable=7'>Close door</a><br>\n", src)
				else
					t1 += text("Cannot close door due to power failure.<br>\n")
		
		t1 += text("<p><a href='?src=\ref[];close=1'>Close</a></p>\n", src)
		user << browse(t1, "window=airlock")
	
	//aiDisable - 1 idscan, 2 disrupt main power, 3 disrupt backup power, 4 drop door bolts, 5 un-electrify door, 7 close door
	//aiEnable - 1 idscan, 4 raise door bolts, 5 electrify door for 30 seconds, 6 electrify door indefinitely, 7 open door
	
	
	proc/hack(mob/user as mob)
		if (src.aiHacking==0)
			src.aiHacking=1
			spawn(20)
				//TODO: Make this take a minute
				user << "Airlock AI control has been blocked. Beginning fault-detection."
				sleep(50)
				if (src.canAIControl())
					user << "Alert cancelled. Airlock control has been restored without our assistance."
					src.aiHacking=0
					return
				else if (!src.canAIHack())
					user << "We've lost our connection! Unable to hack airlock."
					src.aiHacking=0
					return
				user << "Fault confirmed: airlock control wire disabled or cut."
				sleep(20)
				user << "Attempting to hack into airlock. This may take some time."
				sleep(200)
				if (src.canAIControl())
					user << "Alert cancelled. Airlock control has been restored without our assistance."
					src.aiHacking=0
					return
				else if (!src.canAIHack())
					user << "We've lost our connection! Unable to hack airlock."
					src.aiHacking=0
					return
				user << "Upload access confirmed. Loading control program into airlock software."
				sleep(170)
				if (src.canAIControl())
					user << "Alert cancelled. Airlock control has been restored without our assistance."
					src.aiHacking=0
					return
				else if (!src.canAIHack())
					user << "We've lost our connection! Unable to hack airlock."
					src.aiHacking=0
					return
				user << "Transfer complete. Forcing airlock to execute program."
				sleep(50)
				//disable blocked control
				src.aiControlDisabled = 2
				user << "Receiving control information from airlock."
				sleep(10)
				//bring up airlock dialog
				src.aiHacking = 0
				src.attack_ai(user)
				
	
	// Monkey interact same a human

	attack_paw(mob/user)
		return src.attack_hand(user)
	
	// Human interact. If the door panel is open, show the wire interaction window. Otherwise, do standard door interaction.

	attack_hand(mob/user)
		if (!istype(usr, /mob/ai))
			if (src.isElectrified())
				if (src.shock(user, 100))
					return
		
		if (src.p_open)
			user.machine = src
			var/t1 = text("<B>Access Panel</B><br>\n")
			
			//t1 += text("[]: ", airlockFeatureNames[airlockWireColorToIndex[9]])
			t1 += text("Orange Wire: [] []<br>\n", (src.wires & airlockWireColorToFlag[9] ? text("<A href='?src=\ref[];wires=9'>Cut Wire</A>", src) : text("<A href='?src=\ref[];wires=9'>Mend Wire</A>", src)), (src.wires & airlockWireColorToFlag[9] ? text(" or <A href='?src=\ref[];pulse=9'>Pulse Wire</A>", src) : ""))
			
			
			//t1 += text("[]: ", airlockFeatureNames[airlockWireColorToIndex[8]])
			t1 += text("Dark Red Wire:   [] []<br>\n", (src.wires & airlockWireColorToFlag[8] ? text("<A href='?src=\ref[];wires=8'>Cut Wire</A>", src) : text("<A href='?src=\ref[];wires=8'>Mend Wire</A>", src)), (src.wires & airlockWireColorToFlag[8] ? text(" or <A href='?src=\ref[];pulse=8'>Pulse Wire</A>", src) : ""))
			
			//t1 += text("[]: ", airlockFeatureNames[airlockWireColorToIndex[7]])
			t1 += text("White Wire:  [] []<br>\n", (src.wires & airlockWireColorToFlag[7] ? text("<A href='?src=\ref[];wires=7'>Cut Wire</A>", src) : text("<A href='?src=\ref[];wires=7'>Mend Wire</A>", src)), (src.wires & airlockWireColorToFlag[7] ? text(" or <A href='?src=\ref[];pulse=7'>Pulse Wire</A>", src) : ""))
			
			//t1 += text("[]: ", airlockFeatureNames[airlockWireColorToIndex[6]])
			t1 += text("Yellow Wire: [] []<br>\n", (src.wires & airlockWireColorToFlag[6] ? text("<A href='?src=\ref[];wires=6'>Cut Wire</A>", src) : text("<A href='?src=\ref[];wires=6'>Mend Wire</A>", src)), (src.wires & airlockWireColorToFlag[6] ? text(" or <A href='?src=\ref[];pulse=6'>Pulse Wire</A>", src) : ""))
			
			//t1 += text("[]: ", airlockFeatureNames[airlockWireColorToIndex[5]])
			t1 += text("Red Wire:   [] []<br>\n", (src.wires & airlockWireColorToFlag[5] ? text("<A href='?src=\ref[];wires=5'>Cut Wire</A>", src) : text("<A href='?src=\ref[];wires=5'>Mend Wire</A>", src)), (src.wires & airlockWireColorToFlag[5] ? text(" or <A href='?src=\ref[];pulse=5'>Pulse Wire</A>", src) : ""))
			
			//t1 += text("[]: ", airlockFeatureNames[airlockWireColorToIndex[4]])
			t1 += text("Blue Wire:  [] []<br>\n", (src.wires & airlockWireColorToFlag[4] ? text("<A href='?src=\ref[];wires=4'>Cut Wire</A>", src) : text("<A href='?src=\ref[];wires=4'>Mend Wire</A>", src)), (src.wires & airlockWireColorToFlag[4] ? text(" or <A href='?src=\ref[];pulse=4'>Pulse Wire</A>", src) : ""))
			
			//t1 += text("[]: ", airlockFeatureNames[airlockWireColorToIndex[3]])
			t1 += text("Green Wire: [] []<br>\n", (src.wires & airlockWireColorToFlag[3] ? text("<A href='?src=\ref[];wires=3'>Cut Wire</A>", src) : text("<A href='?src=\ref[];wires=3'>Mend Wire</A>", src)), (src.wires & airlockWireColorToFlag[3] ? text(" or <A href='?src=\ref[];pulse=3'>Pulse Wire</A>", src) : ""))
			
			//t1 += text("[]: ", airlockFeatureNames[airlockWireColorToIndex[2]])
			t1 += text("Grey Wire:   [] []<br>\n", (src.wires & airlockWireColorToFlag[2] ? text("<A href='?src=\ref[];wires=2'>Cut Wire</A>", src) : text("<A href='?src=\ref[];wires=2'>Mend Wire</A>", src)), (src.wires & airlockWireColorToFlag[2] ? text(" or <A href='?src=\ref[];pulse=2'>Pulse Wire</A>", src) : ""))
			
			//t1 += text("[]: ", airlockFeatureNames[airlockWireColorToIndex[1]])
			t1 += text("Black Wire:  [] []<br>\n", (src.wires & airlockWireColorToFlag[1] ? text("<A href='?src=\ref[];wires=1'>Cut Wire</A>", src) : text("<A href='?src=\ref[];wires=1'>Mend Wire</A>", src)), (src.wires & airlockWireColorToFlag[1] ? text(" or <A href='?src=\ref[];pulse=1'>Pulse Wire</A>", src) : ""))
			
			t1 += text("<br>\n[]<br>\n[]<br>\n[]", (src.locked ? "The door bolts have fallen!" : "The door bolts look up."), ((src.arePowerSystemsOn() && !(stat & NOPOWER)) ? "The test light is on." : "The test light is off!"), (src.aiControlDisabled==0 ? "The 'AI control allowed' light is on." : "The 'AI control allowed' light is off."))
			
			t1 += text("<p><a href='?src=\ref[];close=1'>Close</a></p>\n", src)
				
			user << browse(t1, "window=airlock")
		else
			..(user)
		return


	// Handle topic links from interaction window. Cut/join wires if clicking with wirecutters

	Topic(href, href_list)
		..()
		if (usr.stat || usr.restrained() )
			return
		if (href_list["close"])
			usr << browse(null, "window=airlock")
			if (usr.machine==src)
				usr.machine = null
	
	
	
				return
		if (!istype(usr, /mob/ai))
			if ((get_dist(src, usr) <= 1 && istype(src.loc, /turf)))
				usr.machine = src
				if (href_list["wires"])
					var/t1 = text2num(href_list["wires"])
					if (!( istype(usr.equipped(), /obj/item/weapon/wirecutters) ))
						usr << alert("You need wirecutters!", null, null, null, null, null)
						return
					if (!( src.p_open ))
						return
					if (src.isWireColorCut(t1))
						src.mend(t1)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
					else
						src.cut(t1)
				else if (href_list["pulse"])
					var/t1 = text2num(href_list["pulse"])
					if (!( istype(usr.equipped(), /obj/item/weapon/multitool) ))
						usr << alert("You need a multitool!", null, null, null, null, null)
						return
					if ((stat & NOPOWER))
						usr << "Due to a power failure, nothing happens."
						return
					if (!src.arePowerSystemsOn())
						usr << "Due to power being disrupted, nothing happens."
						return
					if (!( src.p_open ))
						usr << "You can't pulse it because the panel is closed."
						return
					if (src.isWireColorCut(t1))
						usr << "You can't pulse that wire - it being cut means a signal can't travel properly in it."
						return
	
	
					else
						src.pulse(t1)
			src.updateIconState()
			add_fingerprint(usr)
			src.updateDialog()
		else
			//AI
			if (!src.canAIControl())
				usr << "Airlock control connection failure!"
				return
			//aiDisable - 1 idscan, 2 disrupt main power, 3 disrupt backup power, 4 drop door bolts, 5 un-electrify door, 7 close door
			//aiEnable - 1 idscan, 4 raise door bolts, 5 electrify door for 30 seconds, 6 electrify door indefinitely, 7 open door
			if (href_list["aiDisable"])
				var/code = text2num(href_list["aiDisable"])
				switch (code)
					if (1)
						//disable idscan
						if (src.isWireCut(AIRLOCK_WIRE_IDSCAN))
							usr << "The IdScan wire has been cut - So, you can't disable it, but it is already disabled anyways."
						else if (src.aiDisabledIdScanner)
							usr << "You've already disabled the IdScan feature."
						else
							if (src.arePowerSystemsOn() && (!(stat & NOPOWER)))
								src.aiDisabledIdScanner = 1
							else
								usr << "Unable to disable ID Scanner due to power failure."
					if (2)
						//disrupt main power
						if (src.secondsMainPowerLost == 0)
							src.loseMainPower()
						else
							usr << "Main power is already offline."
					if (3)
						//disrupt backup power
						if (src.secondsBackupPowerLost == 0)
							src.loseBackupPower()
						else
							usr << "Backup power is already offline."
					if (4)
						//drop door bolts
						if (src.isWireCut(AIRLOCK_WIRE_DOOR_BOLTS))
							usr << "You can't drop the door bolts - The door bolt dropping wire has been cut."
						else if (src.locked!=1)
							src.locked = 1
					if (5)
						//un-electrify door
						if (src.isWireCut(AIRLOCK_WIRE_ELECTRIFY))
							usr += text("Can't un-electrify the airlock - The electrification wire is cut.<br>\n")
						else if (src.secondsElectrified==-1)
							src.secondsElectrified = 0
						else if (src.secondsElectrified>0)
							src.secondsElectrified = 0
					if (7)
						//close door
						if (src.blocked)
							usr << text("The airlock has been welded shut!<br>\n")
						else if (src.locked)
							usr << text("The door bolts are down!<br>\n")
						else if (!src.density)
							if (src.arePowerSystemsOn() && (!(stat & NOPOWER)))
								close()
							else
								usr << "Unable to close door due to power failure."
						else
							usr << text("The airlock is already closed.<br>\n")
					
			else if (href_list["aiEnable"])
				var/code = text2num(href_list["aiEnable"])
				switch (code)
					if (1)
						//enable idscan
						if (src.isWireCut(AIRLOCK_WIRE_IDSCAN))
							usr << "You can't enable IdScan - The IdScan wire has been cut."
						else if (src.aiDisabledIdScanner)
							if (src.arePowerSystemsOn() && (!(stat & NOPOWER)))
								src.aiDisabledIdScanner = 0
							else
								usr << "Unable to enable ID Scanner due to power failure."
						else
							usr << "The IdScan feature is not disabled."
					if (4)
						//raise door bolts
						if (src.isWireCut(AIRLOCK_WIRE_DOOR_BOLTS))
							usr << text("The door bolt drop wire is cut - you can't raise the door bolts.<br>\n")
						else if (!src.locked)
							usr << text("The door bolts are already up.<br>\n")
						else if (src.isWireCut(AIRLOCK_WIRE_POWER_ASSIST))
							usr << text("The door bolts are not coming up - The power assist wire has been cut.<br>\n")
						else
							if (src.arePowerSystemsOn() && (!(stat & NOPOWER)))
								src.locked = 0
							else
								usr << text("Cannot raise door bolts due to power failure.<br>\n")
					
					if (5)
						//electrify door for 30 seconds
						if (src.isWireCut(AIRLOCK_WIRE_ELECTRIFY))
							usr << text("The electrification wire has been cut.<br>\n")
						else if (src.secondsElectrified==-1)
							usr << text("The door is already indefinitely electrified. You'd have to un-electrify it before you can re-electrify it with a non-forever duration.<br>\n")
						else if (src.secondsElectrified!=0)
							usr << text("The door is already electrified. You can't re-electrify it while it's already electrified.<br>\n")
						else
							src.secondsElectrified = 30
							spawn(10)
								while (src.secondsElectrified>0)
									src.secondsElectrified-=1
									if (src.secondsElectrified<0)
										src.secondsElectrified = 0
									src.updateDialog()
									sleep(10)
					if (6)
						//electrify door indefinitely
						if (src.isWireCut(AIRLOCK_WIRE_ELECTRIFY))
							usr << text("The electrification wire has been cut.<br>\n")
						else if (src.secondsElectrified==-1)
							usr << text("The door is already indefinitely electrified.<br>\n")
						else if (src.secondsElectrified!=0)
							usr << text("The door is already electrified. You can't re-electrify it while it's already electrified.<br>\n")
						else
							src.secondsElectrified = -1
					if (7)
						//open door
						if (src.blocked)
							usr << text("The airlock has been welded shut!<br>\n")
						else if (src.locked)
							usr << text("The door bolts are down!<br>\n")
						else if (src.density)
							if (src.arePowerSystemsOn() && (!(stat & NOPOWER)))
								open()
							else
								usr << "Unable to open door due to power failure."
						else
							usr << text("The airlock is already opened.<br>\n")
				
			src.updateIconState()
			src.updateDialog()
		
		return
	
	// Attack with item.
	// If weldingtool (and door is closed), weld/unweld the door
	// If wrench, and door has test light on, unlock the door (raise bolts)
	// If screwdriver, toggle door panel open/closed
	// If crowbar, and door is closed, not welded, test light off and not locked, open the door
	// Otherwise, do standard door attackby()

	attackby(obj/item/weapon/C, mob/user)
		//world << text("airlock attackby src [] obj [] mob []", src, C, user)
		if (!istype(usr, /mob/ai))
			if (src.isElectrified())
				if (src.shock(user, 75))
					return
		
		src.add_fingerprint(user)
		if ((istype(C, /obj/item/weapon/weldingtool) && !( src.operating ) && src.density))
			var/obj/item/weapon/weldingtool/W = C
			if(W.welding)
				if (W.weldfuel > 2)
					W.weldfuel -= 2
				else
					user << "Need more welding fuel!"
					return
				if (!( src.blocked ))
					src.blocked = 1
				else
					src.blocked = null
				src.updateIconState()
				return
		else if (istype(C, /obj/item/weapon/wrench))
			if (src.p_open)
				if (src.arePowerSystemsOn())
					if (src.canBoltsBeRaisedManually())
						src.locked = null
					else
						user << alert("You strain to try to raise the door bolts, but the door's power assist seems to be disabled!", null, null, null, null, null)
				else
					user << alert("You need power assist!", null, null, null, null, null)
			src.updateIconState()
		else if (istype(C, /obj/item/weapon/screwdriver))
			src.p_open = !( src.p_open )
			src.updateIconState()
		else if (istype(C, /obj/item/weapon/wirecutters))
			return src.attack_hand(user)
		else if (istype(C, /obj/item/weapon/multitool))
			return src.attack_hand(user)
		else if (istype(C, /obj/item/weapon/crowbar))
			if ((src.density) && (!( src.blocked ) && !( src.operating ) && ((!src.arePowerSystemsOn()) || (stat & NOPOWER)) && !( src.locked )))
				spawn( 0 )
					src.operating = 1
					flick(text("[]doorc0", (src.p_open ? "o_" : null)), src)
					src.icon_state = text("[]door0", (src.p_open ? "o_" : null))
					sleep(15)
					src.density = 0
					src.opacity = 0
					var/turf/T = src.loc
					if (istype(T, /turf))
						T.updatecell = 1
						T.buildlinks()
					src.operating = 0
					return
			else
				if ((!src.density) && (!( src.blocked ) && !( src.operating ) && !( src.locked )))
					spawn( 0 )
						src.operating = 1
						flick(text("[]doorc1", (src.p_open ? "o_" : null)), src)
						src.icon_state = text("[]door1", (src.p_open ? "o_" : null))
						src.density = 1
						if (src.visible)
							src.opacity = 1
	
	
	
						var/turf/T = src.loc
						if (istype(T, /turf))
							T.updatecell = 0
							T.buildlinks()
						sleep(15)
						src.operating = 0
	
		else
			..()
		return
	
	open()
	
		if ((src.blocked || src.locked || (! src.arePowerSystemsOn() ) || (stat & NOPOWER)))
			return
		use_power(50)
		..()
		return
	
	close()
	
		if ((! src.arePowerSystemsOn() ) || (stat & NOPOWER))
			return
		use_power(50)
		..()
		var/turf/T = src.loc
		if (T)
			T.firelevel = 0
		return
