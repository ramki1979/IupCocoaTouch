------------------------------------------------------------------------------
-- Gauge class 
------------------------------------------------------------------------------
local ctrl = {
  nick = "gauge",
  parent = iup.WIDGET,
  creation = "",
  callback = {},
  subdir = "ctrl",
  include = "iupcontrols.h",
}

function ctrl.createElement(class, param)
   return iup.Gauge(param.action)
end

iup.RegisterWidget(ctrl)
iup.SetClass(ctrl, "iupWidget")
