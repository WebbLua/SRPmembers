script_name('SRPmembers')
script_author("Cody_Webb | Telegram: @Imikhailovich")
script_version("21.01.2023")
script_version_number(2)
local script = {checked = false, available = false, update = false, v = {date, num}, url, reload, loaded, unload, quest = {}, upd = {changes = {}, sort = {}}, label = {}}
local check = {bool = false, boolstream = false, stream = {}, findstream = false, status = false, amount = 0, irank = {}, line = 0, rmembers = {}, current = {}}
-------------------------------------------------------------------------[Библиотеки/Зависимости]---------------------------------------------------------------------
local ev = require 'samp.events'
local imgui = require 'imgui'
imgui.ToggleButton = require('imgui_addons').ToggleButton
local vkeys = require 'vkeys'
local rkeys = require 'rkeys'
local inicfg = require 'inicfg'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
-------------------------------------------------------------------------[Конфиг скрипта]-----------------------------------------------------------------------------
local AdressConfig, AdressFolder, settings, srpmemb_ini, memb, srpmembers_ini, server

local config = {
	bools = {
		['Руководство'] = false
	},
	hotkey = {
		['Проверить'] = "0"
	}
}
local memberslist = {
	list = {}
}
-------------------------------------------------------------------------[Переменные и маcсивы]-----------------------------------------------------------------
local main_color = 0x41491d
local prefix = "{41491d}[SRPmembers] {FFFAFA}"
local updatingprefix = u8:decode"{FF0000}[ОБНОВЛЕНИЕ] {FFFAFA}"
local antiflood = 0
local needtoreload = false

local menu = { -- imgui-меню
	main = imgui.ImBool(false),
	settings = imgui.ImBool(true),
	information = imgui.ImBool(false),
	commands = imgui.ImBool(false)
}
imgui.ShowCursor = false

local style = imgui.GetStyle()
local colors = style.Colors
local clr = imgui.Col
local currentNick
local suspendkeys = 2 -- 0 хоткеи включены, 1 -- хоткеи выключены -- 2 хоткеи необходимо включить
local ImVec4 = imgui.ImVec4
local imfonts = {mainFont = nil, smallmainFont = nil}
-------------------------------------------------------------------------[MAIN]--------------------------------------------------------------------------------------------
function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(0) end
	
	repeat wait(0) until sampGetCurrentServerName() ~= "SA-MP"
	server = sampGetCurrentServerName():gsub('|', '')
	server = (server:find('02') and 'Two' or (server:find('Revo') and 'Revolution' or (server:find('Legacy') and 'Legacy' or (server:find('Classic') and 'Classic' or nil))))
    if server == nil then chatmsg(u8:decode'Данный сервер не поддерживается, выгружаюсь...') script.unload = true thisScript():unload() end
	currentNick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
	
	AdressConfig = string.format("%s\\config", thisScript().directory)
    AdressFolder = string.format("%s\\config\\SRPmembers by Webb\\%s\\%s", thisScript().directory, server, currentNick)
	settings = string.format("SRPmembers by Webb\\%s\\%s\\settings.ini", server, currentNick)
	memb = string.format("SRPmembers by Webb\\%s\\%s\\members.ini", server, currentNick)
	
	if not doesDirectoryExist(AdressConfig) then createDirectory(AdressConfig) end
	if not doesDirectoryExist(AdressFolder) then createDirectory(AdressFolder) end
	
	if srpmemb_ini == nil then -- загружаем конфиг
		srpmemb_ini = inicfg.load(config, settings)
		inicfg.save(srpmemb_ini, settings)
	end
	
	if srpmembers_ini == nil then -- загружаем мемберс
		srpmembers_ini = inicfg.load(memberslist, memb)
		inicfg.save(srpmembers_ini, memb)
	end
	
	togglebools = {
		['Руководство'] = srpmemb_ini.bools['Руководство'] and imgui.ImBool(true) or imgui.ImBool(false)
	}
	
	sampRegisterChatCommand("memb", function() 
		for k, v in pairs(srpmemb_ini.hotkey) do 
			local hk = makeHotKey(k) 
			if tonumber(hk[1]) ~= 0 then 
				rkeys.unRegisterHotKey(hk) 
			end 
		end
		suspendkeys = 1 
		menu.main.v = not menu.main.v 
	end)
	sampRegisterChatCommand('getstream', getstream)
	sampRegisterChatCommand('membup', updateScript)
	
	script.loaded = true
	repeat wait(0) until sampIsLocalPlayerSpawned()
	checkUpdates()
	chatmsg(u8:decode"Скрипт запущен. Открыть главное меню - /memb")
	needtoreload = true
	
	imgui.Process = true
	imgui.ShowCursor = false
	
	
	chatManager.initQueue()
	lua_thread.create(chatManager.checkMessagesQueueThread)
	rmembers()
	members()
	while true do
		wait(0)
		if suspendkeys == 2 then
			rkeys.registerHotKey(makeHotKey("Проверить"), true, function() if sampIsChatInputActive() or sampIsDialogActive(-1) or isSampfuncsConsoleActive() then return end members() end)
			suspendkeys = 0
		end
		if not menu.main.v then 
			imgui.ShowCursor = false
			if suspendkeys == 1 then 
				suspendkeys = 2 
				sampSetChatDisplayMode(3) 
			end
		end
		textLabelOverPlayerNickname()
		rankLabelOverPlayerNickname()
		postLabelOverPlayerNickname()
		if not srpmemb_ini.bools['Руководство'] then
			for i = 0, 1000 do
				if postlabel[i] ~= nil then
					sampDestroy3dText(postlabel[i])
					postlabel[i] = nil
				end
			end
		end
	end
