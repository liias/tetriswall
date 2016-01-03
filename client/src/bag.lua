-- mutating
local function shuffle(array)
  local counter = #array
  while counter > 1 do
    local index = math.random(counter)
    array[index], array[counter] = array[counter], array[index]
    counter = counter - 1
  end
  
  return array
end


Bag = {
}

function Bag:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
  
  self.tetrominoIds = {}
	return o
end

function Bag:refill()
  self.tetrominoIds = shuffle({1,2,3,4,5,6,7})
end

function Bag:takeNext()
  if #self.tetrominoIds == 0 then
    self:refill()
  end
  
  return table.remove(self.tetrominoIds)
end



