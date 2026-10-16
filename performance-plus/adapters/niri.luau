local M = {}

local home = noctalia.getenv("HOME") or ""
local xdgConfig = noctalia.getenv("XDG_CONFIG_HOME")
local configDir = (xdgConfig and xdgConfig ~= "") and xdgConfig or (home .. "/.config")

local xdgRuntime = noctalia.getenv("XDG_RUNTIME_DIR")
local runtimeDir = (xdgRuntime and xdgRuntime ~= "") and (xdgRuntime .. "/noctalia-performance-plus") or (home .. "/.cache/noctalia-performance-plus")

local PERF_CONFIG_PATH = runtimeDir .. "/niri-perf.kdl"
local BASE_CONFIG_PATH = configDir .. "/niri/config.kdl"

function M.enable(opts)
    if opts.animations == false and opts.blur == false and opts.shadows == false then
        return
    end

    local parts = {
        string.format('include "%s"', BASE_CONFIG_PATH)
    }

    if opts.animations ~= false then
        table.insert(parts, [[
animations {
    off
}]])
    end

    if opts.blur ~= false then
        table.insert(parts, [[
window-rule {
    background-effect {
        blur false
    }
}

layer-rule {
    match namespace="^noctalia-"
    background-effect {
        blur false
    }
}]])
    end

    if opts.shadows ~= false then
        table.insert(parts, [[
shadow {
    off
}]])
    end

    if #parts == 1 then
        return
    end

    local kdl = table.concat(parts, "\n\n") .. "\n"

    -- Write temp override securely and load it in Niri only if base config exists and write succeeds
    local cmd = string.format([[sh -c 'mkdir -p -m 0700 "%s" && if [ -f "%s" ]; then
    rm -f "%s"
    if cat << "EOF" > "%s"
%s
EOF
    then
        niri msg action load-config-file --path "%s"
    fi
fi']], runtimeDir, BASE_CONFIG_PATH, PERF_CONFIG_PATH, PERF_CONFIG_PATH, kdl, PERF_CONFIG_PATH)
    noctalia.runAsync(cmd)

    noctalia.log("[Niri] Performance mode enabled (animations & background-effects disabled)")
end

function M.disable(opts)
    -- Reload base config in Niri and cleanup temp override only if override exists
    local cmd = string.format("sh -c 'if [ -f \"%s\" ]; then niri msg action load-config-file; rm -f \"%s\"; fi'", PERF_CONFIG_PATH, PERF_CONFIG_PATH)
    noctalia.runAsync(cmd)

    noctalia.log("[Niri] Performance mode disabled (restored base config)")
end

return M