end
-------------------------------------------------------------------------[IMGUI]-------------------------------------------------------------------------------------------
function apply_custom_styles()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	
	imgui.GetStyle().WindowPadding = imgui.ImVec2(8, 8)
	imgui.GetStyle().WindowRounding = 16.0
	imgui.GetStyle().FramePadding = imgui.ImVec2(5, 3)
	imgui.GetStyle().ItemSpacing = imgui.ImVec2(4, 4)
	imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(5, 5)
	imgui.GetStyle().IndentSpacing = 9.0
	imgui.GetStyle().ScrollbarSize = 17.0
	imgui.GetStyle().ScrollbarRounding = 16.0
	imgui.GetStyle().GrabMinSize = 7.0
	imgui.GetStyle().GrabRounding = 6.0
	imgui.GetStyle().ChildWindowRounding = 6.0
	imgui.GetStyle().FrameRounding = 6.0
	
	colors[clr.Text] = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled] = ImVec4(0.73, 0.75, 0.74, 1.00)
	colors[clr.WindowBg] = ImVec4(0.42, 0.48, 0.16, 1.00)
	colors[clr.ChildWindowBg] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border] = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.FrameBg] = ImVec4(0.41, 0.49, 0.24, 0.54)
	colors[clr.FrameBgHovered] = ImVec4(0.26, 0.32, 0.13, 0.54)
	colors[clr.FrameBgActive] = ImVec4(0.33, 0.39, 0.20, 0.54)
	colors[clr.TitleBg] = ImVec4(0.42, 0.48, 0.16, 0.90)
	colors[clr.TitleBgActive] = ImVec4(0.42, 0.48, 0.16, 1.00)
	colors[clr.TitleBgCollapsed] = ImVec4(0.33, 0.44, 0.26, 0.67)
	colors[clr.MenuBarBg] = ImVec4(0.60, 0.67, 0.44, 0.54)
	colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab] = ImVec4(0.42, 0.48, 0.16, 0.54)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.85, 0.98, 0.26, 0.54)
	colors[clr.ScrollbarGrabActive] = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.ComboBg] = colors[clr.PopupBg]
	colors[clr.CheckMark] = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.SliderGrab] = ImVec4(0.35, 0.43, 0.16, 0.84)
	colors[clr.SliderGrabActive] = ImVec4(0.53, 0.53, 0.53, 1.00)
	colors[clr.Button] = ImVec4(0.42, 0.48, 0.16, 0.54)
	colors[clr.ButtonHovered] = ImVec4(0.85, 0.98, 0.26, 0.54)
	colors[clr.ButtonActive] = ImVec4(0.62, 0.75, 0.32, 1.00)
	colors[clr.Header] = ImVec4(0.33, 0.42, 0.15, 0.54)
	colors[clr.HeaderHovered] = ImVec4(0.85, 0.98, 0.26, 0.54)
	colors[clr.HeaderActive] = ImVec4(0.84, 0.66, 0.66, 0.00)
	colors[clr.Separator] = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.SeparatorHovered] = ImVec4(0.43, 0.54, 0.18, 0.54)
	colors[clr.SeparatorActive] = ImVec4(0.52, 0.62, 0.28, 0.54)
	colors[clr.ResizeGrip] = ImVec4(0.66, 0.80, 0.35, 0.54)
	colors[clr.ResizeGripHovered] = ImVec4(0.44, 0.48, 0.34, 0.54)
	colors[clr.ResizeGripActive] = ImVec4(0.37, 0.37, 0.35, 0.54)
	colors[clr.CloseButton] = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.CloseButtonHovered] = ImVec4(0.52, 0.63, 0.26, 0.54)
	colors[clr.CloseButtonActive] = ImVec4(0.81, 1.00, 0.37, 0.54)
	colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered] = ImVec4(0.79, 1.00, 0.32, 0.54)
	colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.TextSelectedBg] = ImVec4(0.26, 0.59, 0.98, 0.35)
	colors[clr.ModalWindowDarkening] = ImVec4(0.80, 0.80, 0.80, 0.35)
	
	
	imgui.GetIO().Fonts:Clear()
	imfonts.mainFont = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\times.ttf', 20.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
	imfonts.smallmainFont = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\times.ttf', 16.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
	
	imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\times.ttf', 14.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
	imgui.RebuildFonts()
