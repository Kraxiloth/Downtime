local addonName, addon = ...

addon = addon or {}

local unpackArgs = unpack or table.unpack

local errors = {}
local disabledComponents = {}

function addon:ReportError(component, message)
    local entry = {
        component = component,
        message = tostring(message),
        time = date("%Y-%m-%d %H:%M:%S")
    }

    errors[#errors + 1] = entry

    -- Keep only the 20 most recent errors.
    if #errors > 20 then
        table.remove(errors, 1)
    end
end

function addon:SafeCall(component, callback, ...)
    if disabledComponents[component] then
        return false
    end

    local args = { ... }
    local argCount = select("#", ...)

    local success, result = xpcall(function()
        return callback(unpackArgs(args, 1, argCount))
    end, function(err)
        local trace = debugstack and debugstack(2, 10, 10)
            or tostring(err)

        self:ReportError(component, tostring(err) .. "\n" .. trace)
        return err
    end)

    if not success then
        disabledComponents[component] = true
        return false
    end

    return true, result
end

function addon:GetErrors()
    return errors
end
