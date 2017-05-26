#__precompile__()
#module AssociationsGUI

using Gtk.ShortNames, GtkReactive, Associations, Base.Dates
include(joinpath(Pkg.dir("AssociationsGUI"), "src", "util.jl"))

function poi_gui(o, points, files)

    #data
    shortfiles = keys(files)
    # widgets
    name = dropdown(points, value = o.name)
    fstart = dropdown(shortfiles, value = o.start.file)
    fstop = dropdown(shortfiles, value = o.stop.file)
    dt = DateTime() + o.start.time
    s1 = spinbutton(0:59, orientation = "v", value = Second(dt).value)
    m1 = spinbutton(0:59, orientation = "v", value = Minute(dt).value)
    h1 = spinbutton(0:23, orientation = "v", value = Hour(dt).value)
    dt = DateTime() + o.stop.time
    s2 = spinbutton(0:59, orientation = "v", value = Second(dt).value)
    m2 = spinbutton(0:59, orientation = "v", value = Minute(dt).value)
    h2 = spinbutton(0:23, orientation = "v", value = Hour(dt).value)
    label = textarea(o.label)
    comment = textarea(o.comment)
    done = button("Done")

    # layout
    setproperty!(widget(s1), :width_request, 5)
    setproperty!(widget(m1), :width_request, 5)
    setproperty!(widget(h1), :width_request, 5)
    setproperty!(widget(s2), :width_request, 5)
    setproperty!(widget(m2), :width_request, 5)
    setproperty!(widget(h2), :width_request, 5)
    g = Grid()
    g[5,0] = Label("POI:")
    g[0,1] = Label("Start:")
    g[2,0] = Label("H")
    g[3,0] = Label("M")
    g[4,0] = Label("S")
    g[0,2] = Label("Stop:")
    g[5,1] = Label("Label:")
    g[5,2] = Label("Comment:")
    g[6,0] = widget(name)
    g[1,1] = widget(fstart)
    g[2,1] = widget(h1)
    g[3,1] = widget(m1)
    g[4,1] = widget(s1)
    g[1,2] = widget(fstop)
    g[2,2] = widget(h2)
    g[3,2] = widget(m2)
    g[4,2] = widget(s2)
    g[6,1] = widget(label)
    g[6,2] = widget(comment)
    g[0:1,0] = widget(done)
    setproperty!(g, :row_spacing, 5)

    # function 
    tsksstrt, rsltsstrt = async_map(nothing, signal(fstart)) do f²
        openit(joinpath(folder, files[f²]))
        return nothing
    end
    tsksstp, rsltsstp = async_map(nothing, signal(fstop)) do f²
        openit(joinpath(folder, files[f²]))
        return nothing
    end
    poi_temp = map(name, fstart, h1, m1, s1, fstop, h2, m2, s2, label, comment) do name², fstart², h1², m1², s1², fstop², h2², m2², s2², label², comment²
        p1 = Point(files[fstart²], h1², m1², s1²)
        p2 = Point(files[fstop²], h2², m2², s2²)
        POI(name², p1, p2, label², comment²)
    end
    poi_new = map(_ -> value(poi_temp), done, init = value(poi_temp))
    time_correct = map(p -> p.start.file == p.stop.file ? p.start.time <= p.stop.time : true, poi_temp)
    #poi_novel = map(association, poi_temp) do a, pp
    #!(pp in a.pois)
    #end
    #good = map(&, time_correct, poi_novel)
    good = time_correct
    poi = filterwhen(good, o, poi_new)

    w = Window("LogBeetle")
    push!(w, g)
    showall(w)
    foreach(poi, init = nothing) do _
        destroy(w)
    end
    return poi
end

function run_gui(o, metadata)

    # data
    nmd = length(metadata)
    # widgets
    widgets = Dict{Symbol, Union{GtkReactive.Textarea, GtkReactive.Dropdown}}()
    for (k, v) in metadata
        if all(isempty.(v))
            widgets[Symbol(k)] = textarea(o.metadata[Symbol(k)])
        else
            widgets[Symbol(k)] = dropdown(v, value = o.metadata[Symbol(k)])
        end
    end
    comment = textarea(o.comment)
    done = button("Done")
    # layout
    g = Grid()
    for (i, kv) in enumerate(widgets)
        g[0,i - 1] = Label(first(kv))
        g[1,i - 1] = last(kv).widget
    end
    g[0, nmd + 1] = Label("Comment")
    g[1, nmd + 1] = widget(comment)
    g[0:1, nmd + 2] = widget(done)
    # function
    run = map(done, init = Run(Dict(k => value(v) for (k, v) in widgets), value(comment))) do _
        Run(Dict(k => value(v) for (k, v) in widgets), value(comment))
    end

    w = Window("LogBeetle")
    push!(w, g)
    showall(w)
    foreach(run, init = nothing) do _
        destroy(w)
    end
    return run
end

folder = "/home/yakir/.julia/v0.6/AssociationsGUI/test/videofolder"



