local config = require("dapui.config")
local util = require("dapui.util")

---@class BufBreakpoints
---@field mark_breakpoint_map table
---@field expanded_breakpoints table
local BufBreakpoints = {}

function BufBreakpoints:new()
  local elem = { mark_breakpoint_map = {}, expanded_breakpoints = {} }
  setmetatable(elem, self)
  self.__index = self
  return elem
end

local function open_frame_callback(current_bp)
  return function()
    util.jump_to_frame({
      line = current_bp.line,
      column = 0,
      source = { path = current_bp.file },
    })
  end
end

---@param canvas dapui.Canvas
function BufBreakpoints:render(canvas, buffer, breakpoints, current_line, current_file, indent)
  indent = indent or config.windows().indent
  local function is_current_line(bp)
    return bp.line == current_line and bp.file == current_file
  end
  for _, bp in pairs(breakpoints) do
    local text = vim.api.nvim_buf_get_lines(buffer, bp.line - 1, bp.line, false)
    if vim.tbl_count(text) ~= 0 then
      canvas:add_mapping(config.actions.OPEN, open_frame_callback(bp))
      canvas:write(string.rep(" ", indent))
      canvas:write(
        tostring(bp.line),
        { group = is_current_line(bp) and "DapUIBreakpointsCurrentLine" or "DapUIBreakpointsLine" }
      )
      canvas:write(" " .. vim.trim(text[1]) .. "\n")

      local info_indent = indent + #tostring(bp.line) + 1
      local whitespace = string.rep(" ", info_indent)

      local function add_info(message, data)
        canvas:add_mapping(config.actions.OPEN, open_frame_callback(bp))
        canvas:write(whitespace)
        canvas:write(message, { group = "DapUIBreakpointsInfo" })
        canvas:write(" " .. data .. "\n")
      end
      if bp.logMessage then
        add_info("Log Message:", bp.logMessage)
      end
      if bp.condition then
        add_info("Condition:", bp.condition)
      end
      if bp.hitCondition then
        add_info("Hit Condition:", bp.hitCondition)
      end
    end
  end
  canvas:remove_line()
end

---@return BufBreakpoints
local function new()
  return BufBreakpoints:new()
end

return new
