-- =========================================================================================
--   _______    ___      .______     .___________.
--  |   ____|  /   \     |   _  \    |           |
--  |  |__    /  ^  \    |  |_)  |   `---|  |----`
--  |   __|  /  /_\  \   |      /        |  |     
--  |  |    /  _____  \  |  |\  \----.   |  |     
--  |__|   /__/     \__\ | _| `._____|   |__|     
--
--  F.A.R.T. - Flying Asset Relocation Tool
--  Map-Marker Based Tanker Re-routing Script
--  By NotGeorge
--  Version: 1.0
-- =========================================================================================
--
--  WHAT IT DOES:
--  F.A.R.T. allows you to dynamically reposition Tankers (and other orbiting AI) 
--  mid-mission using F10 Map Markers, without breaking their tasks. It also draws 
--  their current tracks directly onto the F10 map.
--
--  HOW TO SETUP IN THE MISSION EDITOR:
--  1. Place your AI aircraft (e.g., a Tanker named "ARCO-1").
--  2. Give it a standard route with "Tanker" and "Orbit" tasks.
--  3. (Optional but recommended) Name the start of its orbit waypoint "TRK1" 
--     and the end of its orbit waypoint "TRK2". This saves its "Default" track.
--  4. Open the Triggers menu. Create a trigger: 
--     ONCE -> TIME MORE (5) -> DO SCRIPT FILE (Load this FART.lua file).
--
--  HOW TO USE IN-GAME (F10 MAP MARKERS):
--  Place a map marker anywhere on the F10 map and type one of the following commands:
--
--  Command 1: The Quick Move
--  Syntax:  <GroupName>
--  Example: ARCO-1
--  Result:  Moves ARCO-1's track to the marker. It will use the altitude, heading, 
--           and leg length of its default TRK1/TRK2 track. If no default track 
--           exists, it defaults to its current altitude, 180 heading, and 20nm legs.
--
--  Command 2: The Custom Track
--  Syntax:  <GroupName> <Altitude> <Heading> <Leg_Length>
--  Example: ARCO-1 25000 090 30
--  Result:  Moves ARCO-1 to the marker, sets altitude to 25,000ft, establishes a 
--           090-degree heading, and makes the racetrack 30 nautical miles long.
--
--  Command 3: Reset to Default
--  Syntax:  <GroupName> DEFAULT
--  Example: ARCO-1 DEFAULT
--  Result:  Sends ARCO-1 back to its original TRK1/TRK2 route defined in the 
--           Mission Editor.
-- =========================================================================================

local TankerManager = {
    markIdCounter = 10000,
    activeDrawings = {},
    defaultTracks = {}
}

function TankerManager.routeTanker(group, p1, p2, altMeters)
    local unit = group:getUnit(1)
    if not unit then return end
    
    local currentPos = unit:getPosition().p
    local vel = unit:getVelocity()
    local currentSpeed = math.sqrt(vel.x^2 + vel.y^2 + vel.z^2)
    if currentSpeed < 100 then currentSpeed = 200 end

    local newMission = {
        id = 'Mission',
        params = {
            route = {
                points = {
                    [1] = {
                        action = "Turning Point", alt = currentPos.y, alt_type = "BARO", speed = currentSpeed,
                        type = "Turning Point", x = currentPos.x, y = currentPos.z,
                    },
                    [2] = {
                        action = "Turning Point", alt = altMeters, alt_type = "BARO", speed = currentSpeed,
                        type = "Turning Point", x = p1.x, y = p1.z,
                        task = {
                            id = "ComboTask",
                            params = {
                                tasks = {
                                    [1] = { id = "Tanker", name = "Tanker", enabled = true, auto = false },
                                    [2] = { id = "Orbit", name = "Orbit", params = { pattern = "Race-Track", speed = currentSpeed, altitude = altMeters } }
                                }
                            }
                        }
                    },
                    [3] = {
                        action = "Turning Point", alt = altMeters, alt_type = "BARO", speed = currentSpeed,
                        type = "Turning Point", x = p2.x, y = p2.z,
                    }
                }
            }
        }
    }
    group:getController():setTask(newMission)
end

function TankerManager.drawMapTrack(groupName, coaId, p1, p2, hdgDeg, legNm, altMeters, isDefault, currentPos)
    if TankerManager.activeDrawings[groupName] then
        for _, id in ipairs(TankerManager.activeDrawings[groupName]) do
            trigger.action.removeMark(id)
        end
    end
    TankerManager.activeDrawings[groupName] = {}

    local function draw(drawCommand)
        TankerManager.markIdCounter = TankerManager.markIdCounter + 1
        drawCommand(TankerManager.markIdCounter)
        table.insert(TankerManager.activeDrawings[groupName], TankerManager.markIdCounter)
    end

    draw(function(id) trigger.action.lineToAll(coaId, id, p1, p2, {0, 1, 0, 1}, 1, true) end)

    -- 3. Draw Label
    local displayAlt = math.floor(altMeters / 0.3048)
    local hdgDisplay = math.floor(hdgDeg + 0.5)
    local legDisplay = math.floor(legNm * 10) / 10 -- Keep one decimal place
    
    local title = isDefault and (groupName .. "") or (groupName .. " Track")
    local labelText = title .. "\nAlt: " .. displayAlt .. "ft\nHdg: " .. hdgDisplay .. " / Leg: " .. legDisplay .. "nm"
    
    draw(function(id) trigger.action.textToAll(coaId, id, p1, {1, 1, 1, 1}, {0, 0, 0, 0.5}, 14, true, labelText) end)
end

function TankerManager:onEvent(event)
    if event.id == world.event.S_EVENT_MARK_CHANGE then
        if not event.text then return end

        local args = {}
        for word in string.gmatch(event.text, "%S+") do table.insert(args, word) end
        if #args == 0 then return end

        local groupName = args[1]
        local group = Group.getByName(groupName)

        if group and group:isExist() and group:getCategory() == Group.Category.AIRPLANE then
            local defaultTrack = TankerManager.defaultTracks[groupName]
            local coaId = group:getCoalition()
            local unit = group:getUnit(1)
            if not unit then return end
            local currentPos = unit:getPosition().p

            if args[2] and string.upper(args[2]) == "DEFAULT" then
                if not defaultTrack then
                    trigger.action.outText("ATC: No default TRK1/TRK2 track configured for " .. groupName, 10)
                    trigger.action.removeMark(event.idx)
                    return
                end
                
                TankerManager.routeTanker(group, defaultTrack.p1, defaultTrack.p2, defaultTrack.altMeters)
                TankerManager.drawMapTrack(groupName, coaId, defaultTrack.p1, defaultTrack.p2, defaultTrack.hdgDeg, defaultTrack.legNm, defaultTrack.altMeters, true, currentPos)
                
                trigger.action.outText("ATC: " .. groupName .. " returning to DEFAULT track.", 10)
                trigger.action.removeMark(event.idx)
                return
            end

            local altFeet = tonumber(args[2])
            local hdgDeg = tonumber(args[3])
            local legNm = tonumber(args[4])

            local finalAltMeters, finalHdg, finalLeg

            if defaultTrack then
                finalAltMeters = altFeet and (altFeet * 0.3048) or defaultTrack.altMeters
                finalHdg = hdgDeg or defaultTrack.hdgDeg
                finalLeg = legNm or defaultTrack.legNm
            else
                finalAltMeters = altFeet and (altFeet * 0.3048) or currentPos.y 
                finalHdg = hdgDeg or 180
                finalLeg = legNm or 20
            end

            local p1 = {x = event.pos.x, y = finalAltMeters, z = event.pos.z}
            local hdgRad = math.rad(finalHdg)
            local distMeters = finalLeg * 1852
            
            local p2 = {
                x = p1.x + (math.cos(hdgRad) * distMeters),
                y = finalAltMeters,
                z = p1.z + (math.sin(hdgRad) * distMeters)
            }

            TankerManager.routeTanker(group, p1, p2, finalAltMeters)
            TankerManager.drawMapTrack(groupName, coaId, p1, p2, finalHdg, finalLeg, finalAltMeters, false, currentPos)
            
            trigger.action.outText("ATC: " .. groupName .. " is pushing to new track.", 10)
            trigger.action.removeMark(event.idx)
        end
    end
end

function TankerManager.init()
    for coa_name, coa_data in pairs(env.mission.coalition) do
        if type(coa_data) == 'table' and coa_data.country then
            for _, country in ipairs(coa_data.country) do
                if country.plane and country.plane.group then
                    for _, groupData in ipairs(country.plane.group) do
                        
                        local trk1, trk2
                        if groupData.route and groupData.route.points then
                            for _, pt in ipairs(groupData.route.points) do
                                if pt.name == "TRK1" then trk1 = pt end
                                if pt.name == "TRK2" then trk2 = pt end
                            end
                        end
                        
                        if trk1 and trk2 then
                            local dx = trk2.x - trk1.x
                            local dz = trk2.y - trk1.y
                            
                            local hdgRad = math.atan2(dz, dx)
                            local hdgDeg = math.deg(hdgRad)
                            if hdgDeg < 0 then hdgDeg = hdgDeg + 360 end
                            
                            local distMeters = math.sqrt(dx^2 + dz^2)
                            local legNm = distMeters / 1852
                            
                            local groupName = groupData.name
                            TankerManager.defaultTracks[groupName] = {
                                p1 = {x = trk1.x, y = trk1.alt, z = trk1.y},
                                p2 = {x = trk2.x, y = trk2.alt, z = trk2.y},
                                hdgDeg = hdgDeg,
                                legNm = legNm,
                                altMeters = trk1.alt
                            }
                            
                            local coaEnum = coalition.side[string.upper(coa_name)]
                            TankerManager.drawMapTrack(groupName, coaEnum, TankerManager.defaultTracks[groupName].p1, TankerManager.defaultTracks[groupName].p2, hdgDeg, legNm, trk1.alt, true, nil)
                        end
                    end
                end
            end
        end
    end
end

world.addEventHandler(TankerManager)
TankerManager.init()
env.info("F.A.R.T. Loaded")