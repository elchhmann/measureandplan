---@diagnostic disable : undefined-global
---@diagnostic disable : lowercase-global

maxDist = 1000

function init()
    -- DebugPrint("init2")
end

function tick()
    origin = GetCameraTransform().pos
    cameraDirection = TransformToParentVec(GetCameraTransform(), Vec(0, 0, -1))
    raycast, dist = QueryRaycast(origin, cameraDirection, maxDist)
    hitPosition = VecAdd(origin, VecScale(cameraDirection, dist))
    lenght = VecLength(VecSub(b, a))

    if InputPressed("m") and dist < maxDist then

        if not bSet and aSet then
            b = hitPosition
            bSet = true
            -- DebugPrint(lenght .. "m")
            -- DebugPrint("b set")
            -- DebugPrint(b)
            -- Paint(b, 0.1, spraypaint)
        end

        if not aSet then
            a = hitPosition
            aSet = true
            -- DebugPrint("a set")
            -- DebugPrint(a)
            -- Paint(a, 0.1, spraypaint)
        end
    end
    if InputPressed("n") then
        aSet = false
        bSet = false
        -- DebugPrint("reset")
    end

    if not bSet and aSet and dist < maxDist then
        DebugLine(a, hitPosition, 255, 0, 0, 1)
        DebugCross(a, 0, 255, 0, 1)
        DebugCross(hitPosition, 0, 0, 255, 1)
    end


    -- direction = Vecnormalize(VecSub(b, a))
end

function draw()
    
    UiPush()
        UiFont("bold.ttf", 24)
        UiTranslate(50, 50)
        if bSet then
            UiText("Lenght: " .. lenght .. "m")
        end
    UiPop()

    if (aSet and bSet) then
        DebugLine(a, b, 255, 0, 0, 1)
        DebugCross(a, 0, 255, 0, 1)
        DebugCross(b, 0, 0, 255, 1)
    end
end