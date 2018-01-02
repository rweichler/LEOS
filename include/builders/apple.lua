local super = builder
local builder = super()

function builder:get_sdk_path()
    if self._sdk_path then
        return self._sdk_path
    elseif self.sdk then
        assert(os.execute('command -v xcrun > /dev/null') == 0, "sdk set, but xcrun isn't found")
        return os.capture('xcrun --sdk '..self.sdk..' --show-sdk-path')
    end
end

function builder:set_sdk_path(sdk_path)
    self._sdk_path = sdk_path
end

function builder:get_sflags()
    local sflags = super.get_sflags(self)
    local arch = ''
    local isysroot = self.sdk_path and '-isysroot "'..self.sdk_path..'"' or ''
    if self.archs then
        for i,v in ipairs(self.archs) do
            arch = arch..' -arch '..v
        end
    end
    return sflags..' '..arch..' '..isysroot
end

function builder:get_ldflags()
    local ldflags = super.get_ldflags(self)
    local frameworks = ''
    if self.frameworks then
        frameworks = frameworks..' -F'..self.sdk_path..'/System/Library/PrivateFrameworks'
        for i,v in ipairs(self.frameworks) do
            frameworks = frameworks..' -framework '..v
        end
    end

    if not self.disable_ios9_workaround then
        ldflags = ldflags..' -Wl,-segalign,4000'
    end

    return ldflags..' '..frameworks..' '
end

function builder:link(obj)
    if not super.link(self, obj) then return end

    -- flags
    local execute = self.verbose and os.pexecute or os.execute
    local pretty_print = not self.verbose and not self.quiet

    if pretty_print then
        io.write(YELLOW())
        io.write('ldid ')
        io.write(GREEN())
        io.write(self.output)
        io.write(NORMAL)
        io.write('\n')
    end

    execute("ldid -S"..(self.entitlements or "").." "..self.output)

    return true
end

return builder