end
apply_custom_styles()

function imgui.OnDrawFrame()
	if menu.main.v and script.checked then -- меню скрипта
		imgui.SwitchContext()
		colors[clr.WindowBg] = ImVec4(0.06, 0.06, 0.06, 0.94)
		imgui.PushFont(imfonts.mainFont)
		imgui.ShowCursor = true
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(600, 600), imgui.Cond.FirstUseEver)
		imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
		imgui.Begin(thisScript().name .. (script.available and ' [Доступно обновление: v' .. script.v.num .. ' от ' .. script.v.date .. ']' or ' v' .. script.v.num .. ' от ' .. script.v.date), menu.main, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar)
		local ww = imgui.GetWindowWidth()
		local wh = imgui.GetWindowHeight()
		
		if imgui.Button("Настройки", imgui.ImVec2(290.0, 35.0)) then menu.settings.v = true menu.information.v = false menu.commands.v = false end
		imgui.SameLine()
		if imgui.Button("Информация", imgui.ImVec2(290.0, 35.0)) then menu.settings.v = false menu.information.v = true menu.commands.v = false end
		
		if menu.settings.v and not menu.information.v then
			imgui.BeginChild('settings', imgui.ImVec2(584, 429), true)
			imgui.PushFont(imfonts.smallmainFont)
			imgui.Hotkey("hotkey", "Проверить", 100) imgui.SameLine() imgui.Text("Проверить мемберс\n(мемберс будет автоматически скрыт)")
			if imgui.ToggleButton("rmembers", togglebools['Руководство']) then 
				srpmemb_ini.bools['Руководство'] = togglebools['Руководство'].v
				if srpmemb_ini.bools['Руководство'] then rmembers() end
				inicfg.save(srpmemb_ini, settings)
			end 
			imgui.SameLine() 
			imgui.Text("Отображать должности бойцов Армии LV") 
			imgui.PopFont()
			imgui.EndChild()
		end
		
		if not menu.settings.v and menu.information.v then
			imgui.Text("Данный скрипт является рендером рангов на игроках для проекта Samp RP")
			imgui.Text("Автор: Cody_Webb | Telegram: @Imikhailovich")
			imgui.NewLine()
			imgui.Text("Все настройки автоматически сохраняются в файл:\nmoonloader//config//SRPmembers by Webb//Server//Nick_Name")
			imgui.NewLine()
			imgui.Text("Информация о последних обновлениях:")
			imgui.BeginChild('information', imgui.ImVec2(584, 265), true)
			for k in ipairs(script.upd.sort) do
				if script.upd.changes[tostring(k)] ~= nil then
					imgui.Text(k .. ') ' .. script.upd.changes[tostring(k)])
					imgui.NewLine()
				end
			end
			imgui.EndChild()
		end
		
		if menu.commands.v then
			local cmds = {
				"/memb - открыть/закрыть главное меню скрипта",
				"/getstream - проверить наличие игроков организации в зоне прорисовке",
				"/membup - обновить скрипт",
			}
			local w = 0
			local sortcmds = {}
			for k, v in ipairs(cmds) do table.insert(sortcmds, imgui.CalcTextSize(v).x) end
			table.sort(sortcmds, function(a, b) return a < b end)
			for k, v in ipairs(sortcmds) do
				w = v + 50
			end
			imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
			imgui.SetNextWindowSize(imgui.ImVec2(w, 300), imgui.Cond.FirstUseEver, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar)
			imgui.Begin("Все команды скрипта", menu.commands, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar)
			imgui.Text("Данные команды являются системными, их нельзя изменить:")
			imgui.BeginChild('commands', imgui.ImVec2(w - 15, 235), true)
			for k, v in ipairs(cmds) do imgui.Text(v) end
			imgui.EndChild()
			imgui.End()
		end
		
		imgui.SetCursorPos(imgui.ImVec2(25, wh/2 + 250))
		local found = false
		for i = 0, 1000 do
			if sampIsPlayerConnected(i) and sampGetPlayerScore(i) ~= 0 then
				if sampGetPlayerNickname(i) == "Cody_Webb" then
					if imgui.Button("Cody_Webb[" .. i .. "] сейчас в сети", imgui.ImVec2(260.0, 30.0)) then
						chatManager.addMessageToQueue("/sms " .. i .. " Я пользуюсь твоим скриптом, большое спасибо")
					end
					found = true
				end
			end
		end
		if not found then
			if imgui.Button("Cody Webb сейчас не в сети", imgui.ImVec2(245.0, 30.0)) then
				chatmsg(u8:decode"Cody Webb играет на Revolution (сейчас не онлайн)", main_color)
			end
		end
		
		imgui.PushFont(imfonts.smallmainFont)
		imgui.SetCursorPos(imgui.ImVec2(25, wh/2 + 215))
		if imgui.Button("Все команды скрипта", imgui.ImVec2(170.0, 23.0)) then menu.commands.v = true end
		imgui.SetCursorPos(imgui.ImVec2(ww/2 + 100, wh/2 + 250))
		if imgui.Button("Открыть GitHub", imgui.ImVec2(170.0, 23.0)) then os.execute('explorer "https://github.com/WebbLua/SRPmembers"') end if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted("При нажатии, в браузере по умолчанию откроется ссылка на GitHub скрипта") imgui.EndTooltip() end
		imgui.PopFont()
		
		imgui.End()
		imgui.PopFont()
	end
