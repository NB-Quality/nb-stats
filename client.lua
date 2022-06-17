local gameUI,customUI,MixUI,UIcolor,UIPanel = (config.UI == "gamebase"), (config.UI == "custom"), (config.UI == "mix"), config.slotsColor
local LoadGamebaseStats = config.LoadGamebaseStats
local client_ui_csv,client_ui_csv_gamebase,client_ui_stats_all;
 
client_ui_stats_all = {}
client_ui_csv = ReadCSV("data/stats.csv")

GlobalData = {}

if LoadGamebaseStats then 
    client_ui_csv_gamebase = ReadCSV("data/gamebase.csv") 
    for i=1,#client_ui_csv_gamebase do 
        local stats = client_ui_csv_gamebase[i]
        client_ui_stats_all[stats.stat] = stats
    end 
end

for i=1,#client_ui_csv do 
    local stats = client_ui_csv[i]
    client_ui_stats_all[stats.stat] = stats
end 

local GetMinMax = function(stat)
    local stat = stat:lower()
    local d = client_ui_stats_all[stat] or error(stat,2)
    return d.min,d.max
end 


if gameUI or customUI or MixUI then 
    CreateThread(function()
        UIPanel = Scaleform("PLAYER_SWITCH_STATS_PANEL");
        local display = false     
        local SetScriptGfxAlign = SetScriptGfxAlign
        local SetScriptGfxAlignParams = SetScriptGfxAlignParams
        local IsHudComponentActive = IsHudComponentActive
        local init = function()
            local found = false 
            if display then 
                SetScriptGfxAlign(82, 66);
                SetScriptGfxAlignParams(0, 0, 0, 0);
                found = true 
            end 
            return display
        end 
        local drawend = ResetScriptGfxAlign
        
        CreateThread(function()
            while true do Wait(50) 
                local d = IsHudComponentActive(19)
                if d and not display then 
                    display = true
                    UIPanel:Draw2D(0.14974765625,0.006,0.1874953125,0.3875,init,drawend)
                    UpdatePlayerStats()
                elseif not d and display then 
                    display = false 
                    UIPanel:Close()
                    UIPanel = Scaleform("PLAYER_SWITCH_STATS_PANEL");
                end 
            end 
        end)
    end)
end 

local StoreCustom = function(stat,amount)
    local stat = stat:lower()
    GlobalData[stat] = amount 
end 
local GetStoreCustom = function(stat)
    local stat = stat:lower()
    return GlobalData[stat] 
end 

SetPlayerStat = function (stat,amount)
   local stat = stat:lower()
   local GetStatGamebase = function(stat)
       local stat = GetHashKey("mp0_"..stat)
       return stat 
   end 
   if type(amount) == "string" then 
       local access = StatGetString(GetStatGamebase(stat), -1)
       if access then
          StatSetString(GetStatGamebase(stat), amount, true)
       else 
          StoreCustom(stat,amount)
       end 
   elseif type(amount) == "number" and math.type(amount) == "float" then 
       local access = StatGetFloat(GetStatGamebase(stat), -1)
       if access then
          StatSetFloat(GetStatGamebase(stat), amount, true)
       else 
          StoreCustom(stat,amount)
       end 
   else 
       local access = StatGetInt(GetStatGamebase(stat), -1)
       if access then
          StatSetInt(GetStatGamebase(stat), amount, true)
       else 
          StoreCustom(stat,amount)
       end 
   end 
end

GetPlayerStat = function (stat, type)
   local stat = stat:lower()
   local type = type:lower()
   local GetStatGamebase = function(stat)
       local stat = GetHashKey("mp0_"..stat)
       return stat 
   end 
   if type then 
       if type == "string" then 
          local access,result = StatGetString(GetStatGamebase(stat), -1)
          return result 
       elseif type == "float" then 
          local access,result = StatGetFloat(GetStatGamebase(stat), -1)
          return result 
       else 
          local access,result = StatGetInt(GetStatGamebase(stat), -1)
          return result 
       end 
   else 
       return GetStoreCustom(stat,amount)
   end 
