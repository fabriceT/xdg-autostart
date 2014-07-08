# What is xdg-autostart?

xdg-autostart starts programs located in /etc/xdg/autostart and ~/.config/autostart (see FreeDesktop specification for autostarted programs). Put a line in your ~/.openbox/autostart file (its better to end the command with the & sign).

If you want to set your desktop name (e.g. KDE, XFCE, ROX...), then add it as a parameter (e.g. xdg-autostart GNOME &). Please refer to this [table](http://standards.freedesktop.org/menu-spec/latest/apb.html) to get the name of desktops currently supported by the Freedesktop specification. By default, xdg-autostart uses Openbox as desktop name.

# xdg-autostart? But Openbox already starts programs automatically!

Yes, it does. Dana have done a god job.

The default Openbox session launches openbox-autostart which launches openbox-xdg-autostart, a python script. This script requires python-xdg
library to run and, of course, python. The python-xdg dependency is sometimes missed by packagers, so Openbox may or may not autostart
programs. xdg-autostart doesn't have this problem.

#So why?

It was fun to code an autostart program, and it had to be included in an openbox session managment. You are free to use it or not. If you do
then comment the line calling openbox-xdg-autostart in the /usr/lib/openbox/openbox-autostart file.

# Wait!

Hey wait! This xdg-autostart can manage the "X-GNOME-Autostart-Delay" key, thus an application can wait until its time to pop up into your userspace. No more applications burst when starting your desktop session.