end
-------------------------------------------------------------------------[ФУНКЦИИ]-----------------------------------------------------------------------------------------
function ev.onServerMessage(col, text)
	if script.loaded then
		if col == -356056833 and text:match("^ Для восстановления доступа нажмите клавишу %'F6%' и введите %'%/restoreAccess%'") then if needtoreload then script.reload = true thisScript():reload() end end
		if col == 1687547391 then
			if text == " " then 
				check.current = {}
				if check.bool then 
					return false 
				end 
			end
			if text:match(u8:decode"^%[ID%]Имя  %{C0C0C0%}Ранг%[Номер%]  %{6495ED%}%[AFK секунд%]  %{C0C0C0%}Бан чата$") then 
				if check.bool then 
					return false
				end 
			end
			local nick, rank, i = text:match("^%[%d+%] (.*)  %{C0C0C0%}(.*) %[(%d+)%]  %{6495ED%}")
			if nick ~= nil and rank ~= nil and tonumber(i) then 
				srpmembers_ini.list[nick] = rank
				check.current[nick] = rank
				check.irank[rank] = tonumber(i)
				if check.boolstream then 
					check.stream[nick] = rank
				end
				inicfg.save(srpmembers_ini, memb)
				if check.bool then
					return false 
				end
			end
		end
		if col == -1061109505 then
			if text:match("^===========================================$") then 
				if check.bool then 
					if check.status then
						check.bool = false
						removeFired()
						if not check.boolstream then
							chatmsg(u8:decode"Успешно проверил мемберс - " .. check.amount .. u8:decode(" человек онлайн"))
							else
							check.boolstream = false
						end
						else
						check.status = true
					end
					return 
					false 
				end 
			end
			local arbeiten, blaumachen = text:match(u8:decode"^Всего на работе%: (%d+) %/ выходные%: (%d+)$")
			if tonumber(arbeiten) ~= nil and tonumber(blaumachen) ~= nil then
				check.amount = tonumber(arbeiten) + tonumber(blaumachen)
				if check.bool then 
					return false 
				end 
			end
		end
		if col == -10270721 then
			if text:match(u8:decode"^%[Выходные%]$") then
				if check.bool then 
					return false 
				end
			end
		end
	end
