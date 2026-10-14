#version 2

---@diagnostic disable : undefined-global
---@diagnostic disable : lowercase-global


function maxName(deltas)
    local copy = { }
    local names = { "deltaX", "deltaY", "deltaZ" }
    for _, v in ipairs(deltas) do table.insert(copy, v) end
    
    table.sort(copy, function (a, b) return a > b end)
    
    local result = { }
    
    for biggestKey, biggestValue in ipairs(copy) do
        for index, value in pairs(deltas) do
            if biggestValue == value then
                table.insert(result, names[index])
                break
            end
        end
        
        if #result == 2 then
            return result
        end
    end
end

function avg(a, b)
    return ((a+b)/2)
end

maxDist = 1000

menu = false

mode = "line"

measurements = {
    pos_a = Vec(0, 0, 0),
    set_a = false,
    pos_b = Vec(0, 0, 0),
    set_b = false,
    length = nil,
    type = nil
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

end

function client.tick() -- Measurement math etc
    origin = GetCameraTransform().pos -- Position of the camera
    cameraDirection = TransformToParentVec(GetCameraTransform(), Vec(0, 0, -1)) -- Direction the camera is facing
    raycast, dist = QueryRaycast(origin, cameraDirection, maxDist) -- Raycast from the camera
    hitPosition = VecAdd(origin, VecScale(cameraDirection, dist)) -- Position where the raycast hits
    hitPositionSnapped = Vec(round(hitPosition[1],1), round(hitPosition[2],1), round(hitPosition[3],1))

    -- shape = QueryAabbShapes(hitPosition, hitPosition)
    -- DebugPrint(shape)
    -- DrawShapeHighlight(shape[1], 0.5)
    -- DrawShapeHighlight(shape[2], 0.2)
    -- DrawShapeHighlight(shape[3], 0.1)
    -- DebugCross(hitPosition)
    
    -- shapePos = GetShapeWorldTransform(shape)

    _, bodyPos, _, body = QueryClosestPoint(hitPosition, 0.1)
    -- DebugPrint("Body: " .. body)
    -- DebugPrint("Position: " .. bodyPos[1] .. bodyPos[2] .. bodyPos[3])
    DrawShapeHighlight(body, 0.5)
    DebugPrint(GetShapeLocalTransform(body).pos[1] .. GetShapeLocalTransform(body).pos[2] .. GetShapeLocalTransform(body).pos[3])
    DebugCross(Vec(GetShapeLocalTransform(body).pos[1], GetShapeLocalTransform(body).pos[2], GetShapeLocalTransform(body).pos[3]))
    DebugCross(Vec(GetShapeWorldTransform(body).pos[1], GetShapeWorldTransform(body).pos[2], GetShapeWorldTransform(body).pos[3]))
    -- DebugCross(Vec(round(bodyPos[1], 1), round(bodyPos[2], 1), round(bodyPos[3], 1)))



    if InputPressed(",") then
        menu = not menu
    end

    if InputDown("shift") and VecLength(GetPlayerVelocity()) < 0.1 then
        hitPosition = hitPositionSnapped
        DebugCross(hitPosition, 0, 0, 255, 1)
    end

    if InputPressed("m") then

        if #measurements == 0 then -- If there are no measurements, create the first one
            table.insert(measurements, {
                pos_a = nil,
                set_a = false,
                pos_b = nil,
                set_b = false,
                length = nil,
                type = mode
            })
        end

        if measurements[#measurements].set_b then -- Create a new measurement
            table.insert(measurements, {
                        pos_a = nil,
                        set_a = false,
                        pos_b = nil,
                        set_b = false,
                        length = nil,
                        type = mode
                    })
        end

        if not measurements[#measurements].set_b and measurements[#measurements].set_a and dist < maxDist then -- Second point of the measurement; create a new one
            measurements[#measurements].pos_b = hitPosition
            measurements[#measurements].set_b = true
            measurements[#measurements].length = VecLength(VecSub(measurements[#measurements].pos_a, measurements[#measurements].pos_b))
        end

        if not measurements[#measurements].set_a and dist < maxDist then -- First point of the measurement
            measurements[#measurements].pos_a = hitPosition
            measurements[#measurements].set_a = true 
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
    end

    if InputPressed("rmb") then -- Cancel measurement / remove last one
        table.remove(measurements, #measurements)
    end

end

function client.draw() -- Rendering
    
    for i = 1, #measurements do

        

        deltaX = math.abs(measurements[i].pos_a[1] - measurements[i].pos_b[1])
        deltaY = math.abs(measurements[i].pos_a[2] - measurements[i].pos_b[2])
        deltaZ = math.abs(measurements[i].pos_a[3] - measurements[i].pos_b[3])

        

        local dominantDelta = maxName { deltaX, deltaY, deltaZ }
        -- DebugPrint(dominantDelta)

        if (dominantDelta[1] == "deltaX" and dominantDelta[2] == "deltaZ") or (dominantDelta[1] == "deltaZ" and dominantDelta[2] == "deltaX") then
            aprim = Vec(measurements[i].pos_b[1], measurements[i].pos_a[2], measurements[i].pos_a[3]) -- a'(xb, ya, za)
            bprim = Vec(measurements[i].pos_a[1], measurements[i].pos_b[2], measurements[i].pos_b[3]) -- b'(xa, ya, zb)

            blevel = Vec(measurements[i].pos_b[1], measurements[i].pos_a[2], measurements[i].pos_b[3]) -- b but with the y coordinate of a (same level)

            orientation = "horizontal"
        else
            aprim = Vec(measurements[i].pos_a[1], measurements[i].pos_b[2], measurements[i].pos_a[3]) -- a'(xb, ya, za)
            bprim = Vec(measurements[i].pos_b[1], measurements[i].pos_a[2], measurements[i].pos_b[3]) -- b'(xa, ya, zb)

            blevel = Vec(measurements[i].pos_b[1], measurements[i].pos_a[2], measurements[i].pos_b[3]) -- b but with the y coordinate of a (same level)
            
            orientation = "vertical"
        end


        -- DebugCross(aprim, 0, 1, 1) -- cyan
        -- DebugCross(bprim, 1, 1, 0) -- yellow

        dimensionx = VecLength(VecSub(measurements[i].pos_a, bprim))
        dimensiony = VecLength(VecSub(measurements[i].pos_a, aprim))
        
        uiX, uiY, UIdist = UiWorldToPixel(VecLerp(measurements[i].pos_a, measurements[i].pos_b, 0.5)) -- Get the position of the text in the middle of the line

        if measurements[i].type == "rect" then
            if orientation == horizontal then
                uiX, uiY, UIdist = UiWorldToPixel(VecLerp(measurements[i].pos_a, blevel, 0.5)) -- Get the position of the text in the middle of the line
            else
                uiX, uiY, UIdist = UiWorldToPixel(VecLerp(measurements[i].pos_a, measurements[i].pos_b, 0.5))
            end
        end
        
        if  measurements[i].set_b then -- Final render of the measurements
            DebugCross(measurements[i].pos_a, 0, 1, 0, 1)
            DebugCross(measurements[i].pos_b, 0, 0, 1, 1)

            if measurements[i].type == "line" then
                DebugLine(measurements[i].pos_a, measurements[i].pos_b, 1, 0, 0, 1)
            end

            if measurements[i].type == "rect" then
                if orientation == "horizontal" then
                    DebugLine(measurements[i].pos_a, aprim, 1, 0, 0, 1) -- From a(xa, ya, za) to  a'(xb, ya, za)
                    DebugLine(measurements[i].pos_a, bprim, 1, 0, 0, 1) -- From a(xa, ya, za) to  b'(xa, ya, zb)

                    DebugLine(blevel, aprim, 1, 0, 0, 1) -- From b(xb, yb, zb) to  a'(xb, ya, za)
                    DebugLine(blevel, bprim, 1, 0, 0, 1) -- From b(xb, yb, zb) to  b'(xa, ya, zb)
                else
                    DebugLine(measurements[i].pos_a, aprim, 1, 0, 0, 1) -- From a(xa, ya, za) to  a'(xb, ya, za)
                    DebugLine(measurements[i].pos_a, bprim, 1, 0, 0, 1) -- From a(xa, ya, za) to  b'(xa, ya, zb)

                    DebugLine(measurements[i].pos_b, aprim, 1, 0, 0, 1) -- From b(xb, yb, zb) to  a'(xb, ya, za)
                    DebugLine(measurements[i].pos_b, bprim, 1, 0, 0, 1) -- From b(xb, yb, zb) to  b'(xa, ya, zb)
                end
            end

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
                    if measurements[i].type == "line" then
                       UiText(string.format("%.2f m", measurements[i].length))  
                    end
                    -- DebugPrint(measurements[i].type)
                    if measurements[i].type == "rect" then
                       UiText(string.format("%.2f m x %.2f m", dimensionx, dimensiony))
                    end
                              
                UiPop()
            end
        end
        
        if not measurements[i].set_b and measurements[i].set_a and dist < maxDist then -- Real-time render of the measurements
            DebugCross(measurements[i].pos_a, 0, 1, 0, 1)
            DebugCross(hitPosition, 0, 0, 1, 1)

            if measurements[i].type == "line" then
                DebugLine(measurements[i].pos_a, hitPosition, 1, 0.1, 0.1, 0.4)
            end

            if measurements[i].type == "rect" then
                if orientation == "horizontal" then
                    DebugLine(measurements[i].pos_a, aprim, 1, 0.1, 0.1, 0.4) -- From a(xa, ya, za) to  a'(xb, ya, za)
                    DebugLine(measurements[i].pos_a, bprim, 1, 0.1, 0.1, 0.4) -- From a(xa, ya, za) to  b'(xa, ya, zb)

                    DebugLine(blevel, aprim, 1, 0.1, 0.1, 0.4) -- From b(xb, yb, zb) to  a'(xb, ya, za)
                    DebugLine(blevel, bprim, 1, 0.1, 0.1, 0.4) -- From b(xb, yb, zb) to  b'(xa, ya, zb)
                else
                    DebugLine(measurements[i].pos_a, aprim, 1, 0.1, 0.1, 0.4) -- From a(xa, ya, za) to  a'(xb, ya, za)
                    DebugLine(measurements[i].pos_a, bprim, 1, 0.1, 0.1, 0.4) -- From a(xa, ya, za) to  b'(xa, ya, zb)

                    DebugLine(measurements[i].pos_b, aprim, 1, 0.1, 0.1, 0.4) -- From b(xb, yb, zb) to  a'(xb, ya, za)
                    DebugLine(measurements[i].pos_b, bprim, 1, 0.1, 0.1, 0.4) -- From b(xb, yb, zb) to  b'(xa, ya, zb)
                end
            end
        end
    end

    if menu then
        UiMakeInteractive()

        UiTranslate(UiCenter(), UiMiddle())
        UiAlign("center middle")

        UiPush()
            UiBackgroundBlur(1.0)
            UiColor(0, 0, 0, 0.6)
            UiAlign("center middle")
            UiRect(1000, 500)
        UiPop()

        UiPush()

            UiFont("bold.ttf", 24)

            UiTranslate(-400, -150)
                if UiImageButton("/media/button_line.png") then
                    mode = "line"
                end
            UiPush()
                UiTranslate(0, 80)
                UiText("Line")
            UiPop()

                UiTranslate(200, 0)
                if UiImageButton("/media/button_rect.png") then
                    mode = "rect"
                end

            UiPush()
                UiTranslate(0, 80)
                UiText("Rectangular")
            UiPop()

        UiPop()
    end
end