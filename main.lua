#version 2

---@diagnostic disable : undefined-global
---@diagnostic disable : lowercase-global

maxDist = 1000

function client.init()
    -- DebugPrint("init2")
end

function client.tick() -- Measurement math etc
    origin = GetCameraTransform().pos -- Position of the camera
    cameraDirection = TransformToParentVec(GetCameraTransform(), Vec(0, 0, -1)) -- Direction the camera is facing
    raycast, dist = QueryRaycast(origin, cameraDirection, maxDist) -- Raycast from the camera
    hitPosition = VecAdd(origin, VecScale(cameraDirection, dist)) -- Position where the raycast hits
    lenght = VecLength(VecSub(b, a)) -- Length of the line between points a and b
    if not bSet and dist < maxDist then
        b = hitPosition
    end

    if InputPressed("m") and dist < maxDist then

        if not bSet and aSet then -- Set point b
            b = hitPosition
            bSet = true
            -- DebugPrint(lenght .. "m")
            -- DebugPrint("b set")
            -- DebugPrint(b)
            -- Paint(b, 0.1, spraypaint)
        end

        if not aSet then -- Set point a
            a = hitPosition
            aSet = true
            -- DebugPrint("a set")
            -- DebugPrint(a)
            -- Paint(a, 0.1, spraypaint)
        end
    end
    if InputPressed("n") then -- Reset the points
        aSet = false
        bSet = false
        -- DebugPrint("reset")
    end

 


    -- direction = Vecnormalize(VecSub(b, a))
end

function client.draw() -- Rendering
    if aSet and dist < maxDist then
        UiPush()
            UiFont("bold.ttf", 24)
            uiX, uiY, dist = UiWorldToPixel(VecLerp(a, b, 0.5)) -- Get the position of the text in the middle of the line
            UiAlign("center middle")
            UiTranslate(uiX, uiY)
            UiText(string.format("%.2f m", lenght))
        UiPop()
    end
    if not bSet and aSet and dist < maxDist then -- Real-time render of the measurement
        DebugLine(a, hitPosition, 255, 0, 0, 0.4)
        DebugCross(a, 0, 255, 0, 1)
        DebugCross(hitPosition, 0, 0, 255, 1)
    end

    if (aSet and bSet) then -- Final render of the measurement
        DebugLine(a, b, 255, 0, 0, 1)
        DebugCross(a, 0, 255, 0, 1)
        DebugCross(b, 0, 0, 255, 1)
    end
end