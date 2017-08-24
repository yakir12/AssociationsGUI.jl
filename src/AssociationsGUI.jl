__precompile__()
module AssociationsGUI

using Gtk.ShortNames, GtkReactive, Associations, Base.Dates, DataStructures, HDF5
include(joinpath(Pkg.dir("AssociationsGUI"), "src", "util.jl"))

export main, coordinates_gui

function poi_gui(o, points, files, folder)

    #data
    shortfiles = keys(files)
    # widgets
    name = dropdown(points, value = o.name)
    fstart = dropdown(shortfiles, value = o.start.file)
    fstop = dropdown(shortfiles, value = o.stop.file)
    playstart = button(">")
    playstop = button(">")
    start = timewidget(Time(0,0,0) + o.start.time)
    stop = timewidget(Time(0,0,0) + o.stop.time)
    label = textarea(o.label)
    comment = textarea(o.comment)
    done = button("Done")

    # layout
    g = Grid()
    g[6,0] = Label("POI:")
    g[0,1] = Label("Start:")
    g[2,0] = Label("Play")
    g[3,0] = Label("Time")
    # g[4,0] = Label("M")
    # g[5,0] = Label("S")
    g[0,2] = Label("Stop:")
    g[6,1] = Label("Label:")
    g[6,2] = Label("Comment:")
    g[7,0] = widget(name)
    g[1,1] = widget(fstart)
    g[2,1] = widget(playstart)
    g[3,1] = start.widget
    # g[4,1] = widget(m1)
    # g[5,1] = widget(s1)
    g[1,2] = widget(fstop)
    g[2,2] = widget(playstop)
    g[3,2] = stop.widget
    # g[4,2] = widget(m2)
    # g[5,2] = widget(s2)
    g[7,1] = widget(label)
    g[7,2] = widget(comment)
    g[0:1,0] = widget(done)
    setproperty!(g, :row_spacing, 5)

    # function 
    f1 = map(x -> files[x], fstart)
    f2 = map(x -> files[x], fstop)
    tsksstrt, rsltsstrt = async_map(nothing, signal(playstart)) do _
        openit(joinpath(folder, value(f1)))
        return nothing
    end
    tsksstp, rsltsstp = async_map(nothing, signal(playstop)) do _
        openit(joinpath(folder, value(f2)))
        return nothing
    end
    start_point = map(Point, f1, start.signal)
    stop_point = map(Point, f2, stop.signal)
    wrong_time = map(start_point, stop_point) do p1, p2 # true when the times are fucked
        p1.file == p2.file && p1.time > p2.time
    end
    correct_stop_time = filterwhen(wrong_time, value(start.signal), start.signal)
    bind!(stop.signal, correct_stop_time, false, initial=false)

    time_correct = map(!, wrong_time)
    p1 = filterwhen(time_correct, o.start, start_point)
    p2 = filterwhen(time_correct, o.stop, stop_point)
    poi_temp = map(POI, name, p1, p2, label, comment)

    poi_new = map(_ -> value(poi_temp), done, init = value(poi_temp))
    poi = filterwhen(time_correct, o, poi_new)

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

function main(folder)
    w = Window("LogBeetle", 1000,500)

    vfs = getVideoFiles(folder)
    
    # poi data
    files = shorten(OrderedSet([vf.file for vf in vfs]) ,30)
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
    addrun = button("+")
    setproperty!(widget(addrun), :width_request, 1)
    setproperty!(widget(addrun), :height_request, 1)
    poi_old_ = Signal(POI(points[1], Point(first(values(files)), Second(0)), Point(first(values(files)), Second(0)), "", ""))
    poi_old = map(poi_old_) do p
        p.start.file == p.stop.file ? POI(p.name, p.stop, Point(p.stop.file, 2p.stop.time - p.start.time), p.label, p.comment) : p 
    end

    poi_ = map(addpoi, init = poi_old) do _
        poi_gui(value(poi_old), points, files, folder)
    end
    poi__ = flatten(poi_)

    counterp = foldp((x, _) -> x + 1, 1, poi__)
    oddp = map(isodd, counterp)
    poi = filterwhen(oddp, value(poi__), poi__)

    bind!(poi_old_, poi, initial=false)

    run_old = Signal(Run(Dict(Symbol(k) => isempty(v) ? "" : v[1] for (k, v) in metadata), ""))
    run_ = map(addrun, init = run_old) do _
        run_gui(value(run_old), metadata)
    end
    run__ = flatten(run_)

    counter = foldp((x, _) -> x + 1, 1, run__)
    odd = map(isodd, counter)
    run = filterwhen(odd, value(run__), run__)

    bind!(run_old, run, initial=false)


    s = ScrolledWindow(g)
    push!(w, s)
    showall(w)
    added = merge(poi, run)
    association = foldp(push!, loadAssociation(folder), added)
    assdone = map(association) do a
        empty!(g)
        for (x, p) in enumerate(a.pois)
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
                    poi_ = poi_gui(p, points, files, folder)
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
        g[length(a.pois) + 1,0] = widget(addpoi)
        for (y, r) in enumerate(a.runs)
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
        g[0, length(a.runs) + 1] = widget(addrun)
        for (x, p) in enumerate(a.pois), (y, r) in enumerate(a.runs)
                key = (p, r)
                cb = checkbox(key in a)
                foreach(cb) do tf
                    tf ? push!(a, key) : delete!(a, key)
                end
                g[x,y] = cb
        end
        saves = Button("Save")
        saveh = signal_connect(saves, :clicked) do _
            if isempty(a)
                exit()
            end
            save(folder, a)
            destroy(w)
            checkvideos(a, folder, vfs)
        end
        clears = Button("Clear")
        clearh = signal_connect(clears, :clicked) do _
            empty!(a)
            push!(association, a)
        end
        quits = Button("Quit")
        quith = signal_connect(quits, :clicked) do _
            destroy(w)
            exit()
        end
        savequit = Box(:v)
        push!(savequit, saves, clears, quits)
        g[0,0] = savequit
        showall(w)
    end

