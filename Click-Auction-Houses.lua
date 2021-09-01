--[[
      _             _  _          _                         _        _
     | |           (_)| |        (_)                       (_)      | |
   __| | _ __ ___   _ | |_  _ __  _  _   _   ___ __      __ _   ___ | |__
  / _` || '_ ` _ \ | || __|| '__|| || | | | / _ \\ \ /\ / /| | / __|| '_ \
 | (_| || | | | | || || |_ | |   | || |_| ||  __/ \ V  V / | || (__ | | | |
  \__,_||_| |_| |_||_| \__||_|   |_| \__, | \___|  \_/\_/  |_| \___||_| |_|
                                      __/ |
                                     |___/                                 ]]


script_name("Click-Auction-Houses")
script_author("dmitriyewich")
script_url("https://vk.com/dmitriyewichmods")
script_dependencies("ffi", "memory", "encoding")
script_properties('work-in-pause', 'forced-reloading-only')
script_version("0.1")

local ffi = require 'ffi'
local memory = require 'memory'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

house = {}
hauc = false

local servers = { -- список серверов, где работает
	['185.169.134.45'] = true, -- Brainburg
	['185.169.134.166'] = true, -- Prescott
	['185.169.134.172'] = true, -- Kingman
	['185.169.134.44'] = true, -- Chandler
	['185.169.134.171'] = true, -- Glendale
	['185.169.134.109'] = true, -- Surprise
	['185.169.134.61'] = true, -- Red-Rock
	['185.169.134.3'] = true, -- Phoenix
	['185.169.134.5'] = true, -- Saint-Rose
	['185.169.134.107'] = true, -- Yuma
	['185.169.134.4'] = true, -- Tucson
	['185.169.134.43'] = true, -- Scottdale
	['185.169.134.59'] = true, -- Mesa
	['185.169.134.173'] = true, -- Winslow
	['185.169.134.174'] = true, -- Payson
	['80.66.82.191'] = true, -- Gilbert
	['80.66.82.190'] = true -- Show Low
}

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    while not isSampAvailable() do wait(100) end
	
	font = renderCreateFont('Tahoma', 10, 5)
	
	local ip = sampGetCurrentServerAddress()
	if servers[ip] ~= true then thisScript():unload() end

	sampRegisterChatCommand('hauc', function(arg)
		if arg == nil or arg == "" then -- может придумаю аргументы в след. обновле, если она будет.
			hauc = not hauc
		end
    end)
	sampSetClientCommandDescription("hauc", string.format(u8:decode"Включает рендер домов, Файл: %s", thisScript().filename))

	while true do wait(0)
		if #house >= 2 and hauc then
			for k, v in pairs(house) do
				if v.dom_name ~= nil then
					if timerStart then
						local showtime = v.yimer_tye - (os.time() - timerStart)
						if showtime > 0 then
							local text = u8:decode"Дом {FFFFFF}№" .. v.dom_name .. u8:decode"{BEBEBE} Осталось времени: {FFFFFF}" .. FormatTime(showtime) .. u8:decode"{BEBEBE} Текущая цена: {FFFFFF}" .. v.teckush_stavka_name .. u8:decode"{BEBEBE} Мин. ставка: {FFFFFF}" .. v.min_stavka_name
							if drawClickableText(font, text, convert_x(10), convert_y(120+(k*8)), 0xFFBEBEBE, 0xFFFF0000) then
								sampSendChat('/findihouse '..v.dom_name)
							end
						end
					end
				end
			end
		end

	end
end

function comma_value(n) -- by vrld
	return n:reverse():gsub("(%d%d%d)", "%1%."):reverse():gsub("^%.?", "")
end

function separator(text)
    if text:find("%$%d+") then
        for S in string.gmatch(text, "%$%d+") do
			S = string.sub(S, 2, #S)
            text = text.gsub(text, S, comma_value(S))
        end
	end
    return text
end

function FormatTime(time)
	return os.date((os.date("%H", time) == os.date("%H") and '%M:%S' or '%H:%M:%S'), time)
end

function convert_x(x)
	local gposX, gposY = convertGameScreenCoordsToWindowScreenCoords(x, x)
	return gposX
end

function convert_y(y)
	local gposX, gposY = convertGameScreenCoordsToWindowScreenCoords(y, y)
	return gposY
end

function drawClickableText(font, text, posX, posY, color, colorA)
	renderFontDrawText(font, text, posX, posY, color)
	local textLenght = renderGetFontDrawTextLength(font, text)
	local textHeight = renderGetFontDrawHeight(font)
	local curX, curY = getCursorPos()
	if curX >= posX and curX <= posX + textLenght and curY >= posY and curY <= posY + textHeight then
		renderFontDrawText(font, text, posX, posY, colorA)
		if wasKeyPressed(1) then
			return true
		end
	end
end

function onReceiveRpc(id,bs)
    if id == 61 then -- RPC_SCRSHOWDIALOG
        local rpcData = {
            dialogId = raknetBitStreamReadInt16(bs),
            style = raknetBitStreamReadInt8(bs),
            title = raknetBitStreamReadString(bs, raknetBitStreamReadInt8(bs)),
            button1 = raknetBitStreamReadString(bs, raknetBitStreamReadInt8(bs)),
            button2 = raknetBitStreamReadString(bs, raknetBitStreamReadInt8(bs)),
            text = raknetBitStreamDecodeString(bs, 4096)
        }

		if string.match(rpcData.title, u8:decode"Дома на аукционе") then

			house = {}
			----------------------------------------------------
			for line in rpcData.text:gmatch(u8:decode"[^\n]+") do
				dom, yimer, teckush_stavka, min_stavka = line:match(u8:decode"Дом №(%d+)\t(.+)\t(.+)\t(.+)")
				if dom ~= nil then

				if #split(yimer, ':') == 3 then
					h, m, s = split(yimer, ':')[1], split(yimer, ':')[2], split(yimer, ':')[3]
					if tonumber(h) > 10 then
						h = "0"..h
					end
				end
				if #split(yimer, ':') == 2 then
					h = os.date("%H")
					m = split(yimer, ':')[1]
					s = split(yimer, ':')[2]
				end

				datetime = { year = os.date("%Y"), month = os.date("%m"), day = os.date("%d"), hour = h, min = m, sec = s}
				seconds_since_epoch = os.time(datetime)

				timerStart = os.time()
				timerState = true

				table.insert(house, { dom_name = dom, yimer_name = yimer, yimer_tye = seconds_since_epoch, teckush_stavka_name = separator(teckush_stavka), min_stavka_name = (min_stavka) })
				end
			end
			----------------------------------------------------

			----------------------------------------------------
			dialog_thread = lua_thread.create(function()
				while true do wait(0)
					if not sampIsChatInputActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() and wasKeyPressed(13) then
						sampSendChat("/findihouse "..house[sampGetCurrentDialogListItem()+1].dom_name)
					end
					if not sampIsDialogActive() then
						dialog_thread:terminate()
					end
				end
			end)
			----------------------------------------------------

		end
	end
end

function sampGetCurrentDialogListItem()
    local list = getStructElement(sampGetDialogInfoPtr(), 0x20, 4)
    return getStructElement(list, 0x143, 4)
end

function split(str, delim, plain)
    local tokens, pos, plain = {}, 1, not (plain == false) --[[ delimiter is plain text by default ]]
    repeat
        local npos, epos = string.find(str, delim, pos, plain)
        table.insert(tokens, string.sub(str, pos, npos and npos - 1))
        pos = epos and epos + 1
    until not pos
    return tokens
end

-- Licensed under the MIT License
-- Copyright (c) 2021, dmitriyewich <https://github.com/dmitriyewich/Click-Auction-Houses>