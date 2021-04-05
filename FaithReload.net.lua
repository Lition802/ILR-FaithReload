

if(not(tool:IfDir('./plugins/ilua/faith/')))then
	tool:CreateDir('./plugins/ilua/faith/')
end
if(not(tool:IfFile('./plugins/ilua/faith/nickname.json')))then
	tool:WriteAllText('./plugins/ilua/faith/nickname.json','{\n\t"§2N§3M§4S§eL":200,\n\t"§eCreeper!":150\n}')
end
if(not(tool:IfFile('./plugins/ilua/faith/data.json')))then
	tool:WriteAllText('./plugins/ilua/faith/data.json','{}')
end
if(not(tool:IfFile('./plugins/ilua/faith/onuse.json')))then
	tool:WriteAllText('./plugins/ilua/faith/onuse.json','{}')
end

local json = require("./plugins/ilua/Lib/dkjson")
local data = json.decode(tool:ReadAllText('./plugins/ilua/faith/data.json')) --玩家称号总文件
local onuse = json.decode(tool:ReadAllText('./plugins/ilua/faith/onuse.json')) --记录玩家当前使用称号
local nicks = json.decode(tool:ReadAllText('./plugins/ilua/faith/nickname.json')) --可购买的称号
local formid = {} --表单id
local page = {} --玩家所在页面
local adchose = {} --管理员编辑称号时用

--获取玩家所拥有的称号,返回table
local function getplnicktable(pln)
	return data[pln]
end

--获取所有可购买的称号,返回table
local function getnametbale()
	local nmsl = {}
	for k,v in pairs(nicks)do
		table.insert(nmsl,k)
	end
	return nmsl
end

--获取称号对应的金额
local function checkmoney(num)
	return getnametbale()[num]
end

--判断玩家是否为op
function IfOP(plxuid)
	local pre = json.decode(tool:ReadAllText('permissions.json'))
	for key,value in pairs(pre)do
		if(value['xuid'] == plxuid)then
			if(value['permission'] == 'operator')then
				return true
			end
		end
	end
	return false
end

--判断玩家是否购买过此称号
local function checkifbuy(num,pln)
	local nick = getnametbale()[num]
	for k,v in pairs(data[pln])do
		if(v == nick)then
			return true
		end
	end
	return false
end

function faith_inputcmd(a)
	if(a.cmd == '/faith gui')then
		local gui = luaapi:createGUI('§3faith§r称号系统')
		gui:AddDropdown('选择操作称号',0,json.encode(getnametbale()))
		gui:AddToggle("打开为购买，关闭为穿戴")
		page[a.playername] = 'main'
		formid[a.playername] = gui:SendToPlayer(luaapi:GetUUID(a.playername))
		return false
	elseif(a.cmd == '/faith help')then
		local msg = '§e---------§b[§r帮助§b]§e---------\n§2/faith §e- §b称号购买面板\n§2/faith list §e- §b查看已有称号\n§2/faith view §e- §b查看当前使用的称号\n'
		mc:sendText(luaapi:GetUUID(a.playername),msg)
		return false
	elseif(a.cmd == '/faith list')then
		page[a.playername] = 'chose'
		formid[a.playername] = mc:sendSimpleForm(luaapi:GetUUID(a.playername),'个人称号查看','',json.encode(getplnicktable(a.playername)))
		return false
	elseif(a.cmd == '/faith view')then
		mc:sendText(luaapi:GetUUID(a.playername),'[§3faith§r] §2你正在使用的称号为:'..onuse[a.playername])
		return false
	elseif(a.cmd == '/faith admin')then
		if(IfOP(luaapi:GetXUID(a.playername)))then
			page[a.playername] = 'admin'
			formid[a.playername] = mc:sendSimpleForm(luaapi:GetUUID(a.playername),'faith管理面板','来点什么?','["添加称号","管理称号"]')
		else
			mc:sendText(luaapi:GetUUID(a.playername),'[§3faith§r] §4你不是服务器的管理员!')
		end
		return false
	end
end