end

function return_selected_videos(a::Association, vfs::OrderedSet{VideoFile})::Dict{String, VideoFile}
    uvfs = Set{String}(vf for poi in a.pois for vf in [poi.start.file, poi.stop.file])
    ft = Dict{String, VideoFile}()
    for vf in vfs
        if vf.file in uvfs
            ft[vf.file] = vf
        end
    end
    return ft
end

function checkvideos(a::Association, folder::String, vfs::OrderedSet{VideoFile})
    # data
    ft = return_selected_videos(a, vfs)
    # widgets
    done = button("Done")
    # layout
    g = Grid()
    g[0,0] = Label("File")
    g[1,0] = Label("Year")
    g[2,0] = Label("Month")
    g[3,0] = Label("Day")
    g[4,0] = Label("Hour")
    g[5,0] = Label("Minute")
    g[6,0] = Label("Second")
    #g[7,0] = Label("Millisecond")
    goodtimes = fill(Signal(true), length(ft))
    for (i, (name, vf)) in enumerate(ft)
        play = button(vf.file)
        y = spinbutton(1:10000, value = Dates.Year(vf.datetime).value)
        m = spinbutton(1:12, value = Dates.Month(vf.datetime).value)
        d = spinbutton(1:31, value = Dates.Day(vf.datetime).value)
        H = spinbutton(0:23, value = Dates.Hour(vf.datetime).value)
        M = spinbutton(0:59, value = Dates.Minute(vf.datetime).value)
        S = spinbutton(0:59, value = Dates.Second(vf.datetime).value)
        #MS = spinbutton(0:999, value = Dates.Millisecond(vf.datetime).value)
        setproperty!(y.widget, :width_request, 5)
        setproperty!(m.widget, :width_request, 5)
        setproperty!(d.widget, :width_request, 5)
        setproperty!(H.widget, :width_request, 5)
        setproperty!(M.widget, :width_request, 5)
        setproperty!(S.widget, :width_request, 5)
        #setproperty!(MS.widget, :width_request, 5)
        g[0,i] = play.widget
        g[1,i] = y.widget
        g[2,i] = m.widget
        g[3,i] = d.widget
        g[4,i] = H.widget
        g[5,i] = M.widget
        g[6,i] = S.widget
        #g[7,i] = MS.widget
        dt = map(tuple, y, m, d, H, M, S)
        #dt = map(tuple, y, m, d, H, M, S, MS)
        time_is_good = map(x -> isnull(validargs(DateTime, x...)), dt) 
        goodtimes[i] = time_is_good
        goodtime = filterwhen(time_is_good, value(dt), dt)
        vf2 = map(goodtime) do x
            ft[name] = VideoFile(vf.file, DateTime(x...))
        end
        tasksplay, resultsplay = async_map(nothing, signal(play)) do _
            openit(joinpath(folder, vf.file))
        end
    end

    goodtime = map(&, goodtimes...)
    clicked = filterwhen(goodtime, Void(), signal(done))
    foreach(clicked,  init = nothing) do _
        save(folder, OrderedSet{VideoFile}(values(ft)))
        destroy(win)
    end

    g[0:6, length(ft) + 1] = widget(done)
    #g[0:7, length(ft) + 1] = widget(done)
    win = Window(g, "LogBeetle: Check videos", 1, 1)
    showall(win)

    #=c = Condition()
    signal_connect(win, :destroy) do _
        notify(c)
    end
    wait(c)=#
end

function coordinates_gui(folder::String)
    w = Window("LogBeetle", 500,500)
    info_label = Label("")
    c = Condition()
    ok = button("OK")
    foreach(ok) do _
        notify(c)
    end
    b = Box(:v)
    push!(b, info_label, ok)
    s = ScrolledWindow(b)
    push!(w, s)
    a = loadAssociation(folder)
    for (i, p) in enumerate(a.pois)
        f5name = joinpath(folder, "log", "$i.h5")
        isfile(f5name) && continue
        r = String[]
        push!(r, """<b>POI</b> 
        Name: <i>$(p.name)</i>
        Label: <i>$(p.label)</i>
        Comment: <i>$(p.comment)</i>""")
        for (pp, rr) in a.associations
            if p == pp
                push!(r, """ 
                      <b>Run</b>
                      Repetition: <i>$(rr.repetition)</i>""")
                for (k, v) in rr.run.metadata
                    push!(r, "$k: <i>$v</i>")
                end
                push!(r, "Comment: <i>$(rr.run.comment)</i>")
            end
        end
        info = join(r, "\n")
        G_.markup(info_label, info)
        showall(w)
        wait(c)
        xyt = rand(10,3)
        h5open(f5name, "w") do o
            @write o xyt
        end
    end
    destroy(w)
end

end # module
