/*  xdg-autostart
    Copyright (C) 2014-2017  Fabrice thiroux

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Author:
    Fabrice thiroux <fabrice.thiroux@free.fr>
*/

using GLib;

class AutostartInfoBuilder {
    const string ENTRY = "Desktop Entry";
    const string SHOWIN = "OnlyShowIn";
    const string HIDEIN = "NotShowIn";
    const string DELAY = "X-GNOME-Autostart-Delay";
    const string TRYEXEC = "TryExec";

    private string desktop;

    private KeyFile keyfile = new KeyFile();

    public AutostartInfoBuilder(string desktop) {
        this.desktop = desktop;
    }

    private bool load_file(string path) {
        try {
            return keyfile.load_from_file (path, KeyFileFlags.NONE);
        }
        catch (Error error) {
            stdout.printf("Error : %s", error.message);
            return false;
        }
    }

    private bool get_visibility() {
        /**
         * An application is not visible if:
         *  - it doesn't exists in OnlyShowIn list
         *  - if it exists in NotShowIn list
         *
         * Overwise, it's visible.
        */
        if (keyfile.has_key(ENTRY, SHOWIN)) {
            return find_desktop(SHOWIN, keyfile, desktop);
        }

        if (keyfile.has_key(ENTRY, HIDEIN)) {
            return !find_desktop(HIDEIN, keyfile, desktop);
        }

        return true;
    }

    private string? get_executable_name() {
        if (tryexec_is_validated(keyfile)) {
            return keyfile.get_string (ENTRY, "Exec");
        }

        return null;
    }

    private int get_delay() {
        // how many seconds should be spent before execution? (default: 0 )
        if (keyfile.has_key(ENTRY, DELAY)) {
            return keyfile.get_integer(ENTRY, DELAY);
        }

        return 0;
    }

    public AutostartInfo build(string path) {

        AutostartInfo info = AutostartInfo() {
            visibility = false,
            filename = path
        };

        if (load_file(path)) {
            info.visibility = get_visibility();
            info.executable = get_executable_name();
            info.delay = get_delay();
        }

        return info;
    }

    // Check if the TryExec condition is satisfied
    // If the condition doesn't exist, return true;
    // If it exists, check if executable is in path and runnable
    private bool tryexec_is_validated (KeyFile kf) {
        if (kf.has_key(ENTRY, TRYEXEC)) {
            string? tryexec = kf.get_string(ENTRY, TRYEXEC);
            if (tryexec != null) {
                if (Environment.find_program_in_path (tryexec) == null)  {
                    return false;
                }
            }
        }

        return true;
    }

    // find a pattern in the key list.
    private bool find_desktop(string category, KeyFile kf, string desktop) {
        string[] show_list;

        show_list = kf.get_string_list(ENTRY, category);
        foreach (string de in show_list) {
            if (de == desktop) {
                return true;
            }
        }

        return false;
    }
}
