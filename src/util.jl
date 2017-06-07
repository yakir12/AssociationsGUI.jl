function second2hms(x::Second)::Dict{DataType, Int}
    ps = Dates.CompoundPeriod(Dates.CompoundPeriod(x))
    a = Dict{DataType, Int}(k => 0 for k in [Hour, Minute, Second])
    ts = [Day, Week, Month, Year]
    for p in ps.periods
        if typeof(p) in ts
            a[Hour] += Hour(p).value
        else
            a[typeof(p)] += p.value
        end
    end
    return a
end
shorten(s::String, k::Int) = length(s) > 2k + 1 ? s[1:k]*"…"*s[(end-k + 1):end] : s
function shorten(vfs::OrderedSet{String}, m)
    nmax = maximum(map(length, vfs))
    n = min(m, nmax) - 1
    while n < nmax
        n += 1
        if allunique(shorten(vf, n) for vf in vfs)
            break
        end
    end
    return OrderedDict(shorten(vf, n) => vf for vf in vfs)
end

function openit(f::String)
    if isfile(f)
        cmd = is_windows() ? `explorer $f` : is_linux() ? `xdg-open $f` : is_apple() ? `open $f` : error("Unknown OS")
        return run(ignorestatus(cmd))
        #stream, proc = open(cmd)
        return proc
        # try to see if you can kill the spawned process (closing the movie player). this will be useful for testing this, and for managing shit once the user is done (not sure if all the players automatically close when the user quits julia)
    else
        systemerror("$f not found", true)
    end
end
function findshortfile(v::String, d::Dict{String, String})::String
    for k in keys(d)
        d[k] == v && return k
    end
    error("Couldn't find $v in $d")
end
function validargs(_, y, m, d, rest...)
    0 < m < 13 || return Nullable{ArgumentError}(ArgumentError("Month: $m out of range (1:12)"))
    0 < d < daysinmonth(y,m)+1 || return Nullable{ArgumentError}(ArgumentError("Day: $d out of range (1:$(daysinmonth(y,m)))"))
    return Nullable{ArgumentError}()
end
