
NORMAL_ALPHA = 200
SHADOW_ALPHA = 60

ColorRgb = {
	CYAN = {0, 255, 255},
	BLUE = {0, 0, 255},
	ORANGE = {255, 165, 0},
	YELLOW = {255, 255, 0},
	GREEN = {0, 255, 0},
	PURPLE = {160, 32, 240},
	RED = {255, 0, 0}
}

function colorFromRgba(rgb, alpha)
	return tocolor(rgb[1], rgb[2], rgb[3], alpha)
end

TetrominoId = {
	I = 1,
	J = 2,
	L = 3,
	O = 4,
	S = 5,
	T = 6,
	Z = 7
}

-- shadowAlpha
IdColorMap = {
	[TetrominoId.I] = {rgb=ColorRgb.CYAN},
	[TetrominoId.J] = {rgb=ColorRgb.BLUE},
	[TetrominoId.L] = {rgb=ColorRgb.ORANGE},
	[TetrominoId.O] = {rgb=ColorRgb.YELLOW},
	[TetrominoId.S] = {rgb=ColorRgb.GREEN},
	[TetrominoId.T] = {rgb=ColorRgb.PURPLE},
	[TetrominoId.Z] = {rgb=ColorRgb.RED}
}

KEY_NAMES = { 
  -- mouse
  ["mouse1"] = "Left click",
  ["mouse2"] = "Right click",
  ["mouse3"] = "Middle click",
  ["mouse4"] = "Mouse 4",
  ["mouse5"] = "Mouse 5",
  ["mouse_wheel_up"] = "Mouse wheel up",
  ["mouse_wheel_down"] = "Mouse wheel down",
  -- arrows
  ["arrow_l"] = "Left",
  ["arrow_u"] = "Up",
  ["arrow_r"] = "Right",
  ["arrow_d"] = "Down",

  ["lalt"] = "left alt",
  ["ralt"] = "right alt",
  ["pgup"] = "page up",
  ["pgdn"] = "page down",
  ["lshift"] = "left shift",
  ["rshift"] = "right shift",
  ["lctrl"] = "left ctrl",
  ["rctrl"] = "right ctrl",
  ["capslock"] = "caps lock",
  ["scroll"] = "scroll lock",
}
-- if not described, then just return the key itself
setmetatable(KEY_NAMES, {__index = function(table, key) return key end})


-- just keeping for reference comment atm
local keyTable = {
  "mouse1", "mouse2", "mouse3", "mouse4", "mouse5", "mouse_wheel_up", "mouse_wheel_down", 
  "arrow_l", "arrow_u", "arrow_r", "arrow_d", 
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", 
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", 
  "num_0", "num_1", "num_2", "num_3", "num_4", "num_5", "num_6", "num_7", "num_8", "num_9", 
  "num_mul", "num_add", "num_sep", "num_sub", "num_div", "num_dec", "num_enter", 
  "F1", "F2", "F3", "F4",  "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", 
  "escape", "backspace", "tab", "lalt", "ralt", "enter", "space", "pgup", "pgdn", "end", "home",
  "insert", "delete", "lshift", "rshift", "lctrl", "rctrl", 
  "[", "]", "pause", "capslock", "scroll", 
  ";", ",", "-", ".", "/", "#", "\\", "="
}
