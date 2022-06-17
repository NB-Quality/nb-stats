--Credit: negbook
--https://github.com/negbook/simple_snippets/blob/main/grouped_libs/RequestLoopThread.md
local e,loops,taskduration,task = {},{},{},{}
setmetatable(loops,{__newindex=function(t,k,v) rawset(t,tostring(k),v) end,__index = function(t,k) return rawget(t,tostring(k)) end })
setmetatable(e,{__call = function() end })
local task_inner_updating = {}

local threads_total = 0
local GetThreadsTotal = function() return ("threads_total"..threads_total) end 

local GetDurationByHandle = function(handle)
    if not handle then return end 
    for duration,handles in pairs(loops) do 
        for i=1,#handles do 
            if handles[i] == handle then 
                return duration 
            end 
        end 
    end 
end 

local DeleteTaskHandleFromLoopGroup = function(handle,duration)
    if not handle then return end 
    local handle_index
    local handles = loops[duration]
    if handles then 
        for idx=1,#handles do 
            local v = handles[idx]
            if v == handle then 
                handle_index = idx
                break
            end 
        end 
    end 

    if (loops[duration] or e)[handle_index] then table.remove(loops[duration],handle_index) end 
    if loops[duration] and #loops[duration] == 0 then loops[duration] = nil end 

end 

local updateTask = function(handle,newduration,cb)
    if not handle then return end 
    local oldduration = GetDurationByHandle(handle)
    if oldduration ~= newduration then  
        if not task_inner_updating[oldduration] then task_inner_updating[oldduration] = {} end 
        task_inner_updating[oldduration][handle] = cb 
        return 
    end 
end 


local createLoopGroup;createLoopGroup = function(duration)

     if loops[duration] == nil then 
        loops[duration] = {}; 
        
        CreateThread(function()
            threads_total = threads_total + 1
            local handles = loops[duration]
            
            repeat 
                local runtask = false 
                local handles = handles or e 
                if handles then 
                    for i=1,#handles do 
                        runtask = true 
                        local handle = handles[i] 
                        if handle then 
                            local action = task[handle]
                            local task_inner_update = (task_inner_updating[duration] or e)[handle]
                            if action and not task_inner_update then 
                                action(handle)
                            end 
                            if task_inner_update then 
                                task_inner_update(duration)
                            end 
                        end 
                    end 
                end 
                Wait(duration)
            until not runtask
            threads_total = threads_total - 1
            return 
        end) 
    end 
  
end 

local TaskHandleJoinNewLoopGroup = function(handle, newduration)
    updateTask(handle,newduration,function()
        
        local oldduration = GetDurationByHandle(handle)
        DeleteTaskHandleFromLoopGroup(handle,oldduration)
        createLoopGroup(newduration) 
        table.insert(loops[newduration],handle)
        Wait(oldduration)
        task_inner_updating[oldduration][handle] = nil
        
         
    end)
end 

local addTask = function(handle,duration,onaction)
    if not handle then return end 
    task[handle] = onaction  
    createLoopGroup(duration)
    table.insert(loops[duration],handle)
end 

RequestLoopThreadScaleform = RequestLoopThread or function(duration)

    local result = setmetatable({},{
        __tostring = function(t)
            local idx = 0 
            local tasks = {}
            for i,v in pairs(t) do 
                if i ~= "debug" then 
                    idx = idx + 1
                    table.insert(tasks,i)
                end 
            end 
            return "This handle has "..idx .." tasks: "..table.concat(tasks,",")
        end,
        __mode = "kv",
        __newindex=function(t,name,fn) 
            local Kill = function(newduration)
                
                DeleteTaskHandleFromLoopGroup(t[name],GetDurationByHandle(t[name]))

                rawset(t,name,nil)
            end 
            
            local Set = function(newduration)
                TaskHandleJoinNewLoopGroup(t[name],newduration)
            end 

            local Check = function()
                return not not  t[name]
            end 
            local newobj = function(default)
                local value = default or 0
                return function(action,v) 
                    if Check() then  
                        if action == 'get' then 
                            if v then 
                                return value or 0
                            else
                                return value or 0
                            end 
                        elseif action == 'set' then 
                            if value ~= v then 
                                value = v 
                                Set(v)
                            end 
                        elseif action == 'kill' or action == 'break' then 
                            Kill()
                        end 
                    end 
                end 
            end
            local obj = newobj(duration)
            
            rawset(t,name,obj)

            if fn then 
                addTask(t[name],duration,fn) 
            end 
        end}
    )
    return result
