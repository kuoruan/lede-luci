--[[
luci for Gargoyle QoS
Based on GuoGuo's luci-app-qos-guoguo
Copyright (c) 2017 Xingwang Liao <kuoruan@gmail.com>
]]--

local wa  = require "luci.tools.webadmin"
local uci = require "luci.model.uci".cursor()
local dsp = require "luci.dispatcher"

local m, s, o
local upload_classes = {}
local qos_gargoyle = "qos_gargoyle"

uci:foreach(qos_gargoyle, "upload_class", function(s)
	local class_alias = s.name
	if class_alias then
		upload_classes[#upload_classes + 1] = {name = s[".name"], alias = class_alias}
	end
end)

m = Map(qos_gargoyle, translate("Upload Settings"))

s = m:section(TypedSection, "upload_class", translate("Service Classes"),
	translate("Each upload service class is specified by three parameters: percent bandwidth at "
	.. "capacity, minimum bandwidth and maximum bandwidth."))
s.anonymous = true
s.addremove = true
s.template  = "cbi/tblsection"
s.extedit   = dsp.build_url("admin/services/qos_gargoyle/upload_class/%s")
s.create    = function(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(s.extedit % sid)
		return
	end
end

o = s:option(DummyValue, "name", translate("Class Name"))
o.cfgvalue = function(...)
	return Value.cfgvalue(...) or translate("None")
end

o = s:option(DummyValue, "percent_bandwidth", translate("Percent bandwidth at capacity"))
o.cfgvalue = function(...)
	local v = Value.cfgvalue(...)
	return v and v .. " %" or translate("Not set")
end

o = s:option(DummyValue, "min_bandwidth", translate("Minimum bandwidth"))
o.cfgvalue = function(...)
	local v = Value.cfgvalue(...)
	return v and v .. " kbit/s" or "0"
end

o = s:option(DummyValue, "max_bandwidth", translate("Maximum bandwidth"))
o.cfgvalue = function(...)
	local v = Value.cfgvalue(...)
	return v and v .. " kbit/s" or translate("Unlimited")
end

s = m:section(TypedSection, "upload_rule",translate("Classification Rules"),
	translate("Packets are tested against the rules in the order specified -- rules toward the top "
	.. "have priority. As soon as a packet matches a rule it is classified, and the rest of the rules "
	.. "are ignored. The order of the rules can be altered using the arrow controls.")
)
s.addremove = true
s.sortable  = true
s.anonymous = true
s.template  = "cbi/tblsection"
s.extedit   = dsp.build_url("admin/services/qos_gargoyle/upload_rule/%s")
s.create    = function(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(s.extedit % sid)
		return
	end
end

o = s:option(ListValue, "class", translate("Service Class"))
for _, s in ipairs(upload_classes) do o:value(s.name, s.alias) end

o = s:option(Value, "proto", translate("Transport Protocol"))
o:value("", translate("All"))
o:value("tcp", "TCP")
o:value("udp", "UDP")
o:value("icmp", "ICMP")
o:value("gre", "GRE")
o.write = function(self, section, value)
	Value.write(self, section, value:lower())
end

o = s:option(Value, "source", translate("Source IP"))
wa.cbi_add_knownips(o)
o.datatype = "ip4prefix"

o = s:option(Value, "srcport", translate("Source Port(s)"))
o.datatype  = "or(port, portrange)"

o = s:option(Value, "destination", translate("Destination IP"))
wa.cbi_add_knownips(o)
o.datatype = "ip4prefix"

o = s:option(Value, "dstport", translate("Destination Port(s)"))
o.datatype  = "or(port, portrange)"

return m
