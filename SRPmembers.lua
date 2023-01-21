script_name('SRPmembers')
script_author("Cody_Webb | Telegram: @Imikhailovich")
script_version("20.01.2023")
script_version_number(1)
local script = {checked = false, available = false, update = false, v = {date, num}, url, reload, loaded, unload, quest = {}, upd = {changes = {}, sort = {}}, label = {}}
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
		['Должность'] = false
	},
	hotkey = {
		['Проверить'] = "0"
	}
}
local members = {
}
-------------------------------------------------------------------------[Переменные и маcсивы]-----------------------------------------------------------------
local main_color = 0x41491d
local prefix = "{41491d}[SRPmembers] {FFFAFA}"
local updatingprefix = u8:decode"{FF0000}[ОБНОВЛЕНИЕ] {FFFAFA}"
local antiflood = 0

local menu = { -- imgui-меню
	main = imgui.ImBool(false)
}
imgui.ShowCursor = false

local style = imgui.GetStyle()
local colors = style.Colors
local clr = imgui.Col
local currentNick
local suspendkeys = 2 -- 0 хоткеи включены, 1 -- хоткеи выключены -- 2 хоткеи необходимо включить
local ImVec4 = imgui.ImVec4
local imfonts = {mainFont = nil}
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
		srpmembers_ini = inicfg.load(members, memb)
		inicfg.save(srpmembers_ini, memb)
	end
	
	togglebools = {
		['Должность'] = srpmemb_ini.bools['Должность'] and imgui.ImBool(true) or imgui.ImBool(false)
	}
	
	sampRegisterChatCommand("srpmemb", function() 
		for k, v in pairs(srpmemb_ini.hotkey) do 
			local hk = makeHotKey(k) 
			if tonumber(hk[1]) ~= 0 then 
				rkeys.unRegisterHotKey(hk) 
			end 
		end
		suspendkeys = 1 
		menu.main.v = not menu.main.v 
	end)
	sampRegisterChatCommand('srpmembup', updateScript)
	
	script.loaded = true
	repeat wait(0) until sampIsLocalPlayerSpawned()
	checkUpdates()
	chatmsg(u8:decode"Скрипт запущен. Открыть главное меню - /srpmemb")
	needtoreload = true
	
	imgui.Process = true
	imgui.ShowCursor = false
	
	
	chatManager.initQueue()
	lua_thread.create(chatManager.checkMessagesQueueThread)
	while true do
		wait(0)
		if suspendkeys == 2 then
			rkeys.registerHotKey(makeHotKey("Проверка"), true, function() if sampIsChatInputActive() or sampIsDialogActive(-1) or isSampfuncsConsoleActive() then return end members() end)
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
	
	imfonts.ovFontCars = renderCreateFont("times", 14, 12)
	imfonts.ovFontSquadRender = renderCreateFont("times", 11, 12)
	
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
		imgui.SetNextWindowSize(imgui.ImVec2(400, 600), imgui.Cond.FirstUseEver)
		imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
		imgui.Begin(thisScript().name .. (script.available and ' [Доступно обновление: v' .. script.v.num .. ' от ' .. script.v.date .. ']' or ' v' .. script.v.num .. ' от ' .. script.v.date), menu.main, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar)
		local ww = imgui.GetWindowWidth()
		local wh = imgui.GetWindowHeight()
		
		imgui.SetCursorPos(imgui.ImVec2(ww/2 - 568, wh/2 - 320))
		if imgui.Button("Автоматические действия", imgui.ImVec2(280.0, 35.0)) then menu.automatic.v = true menu.commands.v = false menu.binds.v = false menu.overlay.v = false menu.information.v = false menu.binder.v = false  menu.password.v = false menu.inventory.v = false menu.editor.v = false menu.variables.v = false end
		imgui.SameLine()
		if imgui.Button("Клавиши и команды", imgui.ImVec2(280.0, 35.0)) then menu.automatic.v = false menu.commands.v = false menu.binds.v = true menu.overlay.v = false menu.information.v = false menu.binder.v = false  menu.password.v = false menu.inventory.v = false menu.editor.v = false menu.variables.v = false end
		imgui.SameLine()
		if imgui.Button("Overlay", imgui.ImVec2(280.0, 35.0)) then menu.automatic.v = false menu.commands.v = false menu.binds.v = false menu.overlay.v = true menu.information.v = false menu.binder.v = false  menu.password.v = false menu.inventory.v = false menu.editor.v = false menu.variables.v = false end
		imgui.SameLine()
		if imgui.Button("Кастомный биндер", imgui.ImVec2(280.0, 35.0)) then currentBind = nil menu.automatic.v = false menu.commands.v = false menu.binds.v = false menu.overlay.v = false menu.information.v = false menu.binder.v = true menu.password.v = false menu.inventory.v = false menu.editor.v = false menu.variables.v = false end
		
		imgui.End()
		imgui.PopFont()
	end
