#!/usr/bin/julia
using AssociationsGUI, Gtk
f = open_dialog("")
folder, _ = splitdir(f)
#win = Gtk.Window("")
#folder = open_dialog("Select videos-folder", action=Gtk.GtkFileChooserAction.SELECT_FOLDER)
main(folder)
