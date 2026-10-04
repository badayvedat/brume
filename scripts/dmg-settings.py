# Mise en page du DMG pour dmgbuild : l'app à gauche, Applications à droite, sur le fond de Resources/dmg.
application = defines["app"]

files = [application]
symlinks = {"Applications": "/Applications"}
icon = defines["icon"]
background = defines["background"]
format = "ULFO"

window_rect = ((200, 120), (660, 420))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
icon_size = 128
text_size = 13
icon_locations = {"Brume.app": (170, 200), "Applications": (490, 200)}
