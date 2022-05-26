-- cc.strings

local rc = require("rc")
local strings = {}

function strings.wrap(line, width)
  rc.expect(1, line, "string")

end

function strings.ensure_width(line, width)
end

return strings
