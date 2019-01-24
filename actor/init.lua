local BASE = ...

return function(n)
    return require(BASE .. "." .. n)
end