end 

local CurrentPages = {}
local DisplayingPage = 1
UpdatePlayerStats = function()
    TriggerServerCallback("GetPlayerStats",function(skills)
        CurrentPages = {}
        local opts = {}
        
        for i , v in pairs(skills) do 
            SetPlayerStat(i,v)
        end 
        if UIPanel then 
            if gameUI or MixUI then 
                
                local GetStatIntLocalPercent = function(stat)
                    local r = GetPlayerStat(stat,'int')
                    local min,max =  GetMinMax(stat)
                    r = math.floor((r - min) / (max - min) * 100)
                    return r
                end 
                local GetStatFloatLocalPercent = function(stat,prefix)
                    local r = GetPlayerStat(stat,'float')
                    local min,max =  GetMinMax(stat)
                    r = (r - min) / (max - min) * 100
                    return r
                end 
                opts = {GetStatIntLocalPercent("STAMINA"),"label:PCARD_STAMINA",GetStatIntLocalPercent("shooting_ability"),"label:PCARD_SHOOTING",GetStatIntLocalPercent("strength"),"label:PCARD_STRENGTH",GetStatIntLocalPercent("stealth_ability"),"label:PCARD_STEALTH",GetStatIntLocalPercent("flying_ability"),"label:PCARD_FLYING",GetStatIntLocalPercent("wheelie_ability"),"label:PCARD_DRIVING",GetStatIntLocalPercent("lung_capacity"),"label:PCARD_LUNG",GetStatFloatLocalPercent("player_mental_state"),"label:PCARD_MENTAL_STATE"}
                table.insert(CurrentPages,opts)
            end 
            if customUI or MixUI then  
                -- custom showing ui 
                local temp = {}
                local currentSlots = 1
                local customSlots = config.customUISlots
                if customSlots[1] then 
                    for i=1,#customSlots do 
                        local key = customSlots[i]
                        for k , v in pairs(skills) do 
                            if  key == k then -- custom ui slots
                                
                                if currentSlots < 9 then 
                                    local min,max =  GetMinMax(k)
                                    v = math.floor((v - min) / (max - min) * 100)
                                    table.insert(temp,v)
                                    table.insert(temp,k)
                                    currentSlots = currentSlots + 1
                                    
                                    if currentSlots == 9 then 
                                        table.insert(CurrentPages,temp)
                                        
                                        currentSlots = 1
                                        temp = {}
                                    end     
                                    
                                    --break
                                end 
                                
                            end 
                        end 
                    end 
                    opts = temp
                    table.insert(CurrentPages,opts)
                    
                end 
            end 
            
            DisplayingPage = 1
            local current = CurrentPages[DisplayingPage]
            if current and current[1] then 
                UIPanel("SET_STATS_LABELS",UIcolor,false,table.unpack(current))
            end
            
        end 
    end)
end 

CreateThread(function()
    local wait = config.pagefliptimer
	while true do
		Wait(wait)
        if UIPanel then 
            DisplayingPage = DisplayingPage + 1
            if #CurrentPages > 0 and (DisplayingPage > #CurrentPages or DisplayingPage > config.maxpages) then 
                DisplayingPage = 1
            end 
            
            local current = CurrentPages[DisplayingPage]
            if current and current[1] then 
                UIPanel("SET_STATS_LABELS",UIcolor,false,table.unpack(current))
            end 
        end 
	end
end)

CreateThread(function()
	while true do
		Wait(50)
		if NetworkIsSessionStarted() then
			UpdatePlayerStats()
			return
		end
	end
end)


exports("UpdatePlayerStats",UpdatePlayerStats)
exports("GetPlayerStat",GetPlayerStat)
exports("SetPlayerStat",SetPlayerStat)