end

function ev.onShowDialog(dialogid, style, title, button1, button2, text)
	if script.loaded then
		if dialogid == 22 and style == 5 and title == u8:decode"Состав онлайн" then
			for v in text:gmatch('[^\n]+') do 
				local id, nick, rank, i = v:match("%[%d+%] %[(%d+)%] ([%a_]+)	(%W*) %[(%d+)%].*") 
				if nick ~= nil and rank ~= nil and tonumber(i) then 
					srpmembers_ini.list[nick] = rank
					check.current[nick] = rank
					check.irank[rank] = tonumber(i)
					if check.boolstream then 
						check.stream[nick] = rank
					end
					inicfg.save(srpmembers_ini, memb)
				end
			end
		end
	end
end

function ev.onSendChat(message)
	chatManager.lastMessage = message
	chatManager.updateAntifloodClock()
end

function ev.onSendCommand(message)
	chatManager.lastMessage = message
	chatManager.updateAntifloodClock()
end

function members()
	check.bool = true
	check.status = false
	chatManager.addMessageToQueue("/members")
end

function getstream()
	lua_thread.create(function()
		check.stream = {}
		check.bool = true
		check.boolstream = true
		check.status = false
		check.line = 0
		chatManager.addMessageToQueue("/members")
		while check.boolstream do wait(0) end
		for k, v in pairs(check.stream) do
			local id = sampGetPlayerIdByNickname(k)
			if id ~= nil then
				if sampGetCharHandleBySampPlayerId(id) then
					if check.line == 0 then 
						sampAddChatMessage("===========================================", 0xFFBFBFBF) 
						check.line = check.line + 1 
					end
					local clist = "{" .. ("%06x"):format(bit.band(sampGetPlayerColor(id), 0xFFFFFF)) .. "}"
					chatmsg(clist .. k .. "[" .. id .. "] {BFBFBF}" .. v .. (check.irank[v] ~= nil and "[" .. check.irank[v] .. "]" or "") .. (sampIsPlayerPaused(id) and " {008000}[AFK]" or "") .. u8:decode" - в зоне прорисовки")
					check.findstream = true
				end
			end
		end
		if check.line ~= 0 then 
			sampAddChatMessage("===========================================", 0xFFBFBFBF) 
			check.line = 0
		end
		if not check.findstream then chatmsg(u8:decode"Никого не найдено из мемберса!") end
	end)
end

function removeFired()
	for i = 0, 1000 do
		if sampIsPlayerConnected(i) and srpmembers_ini.list[sampGetPlayerNickname(i)] ~= nil then
			if check.current[sampGetPlayerNickname(i)] == nil then
				srpmembers_ini.list[sampGetPlayerNickname(i)] = nil
				inicfg.save(srpmembers_ini, memb)
			end
		end
	end
end

function rmembers() -- взято из rukovodstvo.lua
	check.rmembers = {}
    local temp = os.tmpname()
    local time = os.time()
    downloadUrlToFile("https://docs.google.com/spreadsheets/u/0/d/1hVwvPBD5PJT3CrHvsOIWGtJigGmMT5UfmgZsPJfu_Hk/export?format=tsv", temp, function(_, status)
        if (status == 58) then
            local file = io.open(temp, "r")
            for line in file:lines() do
                line = encoding.UTF8:decode(line)
                local template = "(%w+_%w+)\t(.+)"
                if (line:find(template)) then
                    local name, office = line:match(template)
					check.rmembers[name] = office
				end
			end
            file:close()
            os.remove(temp)
			else
            if (os.time() - time > 10) then
                chatmsg("Превышено время загрузки файла, повторите попытку", 0xFFFFFFFF)
				return
			end
		end
	end)
end

function sampGetPlayerIdByNickname(name)
	local name = tostring(name)
	local _, localId = sampGetPlayerIdByCharHandle(PLAYER_PED)
	for i = 0, 1000 do
		if (sampIsPlayerConnected(i) or localId == i) and sampGetPlayerNickname(i) == name then
			return i
		end
	end
