function log(...)  
  local printResult = ""
  for i, v in ipairs(arg) do
    printResult = printResult .. tostring(v) .. " "
  end
  
  outputDebugString(printResult)
end