function faith_select(a)
	if(a.formid == formid[a.playername])and(a.selected ~= 'null')then
		if(page[a.playername] == 'main')then --主菜单
			se = json.decode(a.selected)
			if(not(se[2]))then
				if(checkifbuy(se[1]+1,a.playername))then
					onuse[a.playername] = getnametbale()[se[1]+1]
					tool:WriteAllText('./plugins/ilua/faith/onuse.json',json.encode(onuse,{indent=true}))
					mc:sendText(a.uuid,'[§3faith§r] §2称号切换成功！当前称号:'..onuse[a.playername])
				else
					mc:sendText(a.uuid,'[§3faith§r] §4你还没有这个称号！')
				end
			else
				if(checkifbuy(se[1]+1,a.playername))then
					mc:sendText(a.uuid,'[§3faith§r] §4你已经有这个称号了！')
				else
					if(not(tonumber(mc:getscoreboard(a.uuid,'money')) < nicks[checkmoney(se[1]+1)]))then
						table.insert(data[a.playername],getnametbale()[se[1]+1])
						tool:WriteAllText('./plugins/ilua/faith/data.json',json.encode(data,{indent=true}))
						mc:runcmd('scoreboard players remove"'..a.playername..'" '..'money'..' '..nicks[checkmoney(se[1]+1)])
						mc:sendText(a.uuid,'[§3faith§r] §2称号购买成功！')
					else
						mc:sendText(a.uuid,'[§3faith§r] '..string.gsub("§4你钱不够！至少需要{money}金币",'{money}',tostring(nicks[checkmoney(se[1]+1)])))
					end
				end
			end
		elseif(page[a.playername] == 'chose')then --faith list菜单
			onuse[a.playername] = getplnicktable(a.playername)[tonumber(a.selected)+1]
			tool:WriteAllText('./plugins/ilua/faith/onuse.json',json.encode(onuse,{indent=true}))
			mc:sendText(a.uuid,'[§3faith§r] §2称号切换成功！当前称号:'..onuse[a.playername])
		elseif(page[a.playername] == 'admin')then --管理员菜单
			local se = tonumber(a.selected)
			if(se == 0)then
				local gui = luaapi:createGUI('添加称号')
				gui:AddInput('输入称号','写在这里')
				gui:AddInput('输入价格','务必写入数字')
				page[a.playername] = 'admin_add'
				formid[a.playername] = gui:SendToPlayer(a.uuid)
			elseif(se == 1)then
				page[a.playername] = 'admin_chose'
				formid[a.playername] = mc:sendSimpleForm(a.uuid,'称号管理','',json.encode(getnametbale()))
			end
		elseif(page[a.playername] == 'admin_add')then --管理员添加称号
			local se = json.decode(a.selected)
			if(tonumber(se[2]) ~= nil)then
				nicks[se[1]] = tonumber(se[2])
				tool:WriteAllText('./plugins/ilua/faith/nickname.json',json.encode(nicks,{indent=true}))
				mc:sendText(a.uuid,'[§3faith§r] §2添加成功!')
			else
				mc:sendText(a.uuid,'[§3faith§r] §4输入的格式有错误!')
			end
		elseif(page[a.playername] == 'admin_chose')then --管理员选择所要编辑的称号
			local se = tonumber(a.selected)
			local nick = getnametbale()[se+1]
			adchose[a.playername] = nick
			page[a.playername] = 'admin_chose2'
			local msg = '选中项:'..nick.."\n§r价格:"..nicks[nick]
			formid[a.playername] = mc:sendSimpleForm(a.uuid,'称号管理',msg,'["修改价格","移除此称号"]')
		elseif(page[a.playername] == 'admin_chose2')then --管理员编辑选中称号
			local se = tonumber(a.selected)
			if(se == 0)then
				local gui = luaapi:createGUI('修改称号价格')
				gui:AddInput('输入价格','务必输入数字')
				page[a.playername] = 'admin_change_money'
				formid[a.playername] = gui:SendToPlayer(a.uuid)
			elseif(se == 1)then
				nicks[adchose[a.playername]] = nil
				tool:WriteAllText('./plugins/ilua/faith/nickname.json',json.encode(nicks,{indent=true}))
				mc:sendText(a.uuid,'[§3faith§r] '..adchose[a.playername]..'§r项已被删除')
			end
		elseif(page[a.playername] == 'admin_change_money')then --管理员修改选中称号价格
			local se = json.decode(a.selected)
			if(tonumber(se[1]) ~= nil)then
				nicks[adchose[a.playername]] = tonumber(se[1])
				tool:WriteAllText('./plugins/ilua/faith/nickname.json',json.encode(nicks,{indent=true}))
				mc:sendText(a.uuid,'[§3faith§r] §2修改成功!')
			else
				mc:sendText(a.uuid,'[§3faith§r] §4输入的格式有错误!')
			end
		end
	end
end

--加载名字时判断玩家拥有称号是否为空
--为空则新建table
--防止查看自己所拥有的称号时出错
function faith_lname(a)
	if(data[a.playername] == nil)then
		data[a.playername] = {}
	end
end

function faith_chat(a)
	if(not(onuse[a.playername] == nil))then
		local shat = '<['..onuse[a.playername]..'§r]'..a.playername..'> '..a.msg
		mc:runcmd('tellraw @a {"rawtext":[{"text":"'..shat..'"}]}')
		print('{['..os.date('%Y-%m-%d %H:%M:%S')..' Chat] 玩家 ['..onuse[a.playername]..']'..a.playername..' 说:'..a.msg)
		return false
	end
end
luaapi:Listen('onFormSelect',faith_select)
luaapi:Listen('onInputText',faith_chat)
luaapi:Listen('onInputCommand',faith_inputcmd)
luaapi:Listen('onLoadName',faith_lname)
mc:setCommandDescribe('faith', '称号系统')
mc:setCommandDescribe('faith gui', '打开称号面板')
mc:setCommandDescribe('faith help', '帮助')
mc:setCommandDescribe('faith list','查看自己所有称号')
mc:setCommandDescribe('faith admin','称号管理')
mc:setCommandDescribe('faith view','查看当前称号')
local logo = [[  _____     _ _   _     
 |  ___|_ _(_) |_| |__  
 | |_ / _` | | __| '_ \ 
 |  _| (_| | | |_| | | |
 |_|  \__,_|_|\__|_| |_|
                       ]]
print(logo)
print('[INFO] [FaithReload] 装载成功!')
print('[INFO] [FaithReload] version = 1.0.0!')