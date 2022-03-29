-- program to automatically takeoff and then at 20m output data into a csv file.  another issue i have is that the plane will turn on the runway which is really pissing me off
local output = io.open("E:\\Apps + Games\\X-Plane 11\\Resources\\plugins\\FlyWithLua\\Scripts\\output-f1-35ft.csv", "a")
local starttime, startpos, startWind, densityAlt, pressureAlt
local rotate_speed = 130
-- PA, time, speed, distance, Wind Dir, Wind Speed

local g = 9.81
local r_s = 287.058 -- https://aviation.stackexchange.com/questions/71962/what-formula-to-use-for-calculating-pressure-altitude
local p_0 = 1013.25
local t_0 = 288.15
local l = 0.0065
set("sim/operation/override/override_control_surfaces", 0)
dataref("AGL", "sim/flightmodel/position/y_agl")
dataref("PA", "sim/flightmodel/misc/h_ind")
dataref("time", "sim/time/total_running_time_sec")
dataref("speed", "sim/flightmodel/position/groundspeed")
dataref("Aircraft_x", "sim/flightmodel/position/local_x")
dataref("Aircraft_z", "sim/flightmodel/position/local_z")
dataref("windspeed_kn", "sim/weather/wind_speed_kt[0]")
dataref("winddir_deg", "sim/weather/wind_direction_degt[0]")
dataref("temp", "sim/weather/temperature_ambient_c")
dataref("pressure", "sim/weather/barometer_sealevel_inhg")
dataref("airspeed", "sim/flightmodel/position/indicated_airspeed")
dataref("parkbrake", "sim/cockpit2/controls/parking_brake_ratio", "writable")
dataref("mixture", "sim/aircraft/overflow/acf_drive_by_wire", "writable")
dataref("rpm", "sim/cockpit2/engine/indicators/engine_speed_rpm") --dataref("heading_select", "sim/cockpit/autopilot/heading_mag", "writable") -- risky
dataref("masterstickpitch", "toliss_airbus/smartCopilotSync/ATA27/MasterStickPitch", "writable") --set("sim/flightmodel/engine/ENGN_TRQ", 0) --mixture = 1 --yaw_damper = 1 --
dataref("flaprat", "sim/cockpit2/controls/flap_ratio", "writable")

engine = dataref_table("sim/cockpit2/engine/actuators/throttle_ratio")
throttle_input = dataref_table("AirbusFBW/throttle_input")
local changedElevator = true

function agl()
    --set("sim/dataref/override/override_engines", 1)
    --N_prop = 0
    --L_prop = 0
    if airspeed >= rotate_speed and changedElevator then
        masterstickpitch = 1
        XPLMSpeakString("Ro tar tay")
        set("sim/operation/override/override_control_surfaces", 1)
        set("sim/cockpit2/controls/yoke_pitch_ratio", 0.60)
        changedElevator = false
        set("sim/operation/override/override_control_surfaces", 0)
    end
    if AGL >= 10.668 then -- 35ft
        XPLMSpeakString("Above 35 feet")
        local endpos = {Aircraft_x, Aircraft_z}
        local endtime = time
        local totaltime = endtime - starttime
        distance = math.sqrt(math.abs((endpos[1] - startpos[1]) ^ 2) + math.abs((endpos[2] - startpos[2]) ^ 2))
        pcall(
            output:write(
                densityAlt,
                ",",
                startpressure,
                ",",
                starttemp,
                ",",
                distance,
                ",",
                totaltime,
                ",",
                speed,
                ",",
                startWind[1],
                ",",
                startWind[2],
                ",",
                rpm,
                ",",
                rotate_speed,
                "\n"
            )
        )
        pcall(output:close())
    end
end

function density_altitude(alt_setting) -- https://www.omnicalculator.com/physics/density-altitude#what-is-density-altitude
    -- H = 44.3308 - 42.2665 * ρ^0.234969
    -- ρ = (Pd / (Rd * T)) + (Pv / (Rv * T))
    dataref("rel_hum", "sim/weather/relative_humidity_sealevel_percent")
    dataref("oat_c", "sim/cockpit2/temperature/outside_air_temp_degc")
    dataref("elev_m", "sim/flightmodel/position/elevation")
    dataref("dewpoint", "sim/weather/dewpoi_sealevel_c")
    --XPLMSpeakString(pressure_da)
    --alt_setting = pressure * 33.8638866667 -- to hPa

    this_is_pissing_me_off = alt_setting ^ 0.190263
    dew_k = dewpoint + 273.15
    oat_k = oat_c + 273.15
    Pv = (rel_hum / 100) * 6.1078 * (10 ^ ((7.5 * dewpoint) / (dewpoint + 237.3))) -- https://ncalculators.com/meteorology/vapor-pressure-calculator.htm

    P = (this_is_pissing_me_off - (8.417286 * (10 ^ -5) * elev_m)) ^ (1 / 0.190263) -- alt_setting ^ 0.190263

    Pd = P - Pv
    Rd = 287.058
    Rv = 461.495
    pres = ((Pd / (Rd * oat_k)) + (Pv / (Rv * oat_k))) * 100 -- not exactly the same but close enough that I think it's correct

    H = 44.3308 - 42.2665 * (pres ^ 0.234969)
    XPLMSpeakString(H)
    return H * 1000 -- from km to m
end

function update()
    if CKEY == "s" then
        --XPLMSpeakString("pressed S")
        --set("sim/operation/override/override_control_surfaces", 1)
        --flaprat = 0.3333
        starttime = time
        startpos = {Aircraft_x, Aircraft_z}
        starttemp = temp
        startpressure = pressure * 33.8638867 -- to hPa

        --pressureAlt = AGL + (t_0 / l) * (1 - (startpressure / p_0) ^ (r_s * l / g)) -- https://aviation.stackexchange.com/questions/71962/what-formula-to-use-for-calculating-pressure-altitude
        densityAlt = density_altitude(startpressure)
        startWind = {winddir_deg, windspeed_kn * 463 / 900} -- to m/s
        parkbrake = 0
        set("AirbusFBW/ParkBrake", 0)
        flaprat = 0.25
        throttle_input[0] = 1
        throttle_input[1] = 1
        throttle_input[0] = 1
        throttle_input[1] = 1
        do_every_frame("agl()")
    end
end

do_on_keystroke("update()")
