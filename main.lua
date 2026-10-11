#version 2

---@diagnostic disable : undefined-global
---@diagnostic disable : lowercase-global

maxDist = 1000

measurements = {
    pos_a = Vec(0, 0, 0),
    set_a = false,
    pos_b = Vec(0, 0, 0),
    set_b = false,
    length = nil
}

function round(value, decimals)
    local factor = 10 ^ decimals
    local scaled = value * factor

    if scaled >= 0 then
        return math.floor(scaled + 0.5) / factor
    else
        return math.ceil(scaled - 0.5) / factor
    end
end

function client.init()
    -- DebugPrint("init2")
end

function client.tick() -- Measurement math etc
    origin = GetCameraTransform().pos -- Position of the camera
    cameraDirection = TransformToParentVec(GetCameraTransform(), Vec(0, 0, -1)) -- Direction the camera is facing
    raycast, dist = QueryRaycast(origin, cameraDirection, maxDist) -- Raycast from the camera
    hitPosition = VecAdd(origin, VecScale(cameraDirection, dist)) -- Position where the raycast hits
    hitPositionSnapped = Vec(round(hitPosition[1],1), round(hitPosition[2],1), round(hitPosition[3],1))

    if InputDown("shift") and VecLength(GetPlayerVelocity()) < 0.1 then
        hitPosition = hitPositionSnapped
        DebugCross(hitPosition, 0, 0, 255, 1)
    end
    -- DebugPrint(GetPlayerVelocity())
    if InputPressed("m") then

        if #measurements == 0 then -- If there are no measurements, create the first one
            table.insert(measurements, {
                pos_a = nil,
                set_a = false,
                pos_b = nil,
                set_b = false,
                length = nil
            })
            -- DebugPrint("First measurement created")
        end

        if measurements[#measurements].set_b then
            table.insert(measurements, {
                        pos_a = nil,
                        set_a = false,
                        pos_b = nil,
                        set_b = false,
                        length = nil
                    })
            -- DebugPrint("New measurement created")
        end

        if not measurements[#measurements].set_b and measurements[#measurements].set_a and dist < maxDist then -- Second point of the measurement; create a new one
            measurements[#measurements].pos_b = hitPosition
            measurements[#measurements].set_b = true
            measurements[#measurements].length = VecLength(VecSub(measurements[#measurements].pos_a, measurements[#measurements].pos_b))
            -- DebugPrint("Second measurement point set")
        end

        if not measurements[#measurements].set_a and dist < maxDist then -- First point of the measurement
            measurements[#measurements].pos_a = hitPosition
            measurements[#measurements].set_a = true 
            -- DebugPrint("First measurement point set")
        end
        
    end

    if #measurements > 0 and measurements[#measurements].set_a and not measurements[#measurements].set_b then
        measurements[#measurements].pos_b = hitPosition
        if dist < maxDist then
            measurements[#measurements].length = VecLength(VecSub(measurements[#measurements].pos_a, measurements[#measurements].pos_b))
        end
    end

    if InputPressed("n") then
        measurements = {} -- Clear all measurements
        -- DebugPrint("All measurements cleared")
    end

    if InputPressed("rmb") then -- Cancel measurement / remove last one
        table.remove(measurements, #measurements)
    end

    DebugPrint(#measurements)
end

function client.draw() -- Rendering
    

    for i = 1, #measurements do

        uiX, uiY, UIdist = UiWorldToPixel(VecLerp(measurements[i].pos_a, measurements[i].pos_b, 0.5)) -- Get the position of the text in the middle of the line
        -- DebugPrint("X = " .. uiX)
        -- DebugPrint("Y = " .. uiY)
        -- DebugPrint("D = " .. UIdist)
        if  measurements[i].set_b then -- Final render of the measurements
            DebugLine(measurements[i].pos_a, measurements[i].pos_b, 1, 0, 0, 1)
            DebugCross(measurements[i].pos_a, 0, 1, 0, 1)
            DebugCross(measurements[i].pos_b, 0, 0, 1, 1)
        end

        if UIdist > 0 and measurements[i].set_a and measurements[i].length < maxDist then -- Measurement length label
            if (not measurements[i].set_b and dist < maxDist) or measurements[i].set_b then
                UiPush()
                    UiFont("bold.ttf", 24)
                    UiAlign("center middle")
                    UiTranslate(uiX, uiY)
                    if measurements[i].set_b then
                        UiColor(1,1,1,1)
                        UiTextOutline(0,0,0,5)
                    end
                    if not measurements[i].set_b then
                        UiColor(1,1,1,0.3)
                    end
                    UiText(string.format("%.2f m", measurements[i].length))           
                UiPop()
            end
        end
        if not measurements[i].set_b and measurements[i].set_a and dist < maxDist then -- Real-time render of the measurements
            DebugLine(measurements[i].pos_a, hitPosition, 1, 0.1, 0.1, 0.4)
            DebugCross(measurements[i].pos_a, 0, 1, 0, 1)
            DebugCross(hitPosition, 0, 0, 1, 1)
        end
    end
end