end 


Scaleform = {}

local scaleform = {}
scaleform.__index = scaleform

function Scaleform.Request(name)
	local name = name 
    local handle = RequestScaleformMovie(name)
    local timer = GetGameTimer() 
    while not HasScaleformMovieLoaded(handle) and math.abs(GetTimeDifference(GetGameTimer(), timer)) < 5000 do 
        Wait(50)
    end 

	local self = {
        name = name, 
        handle = handle, 
    }
	return setmetatable(self, {
        __tostring = handle
    })
end

Scaleform = {}

local scaleform = {}
scaleform.__index = scaleform
scaleform.__tostring = function(self) return self.handle end 
local sender = function(handle,...)
    local tb = {...}
	PushScaleformMovieFunction(handle,tb[1])
    
	for i=2,#tb do
        local v = tb[i]
		if type(v) == "number" then 
			if math.type(v) == "integer" then
					ScaleformMovieMethodAddParamInt(v)
			else
					ScaleformMovieMethodAddParamFloat(v)
			end
		elseif type(v) == "string" then 
            if string.sub(v, 1, string.len("label:")) == "label:" then 
                local v = string.sub(v, string.len("label:")+1, string.len(v))
                BeginTextCommandScaleformString(v)
                EndTextCommandScaleformString()
            elseif string.sub(v, 1, string.len("hashlabel:")) == "hashlabel:" then 
                local v = string.sub(v, string.len("hashlabel:")+1, string.len(v))
                AddTextComponentSubstringTextLabelHashKey(tonumber(v))
            else 
                ScaleformMovieMethodAddParamTextureNameString(v) 
            end 
		elseif type(v) == "boolean" then ScaleformMovieMethodAddParamBool(v)
        elseif type(v) == "table" then 
            BeginTextCommandScaleformString(v[1])
            for k=2,#v do 
                local c = v[k]
                if string.sub(c, 1, string.len("label:")) == "label:" then 
                    local c = string.sub(c, string.len("label:")+1, string.len(c))
                    AddTextComponentSubstringTextLabel(c)
                elseif string.sub(c, 1, string.len("hashlabel:")) == "hashlabel:" then 
                    local c = string.sub(c, string.len("hashlabel:")+1, string.len(c))
                    AddTextComponentSubstringTextLabelHashKey(tonumber(c))
                else 
                    if type(c) == "number" then 
                        AddTextComponentInteger(c)
                    else 
                        ScaleformMovieMethodAddParamTextureNameString(c) 
                    end
                end 
            end 
            EndTextCommandScaleformString()
		end
	end 
   
	PopScaleformMovieFunctionVoid()
end 
scaleform.__call = function(t,...)
    local handle = t.handle
	return sender(handle,...)
end 
scaleform.send = scaleform.__call
Scaleform.Send = sender 

Scaleform.Request = function(name)
    local name = name 
    local handle = RequestScaleformMovie(name)
    local timer = GetGameTimer() 
    while not HasScaleformMovieLoaded(handle) and math.abs(GetTimeDifference(GetGameTimer(), timer)) < 5000 do 
        Wait(50)
    end 
    local self;self = {
        name = name,
        handle = handle,
        unvalid = false
    }
    return setmetatable(self,scaleform)
end 
setmetatable(Scaleform,{__call=function(scaleform,name) return scaleform.Request(name) end}) 
Loop = RequestLoopThreadScaleform(0)
function scaleform:Draw(drawinit,drawend)
    
    local name = self.name
    local handle = self.handle
    Loop["scaleform:"..name] = function(duration)
        
        if drawinit and drawinit() then 
            DrawScaleformMovieFullscreen(handle,255,255,255,255,0)
        end
        if drawend then drawend() end 
    end 
end 