end
-------------------------------------------[ChatManager -> взято из donatik.lua]------------------------------------------
chatManager = {}
chatManager.messagesQueue = {}
chatManager.messagesQueueSize = 1000
chatManager.antifloodClock = os.clock()
chatManager.lastMessage = ""
chatManager.antifloodDelay = 0.8

function chatManager.initQueue() -- очистить всю очередь сообщений
	for messageIndex = 1, chatManager.messagesQueueSize do
		chatManager.messagesQueue[messageIndex] = {
			message = "",
		}
	end
end

function chatManager.addMessageToQueue(string, _nonRepeat) -- добавить сообщение в очередь
	local isRepeat = false
	local nonRepeat = _nonRepeat or false
	
	if nonRepeat then
		for messageIndex = 1, chatManager.messagesQueueSize do
			if string == chatManager.messagesQueue[messageIndex].message then
				isRepeat = true
			end
		end
	end
	
	if not isRepeat then
		for messageIndex = 1, chatManager.messagesQueueSize - 1 do
			chatManager.messagesQueue[messageIndex].message = chatManager.messagesQueue[messageIndex + 1].message
		end
		chatManager.messagesQueue[chatManager.messagesQueueSize].message = string
	end
end

function chatManager.checkMessagesQueueThread() -- проверить поток очереди сообщений
	while true do
		wait(0)
		for messageIndex = 1, chatManager.messagesQueueSize do
			local message = chatManager.messagesQueue[messageIndex]
			if message.message ~= "" then
				if string.sub(chatManager.lastMessage, 1, 1) ~= "/" and string.sub(message.message, 1, 1) ~= "/" then
					chatManager.antifloodDelay = chatManager.antifloodDelay + 0.5
				end
				if os.clock() - chatManager.antifloodClock > chatManager.antifloodDelay then
					
					local sendMessage = true
					
					local command = string.match(message.message, "^(/[^ ]*).*")
					
					if sendMessage then
						chatManager.lastMessage = u8:decode(message.message)
						sampSendChat(u8:decode(message.message))
					end
					
					message.message = ""
				end
				chatManager.antifloodDelay = 0.8
			end
		end
	end
end

function chatManager.updateAntifloodClock() -- обновить задержку из-за определённых сообщений
	chatManager.antifloodClock = os.clock()
	if string.sub(chatManager.lastMessage, 1, 5) == "/sms " or string.sub(chatManager.lastMessage, 1, 3) == "/t " then
		chatManager.antifloodClock = chatManager.antifloodClock + 0.5
	end
end
--------------------------------------------------------------------------------------------------------------------------
textlabel = {}
function textLabelOverPlayerNickname()
	for i = 0, 1000 do
		if textlabel[i] ~= nil then
			sampDestroy3dText(textlabel[i])
			textlabel[i] = nil
		end
	end
	for i = 0, 1000 do 
		if sampIsPlayerConnected(i) and sampGetPlayerScore(i) ~= 0 then
			local nick = sampGetPlayerNickname(i)
			if script.label[nick] ~= nil then
				if textlabel[i] == nil then
					textlabel[i] = sampCreate3dText(u8:decode(script.label[nick].text), tonumber(script.label[nick].color), 0.0, 0.0, 0.8, 21.5, false, i, -1)
				end
			end
			else
			if textlabel[i] ~= nil then
				sampDestroy3dText(textlabel[i])
				textlabel[i] = nil
			end
		end
	end
end

ranklabel = {}
function rankLabelOverPlayerNickname()
	for i = 0, 1000 do
		if ranklabel[i] ~= nil then
			sampDestroy3dText(ranklabel[i])
			ranklabel[i] = nil
		end
	end
	for i = 0, 1000 do 
		if sampIsPlayerConnected(i) and sampGetPlayerScore(i) ~= 0 then
			local nick = sampGetPlayerNickname(i)
			if srpmembers_ini.list[nick] ~= nil then
				if ranklabel[i] == nil then
					ranklabel[i] = sampCreate3dText(srpmembers_ini.list[nick], 0xFFFFFAFA, 0.0, 0.0, 0.4, 22, false, i, -1)
				end
			end
			else
			if ranklabel[i] ~= nil then
				sampDestroy3dText(ranklabel[i])
				ranklabel[i] = nil
			end
		end
	end
end