end
-------------------------------------------------------------------------[ФУНКЦИИ]-----------------------------------------------------------------------------------------
function ev.onServerMessage(col, text)
	if script.loaded then
		if col == 1687547391 then
			if text == "  " then return false end
			if text:match("^%[ID%]Имя  %{C0C0C0%}Ранг%[Номер%]  %{6495ED%}%[AFK секунд%]  %{C0C0C0%}Бан чата$") then return false end
			local nick, rank = text:match("^%[%d+%] (.*)  %{C0C0C0%}(.*) %[%d+%]  %{6495ED%}")
			if nick ~= nil and rank ~= nil then 
				srpmemb_ini[nick] = rank
				return false
			end
		end
		if col == -1061109505 then
			if text:match("^===========================================$") then return false end
		end
		if col == -10270721 then
			if text:match("^%[Выходные%]$") then
				return false
			end
		end
		inicfg.save(srpmemb_ini, settings)
	end
end

-- [ML] (script) SpecialFunctions.lua:     1687547391
-- [ML] (script) SpecialFunctions.lua: [ID]Имя  Ранг[Номер]  [AFK секунд]  Бан чата   1687547391
-- [ML] (script) SpecialFunctions.lua: ===========================================   -1061109505
-- [ML] (script) SpecialFunctions.lua: [9] Luis_Havertz  Ефрейтор [2]     1687547391
-- [ML] (script) SpecialFunctions.lua: [20] Cameron_Rayson  Полковник [14]     1687547391
-- [ML] (script) SpecialFunctions.lua: [36] Micha_Dirol  Ефрейтор [2]     1687547391
-- [ML] (script) SpecialFunctions.lua: [91] Dima_Travokur  Рядовой [1]  [AFK: 442]   1687547391
-- [ML] (script) SpecialFunctions.lua: [114] Vana_Grelon  Ефрейтор [2]     1687547391
-- [ML] (script) SpecialFunctions.lua: [146] Wiliam_Djons  Ст.Лейтенант [10]     1687547391
-- [ML] (script) SpecialFunctions.lua: [180] Joe_Santos  Мл.сержант [3]     1687547391
-- [ML] (script) SpecialFunctions.lua: [201] Maik_Leslie  Подполковник [13]     1687547391
-- [ML] (script) SpecialFunctions.lua: [204] Liam_Antonio  Прапорщик [7]     1687547391
-- [ML] (script) SpecialFunctions.lua: [208] Dwaune_Johnson  Сержант [4]     1687547391
-- [ML] (script) SpecialFunctions.lua: [226] Foma_Harison  Ефрейтор [2]     1687547391
-- [ML] (script) SpecialFunctions.lua: [239] Misato_Katsuragi  Мл.сержант [3]  [SLEEP|AFK: 5502|5501]   1687547391
-- [ML] (script) SpecialFunctions.lua: [251] Enzo_Elesteroff  Рядовой [1]     1687547391
-- [ML] (script) SpecialFunctions.lua: [252] Jack_Green  Сержант [4]     1687547391
-- [ML] (script) SpecialFunctions.lua: [263] Federico_Boune  Мл.Лейтенант [8]     1687547391
-- [ML] (script) SpecialFunctions.lua: [278] Joseph_Lis  Капитан [11]     1687547391
-- [ML] (script) SpecialFunctions.lua: [303] Dom_Estos  Старшина [6]     1687547391
-- [ML] (script) SpecialFunctions.lua: [379] Sashka_Dias  Ефрейтор [2]     1687547391
-- [ML] (script) SpecialFunctions.lua: [393] Julie_Escobar  Капитан [11]     1687547391
-- [ML] (script) SpecialFunctions.lua: [394] Luke_Evans  Ст.сержант [5]     1687547391
-- [ML] (script) SpecialFunctions.lua: [401] Ken_Deloroza  Ст.сержант [5]     1687547391
-- [ML] (script) SpecialFunctions.lua: [441] Alex_Mori  Рядовой [1]     1687547391
-- [ML] (script) SpecialFunctions.lua: [Выходные]   -10270721
-- [ML] (script) SpecialFunctions.lua: [3] Dennis_Dias  Сержант [4]     1687547391
-- [ML] (script) SpecialFunctions.lua: [53] Lavrentiy_Beria  Ст.Лейтенант [10]     1687547391
-- [ML] (script) SpecialFunctions.lua: [164] Hector_Gray  Сержант [4]     1687547391
-- [ML] (script) SpecialFunctions.lua: [211] Nikolay_Kapustin  Мл.сержант [3]  [SLEEP|AFK: 1580|1576]   1687547391
-- [ML] (script) SpecialFunctions.lua: [249] Joe_Mod  Старшина [6]     1687547391
-- [ML] (script) SpecialFunctions.lua: [264] Obiram_Antonio  Старшина [6]     1687547391
-- [ML] (script) SpecialFunctions.lua: [646] Daniil_Puchkov  Лейтенант [9]  [SLEEP|AFK: 12791|12741]   1687547391
-- [ML] (script) SpecialFunctions.lua: Всего на работе: 22 / выходные: 7   -1061109505
-- [ML] (script) SpecialFunctions.lua: ===========================================   -1061109505

function ev.onSendChat(message)
	chatManager.lastMessage = message
	chatManager.updateAntifloodClock()
end

function ev.onSendCommand(message)
	chatManager.lastMessage = message
	chatManager.updateAntifloodClock()
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
	for i = 0, 999 do
		if textlabel[i] ~= nil then
			sampDestroy3dText(textlabel[i])
			textlabel[i] = nil
		end
	end
	for i = 0, 999 do 
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
		for i = 0, 999 do
			if textlabel[i] ~= nil then
				sampDestroy3dText(textlabel[i])
				textlabel[i] = nil
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