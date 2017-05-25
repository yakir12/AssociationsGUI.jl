__precompile__()
module AssociationsGUI

using Gtk.ShortNames, GtkReactive, Associations

export main

include(joinpath(Pkg.dir("AssociationsGUI"), "src", "util.jl"))

include(joinpath(Pkg.dir("AssociationsGUI"), "src", "gui.jl"))

end # module