postlabel = {}
function postLabelOverPlayerNickname()
	for i = 0, 1000 do
		if postlabel[i] ~= nil then
			sampDestroy3dText(postlabel[i])
			postlabel[i] = nil
		end
	end
	for i = 0, 1000 do 
		if sampIsPlayerConnected(i) and sampGetPlayerScore(i) ~= 0 then
			local nick = sampGetPlayerNickname(i)
			if check.rmembers[nick] ~= nil then
				if postlabel[i] == nil then
					postlabel[i] = sampCreate3dText(check.rmembers[nick], 0xFF046901, 0.0, 0.0, 0.3, 22, false, i, -1)
				end
			end
			else
			if postlabel[i] ~= nil then
				sampDestroy3dText(postlabel[i])
				postlabel[i] = nil
			end
		end
	end
end

function chatmsg(t)
	sampAddChatMessage(prefix .. t, main_color)
end

function makeHotKey(numkey)
	local rett = {}
	for _, v in ipairs(string.split(srpmemb_ini.hotkey[numkey], ", ")) do
		if tonumber(v) ~= 0 then table.insert(rett, tonumber(v)) end
	end
	return rett
end

function string.split(str, delim, plain) -- bh FYP
	local tokens, pos, plain = {}, 1, not (plain == false) --[[ delimiter is plain text by default ]]
	repeat
		local npos, epos = string.find(str, delim, pos, plain)
		table.insert(tokens, string.sub(str, pos, npos and npos - 1))
		pos = epos and epos + 1
	until not pos
	return tokens
end

function imgui.Hotkey(name, numkey, width)
	imgui.BeginChild(name, imgui.ImVec2(width, 32), true)
	imgui.PushItemWidth(width)
	
	local hstr = ""
	for _, v in ipairs(string.split(srpmemb_ini.hotkey[numkey], ", ")) do
		if v ~= "0" then
			hstr = hstr == "" and tostring(vkeys.id_to_name(tonumber(v))) or "" .. hstr .. " + " .. tostring(vkeys.id_to_name(tonumber(v))) .. ""
		end
	end
	hstr = (hstr == "" or hstr == "nil") and "Нет клавиши" or hstr
	
	imgui.Text(hstr)
	imgui.PopItemWidth()
	imgui.EndChild()
	if imgui.IsItemClicked() then
		lua_thread.create(
			function()
				local curkeys = ""
				local tbool = false
				while true do
					wait(0)
					if not tbool then
						for k, v in pairs(vkeys) do
							sv = tostring(v)
							if isKeyDown(v) and (v == vkeys.VK_MENU or v == vkeys.VK_CONTROL or v == vkeys.VK_SHIFT or v == vkeys.VK_LMENU or v == vkeys.VK_RMENU or v == vkeys.VK_RCONTROL or v == vkeys.VK_LCONTROL or v == vkeys.VK_LSHIFT or v == vkeys.VK_RSHIFT) then
								if v ~= vkeys.VK_MENU and v ~= vkeys.VK_CONTROL and v ~= vkeys.VK_SHIFT then
									if not curkeys:find(sv) then
										curkeys = tostring(curkeys):len() == 0 and sv or curkeys .. " " .. sv
									end
								end
							end
						end
						
						for k, v in pairs(vkeys) do
							sv = tostring(v)
							if isKeyDown(v) and (v ~= vkeys.VK_MENU and v ~= vkeys.VK_CONTROL and v ~= vkeys.VK_SHIFT and v ~= vkeys.VK_LMENU and v ~= vkeys.VK_RMENU and v ~= vkeys.VK_RCONTROL and v ~= vkeys.VK_LCONTROL and v ~= vkeys.VK_LSHIFT and v ~=vkeys. VK_RSHIFT) then
								if not curkeys:find(sv) then
									curkeys = tostring(curkeys):len() == 0 and sv or curkeys .. " " .. sv
									tbool = true
								end
							end
						end
						else
						tbool2 = false
						for k, v in pairs(vkeys) do
							sv = tostring(v)
							if isKeyDown(v) and (v ~= vkeys.VK_MENU and v ~= vkeys.VK_CONTROL and v ~= vkeys.VK_SHIFT and v ~= vkeys.VK_LMENU and v ~= vkeys.VK_RMENU and v ~= vkeys.VK_RCONTROL and v ~= vkeys.VK_LCONTROL and v ~= vkeys.VK_LSHIFT and v ~=vkeys. VK_RSHIFT) then
								tbool2 = true
								if not curkeys:find(sv) then
									curkeys = tostring(curkeys):len() == 0 and sv or curkeys .. " " .. sv
								end
							end
						end
						
						if not tbool2 then break end
					end
				end
				
				local keys = ""
				if tonumber(curkeys) == vkeys.VK_BACK then
					srpmemb_ini.hotkey[numkey] = "0"
					else
					local tNames = string.split(curkeys, " ")
					for _, v in ipairs(tNames) do
						local val = (tonumber(v) == 162 or tonumber(v) == 163) and 17 or (tonumber(v) == 160 or tonumber(v) == 161) and 16 or (tonumber(v) == 164 or tonumber(v) == 165) and 18 or tonumber(v)
						keys = keys == "" and val or "" .. keys .. ", " .. val .. ""
					end
				end
				
				srpmemb_ini.hotkey[numkey] = keys
				inicfg.save(srpmemb_ini, settings)
			end
		)
	end