function scaleform:Draw2D(x,y,width,height,drawinit,drawend)
    
    local name = self.name
    local handle = self.handle
    Loop["scaleform:"..name] = function(duration)
        if drawinit and drawinit() then 
            DrawScaleformMovie(handle, x, y, width, height, 255, 255, 255, 255)
        end 
        if drawend then drawend() end 
    end 
end 

function scaleform:Draw2DPixel(x,y,width,height,drawinit,drawend)
    
    local name = self.name
    local handle = self.handle
    local Width, Height = 1280,720
    local x = x / Width
    local y = y / Height
    local width = width / Width
    local height = height / Height
    Loop["scaleform:"..name] = function(duration)
        
        if drawinit and drawinit() then 
            DrawScaleformMovie(handle, x + (width / 2.0), y + (height / 2.0), width, height, 255, 255, 255, 255)
        end 
        if drawend then drawend() end 
    end 
end 

function scaleform:Draw3D(x, y, z, rx, ry, rz, scalex, scaley, scalez)
    
    local name = self.name
    local handle = self.handle
    Loop["scaleform:"..name] = function(duration)
        
        DrawScaleformMovie_3dNonAdditive(handle, x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
    end 
end

function scaleform:Draw3DTransparent(x, y, z, rx, ry, rz, scalex, scaley, scalez)
    
    local name = self.name
    local handle = self.handle
    Loop["scaleform:"..name] = function(duration)
        
        DrawScaleformMovie_3d(handle, x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
    end 
end

local function GetPlayerPedOrVehicle(player)
    local ped = (player == nil or player== -1) and PlayerPedId() or GetPlayerPed(player)
    local veh = GetVehiclePedIsIn(ped)
    return veh~=0 and veh or ped
end

function scaleform:Draw3DPed(ped,offsetx,offsety,offsetz)
    
    local name = self.name
    local handle = self.handle
    local offset = offsety == nil and (offsetx or vector3(0.0,0.0,0.0)) or vector3(offsetx,offsety,offsetz)
    Loop["scaleform:"..name] = function(duration)
        
        local entity = ped
        local model = GetEntityModel(entity)
        local s1,s2 = GetModelDimensions(model)
        local sizeVector = s2-s1
        local inveh = IsPedInAnyVehicle(entity) 
        local coords = inveh and GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.z/2) or GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.y/2)
        local x,y,z = table.unpack(coords)
        local rot = GetEntityRotation(entity,2)
        local rx,ry,rz = table.unpack(rot)
        local scale = vector3(1.0,1.0,1.0)
        local scalex, scaley, scalez = table.unpack(scale)
        SetGameplayCamRelativePitch(0, 0.1);
        SetGameplayCamRelativeHeading(0);
        DrawScaleformMovie_3dNonAdditive(handle, x, y, z, rx, inveh and -ry or ry, inveh and rz or -rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)

    end 
end

function scaleform:Draw3DPedTransparent(ped,offsetx,offsety,offsetz)
    
    local name = self.name
    local handle = self.handle
    local offset = offsety == nil and (offsetx or vector3(0.0,0.0,0.0)) or vector3(offsetx,offsety,offsetz)
    Loop["scaleform:"..name] = function(duration)
        
        local entity = ped
        local model = GetEntityModel(entity)
        local s1,s2 = GetModelDimensions(model)
        local sizeVector = s2-s1
        local inveh = IsPedInAnyVehicle(entity) 
        local coords = inveh and GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.z/2) or GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.y/2)
        local x,y,z = table.unpack(coords)
        local rot = GetEntityRotation(entity,2)
        local rx,ry,rz = table.unpack(rot)
        local scale = vector3(1.0,1.0,1.0)
        local scalex, scaley, scalez = table.unpack(scale)
        SetGameplayCamRelativePitch(0, 0.1);
        SetGameplayCamRelativeHeading(0);
        DrawScaleformMovie_3d(handle, x, y, z, rx, inveh and -ry or ry, rz, 2.0, 2.0, 1.0, scalex, -scaley, scalez, 2)

    end 
end


function scaleform:Close()
    Loop["scaleform:"..self.name]("kill")
    SetScaleformMovieAsNoLongerNeeded(self.handle)
    self.handle = nil
end

function scaleform:IsAlive()
	return not self.unvalid
end
