START_STOP_KEY = "rshift"
START_STOP_KEY_NAME = "right shift"

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