end

function checkUpdates() -- проверка обновлений
	local fpath = os.tmpname()
	if doesFileExist(fpath) then os.remove(fpath) end
	downloadUrlToFile("https://raw.githubusercontent.com/WebbLua/SRPmembers/main/version.json", fpath, function(_, status, _, _)
		if status == 58 then
			if doesFileExist(fpath) then
				local file = io.open(fpath, 'r')
				if file then
					local info = decodeJson(file:read('*a'))
					file:close()
					os.remove(fpath)
					script.v.num = info.version_num
					script.v.date = info.version_date
					script.url = info.version_url
					script.label = info.version_label
					script.upd.changes = info.version_upd
					if script.upd.changes then
						for k in pairs(script.upd.changes) do
							table.insert(script.upd.sort, k)
						end
						table.sort(script.upd.sort, function(a, b) return a > b end)
					end
					script.checked = true
					if info['version_num'] > thisScript()['version_num'] then
						script.available = true
						if script.update then updateScript() return end
						chatmsg(updatingprefix .. u8:decode"Обнаружена новая версия скрипта от " .. info['version_date'] .. u8:decode", пропишите /srpmembup для обновления")
						chatmsg(updatingprefix .. u8:decode"Изменения в новой версии:")
						if script.upd.sort ~= {} then
							for k in ipairs(script.upd.sort) do
								if script.upd.changes[tostring(k)] ~= nil then
									chatmsg(updatingprefix .. k .. ') ' .. u8:decode(script.upd.changes[tostring(k)]))
								end
							end
						end
						return true
						else
						if script.update then chatmsg(u8:decode"Обновлений не обнаружено, вы используете самую актуальную версию: v" .. script.v.num .. u8:decode" за " .. script.v.date) script.update = false return end
					end
					else
					chatmsg(u8:decode"Не удалось получить информацию про обновления(")
					thisScript():unload()
				end
				else
				chatmsg(u8:decode"Не удалось получить информацию про обновления(")
				thisScript():unload()
			end
		end
	end)
end

function updateScript()
	script.update = true
	if script.available then
		downloadUrlToFile(script.url, thisScript().path, function(_, status, _, _)
			if status == 6 then
				chatmsg(updatingprefix .. u8:decode"Скрипт был обновлён!")
				if script.find("ML-AutoReboot") == nil then
					thisScript():reload()
				end
			end
		end)
		else
		checkUpdates()
	end
end

function onScriptTerminate(s, bool)
	if s == thisScript() and not bool then
		for i = 0, 1000 do
			if textlabel[i] ~= nil then
				sampDestroy3dText(textlabel[i])
				textlabel[i] = nil
			end
			if ranklabel[i] ~= nil then
				sampDestroy3dText(ranklabel[i])
				ranklabel[i] = nil
			end
			if postlabel[i] ~= nil then
				sampDestroy3dText(postlabel[i])
				postlabel[i] = nil
			end
		end
		if not script.reload then
			if not script.update then
				if not script.unload then
					chatmsg(u8:decode"Скрипт крашнулся: откройте консоль sampfuncs (кнопка ~), скопируйте текст ошибки и отправьте разработчику")
					else
					chatmsg(u8:decode"Скрипт был выгружен")
				end
				else
				chatmsg(updatingprefix .. u8:decode"Старый скрипт был выгружен, загружаю обновлённую версию...")
			end
			else
			chatmsg(u8:decode"Перезагружаюсь...")
		end
	end
end			