#function main(folder)

    # poi data
    files = shorten(getVideoFiles(folder), 30)
    points = strip.(vec(readcsv(joinpath(folder, "metadata", "poi.csv"), String)))

    # run data
    tmp = readcsv(joinpath(folder, "metadata", "run.csv"))
    metadata = Dict{String, Vector{String}}()
    for i = 1:size(tmp,1)
        b = strip.(tmp[i,:])
        metadata[b[1]] = filter(x -> !isempty(x), b[2:end])
    end


    g = Grid()
    addpoi = button("+")
    setproperty!(widget(addpoi), :width_request, 1)
    setproperty!(widget(addpoi), :height_request, 1)
    #g[1,0] = widget(addpoi)
    addrun = button("+")
    setproperty!(widget(addrun), :width_request, 1)
    setproperty!(widget(addrun), :height_request, 1)
    #g[0,1] = widget(addrun)
    w = Window("LogBeetle")
    push!(w, g)
    showall(w)
    poi_old_ = Signal(POI(points[1], Point(first(values(files)), Second(0)), Point(first(values(files)), Second(0)), "", ""))
    poi_old = map(poi_old_) do p
        p.start.file == p.stop.file ? POI(p.name, p.stop, Point(p.stop.file, 2p.stop.time - p.start.time), p.label, p.comment) : p 
    end

    poi_ = map(addpoi, init = poi_old) do _
        poi_gui(value(poi_old), points, files)
    end
    poi = droprepeats(flatten(poi_))
    bind!(poi_old_, poi)

    run_old = Signal(Run(Dict(Symbol(k) => isempty(v) ? "" : v[1] for (k, v) in metadata), ""))
    run_ = map(addrun, init = run_old) do _
        run_gui(value(run_old), metadata)
    end
    run__ = flatten(run_)
    counter = foldp((x, _) -> x + 1, 1, run__)
    odd = map(isodd, counter)

    run = filterwhen(odd, value(run__), run__)
    bind!(run_old, run, initial=false)



    added = merge(poi, run)
    association = foldp(push!, loadAssociation(folder), added)
    assdone = map(association) do a
        empty!(g)
        for (x, p) in enumerate(a.pois)
            if p.visible
                file = MenuItem("_$(p.name) $(p.label)")
                filemenu = Menu(file)
                check_ = MenuItem("Check")
                checkh = signal_connect(check_, :activate) do _
                    for r in a.runs
                        push!(a, (p, r))
                    end
                    push!(association, a)
                end
                push!(filemenu, check_)
                uncheck_ = MenuItem("Uncheck")
                uncheckh = signal_connect(uncheck_, :activate) do _
                    for r in a.runs
                        delete!(a, (p, r))
                    end
                    push!(association, a)
                end
                push!(filemenu, uncheck_)
                #=hide_ = MenuItem("Hide")
                hideh = signal_connect(hide_, :activate) do _
                    p.visible = false
                    push!(association, a)
                end
                push!(filemenu, hide_)=#
                edit_ = MenuItem("Edit")
                edith = signal_connect(edit_, :activate) do _
                    poi_ = poi_gui(p, points, files)
                    poi_new = droprepeats(poi_)
                    foreach(poi_new, init = nothing) do n
                        replace!(a, p, n)
                        push!(association, a)
                        nothing
                    end
                end
                push!(filemenu, edit_)
                push!(filemenu, SeparatorMenuItem())
                delete = MenuItem("Delete")
                deleteh = signal_connect(delete, :activate) do _
                    delete!(a, p)
                    push!(association, a)
                end
                push!(filemenu, delete)
                mb = MenuBar()
                push!(mb, file)
                g[x,0] = mb
            end
        end
        g[length(a.pois) + 1,0] = widget(addpoi)
        for (y, r) in enumerate(a.runs)
            if r.run.visible
                file = MenuItem(string("_", shorten(string(join(values(r.run.metadata), ":")..., ":", r.repetition), 30)))
                filemenu = Menu(file)
                check_ = MenuItem("Check")
                checkh = signal_connect(check_, :activate) do _
                    for p in a.pois
                        push!(a, (p, r))
                    end
                    push!(association, a)
                end
                push!(filemenu, check_)
                uncheck_ = MenuItem("Uncheck")
                uncheckh = signal_connect(uncheck_, :activate) do _
                    for p in a.pois
                        delete!(a, (p, r))
                    end
                    push!(association, a)
                end
                push!(filemenu, uncheck_)
                #=hide_ = MenuItem("Hide")
                hideh = signal_connect(hide_, :activate) do _
                    r.visible = false
                    push!(association, a)
                end
                push!(filemenu, hide_)=#
                edit_ = MenuItem("Edit")
                edith = signal_connect(edit_, :activate) do _
                    run_ = run_gui(r.run, metadata)
                    run_new = droprepeats(run_)
                    foreach(run_new, init = nothing) do n
                        replace!(a, r, n)
                        push!(association, a)
                        nothing
                    end
                end
                    #=for (k, v) in widgets
                        push!(v, r.run.metadata[k])
                    end
                    push!(run_comment, r.run.comment)
                    delete!(a, r)
                end=#
                push!(filemenu, edit_)
                push!(filemenu, SeparatorMenuItem())
                delete = MenuItem("Delete")
                deleteh = signal_connect(delete, :activate) do _
                    delete!(a, r)
                    push!(association, a)
                end
                push!(filemenu, delete)
                mb = MenuBar()
                push!(mb, file)
                g[0,y] = mb
            end
        end
        g[0, length(a.runs) + 1] = widget(addrun)
        for (x, p) in enumerate(a.pois), (y, run) in enumerate(a.runs)
            if p.visible
                key = (p, run)
                cb = checkbox(key in a.associations)
                foreach(cb) do tf
                    tf ? push!(a, key) : delete!(a, key)
                end
                g[x,y] = cb
            end
        end
        showall(w)
    end


#end


# all data

#main(folder)



#include(joinpath(Pkg.dir("AssociationsGUI"), "src", "gui.jl"))

#end # module
