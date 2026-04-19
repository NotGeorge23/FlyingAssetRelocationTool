=========================================================================================
  _______    ___      .______     .___________.
 |   ____|  /   \     |   _  \    |           |
 |  |__    /  ^  \    |  |_)  |   `---|  |----`
 |   __|  /  /_\  \   |      /        |  |     
 |  |    /  _____  \  |  |\  \----.   |  |     
 |__|   /__/     \__\ | _| `._____|   |__|     
 
 F.A.R.T. - Flying Asset Relocation Tool
 Map-Marker Based Tanker Re-routing Script
 By NotGeorge
=========================================================================================

 WHAT IT DOES:
 F.A.R.T. allows you to dynamically reposition Tankers (and other orbiting AI) 
 mid-mission using F10 Map Markers, without breaking their tasks. It also draws 
 their current tracks directly onto the F10 map.

 HOW TO SETUP IN THE MISSION EDITOR:
 1. Place your AI aircraft (e.g., a Tanker named "ARCO-1").
 2. Give it a standard route with "Tanker" and "Orbit" tasks.
 3. (Optional but recommended) Name the start of its orbit waypoint "TRK1" 
    and the end of its orbit waypoint "TRK2". This saves its "Default" track.
 4. Open the Triggers menu. Create a trigger: 
    ONCE -> TIME MORE (5) -> DO SCRIPT FILE (Load this FART.lua file).

 HOW TO USE IN-GAME (F10 MAP MARKERS):
 Place a map marker anywhere on the F10 map and type one of the following commands:

 Command 1: The Quick Move
 Syntax:  <GroupName>
 Example: ARCO-1
 Result:  Moves ARCO-1's track to the marker. It will use the altitude, heading, 
          and leg length of its default TRK1/TRK2 track. If no default track 
          exists, it defaults to its current altitude, 180 heading, and 20nm legs.

 Command 2: The Custom Track
 Syntax:  <GroupName> <Altitude> <Heading> <Leg_Length>
 Example: ARCO-1 25000 090 30
 Result:  Moves ARCO-1 to the marker, sets altitude to 25,000ft, establishes a 
          090-degree heading, and makes the racetrack 30 nautical miles long.

 Command 3: Reset to Default
 Syntax:  <GroupName> DEFAULT
 Example: ARCO-1 DEFAULT
 Result:  Sends ARCO-1 back to its original TRK1/TRK2 route defined in the 
          Mission Editor.
=========================================================================================
