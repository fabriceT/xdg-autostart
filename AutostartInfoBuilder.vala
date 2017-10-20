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

    /**
     * Returns the visibility of the desktop file
     *
     * Not visible if:
     *  - it doesn't exists in OnlyShowIn list
     *  - it exists in NotShowIn list
     *
     * @returns true if desktop file is visible, false otherwise.
     */
    private bool get_visibility() {
        try {
            if (keyfile.has_key(ENTRY, SHOWIN))
                return find_desktop(SHOWIN, keyfile, desktop);
        }
        catch (KeyFileError error) {
            warning("%s", error.message);
        }

        try {
            if (keyfile.has_key(ENTRY, HIDEIN))
                return !find_desktop(HIDEIN, keyfile, desktop);
        }
        catch (KeyFileError error) {
            warning("%s", error.message);
        }

        return true;
    }

    /**
     * Check if executable name exists or if TryExec condition is met
     *
     * @returns the executable name or null.
     */
    private string? get_executable_name() {
        try {
            if (tryexec_is_validated(keyfile))
                return keyfile.get_string (ENTRY, "Exec");
        }
        catch (KeyFileError error) {
            warning("%s", error.message);
        }

        return null;
    }

    /**
     * @returns the delay in seconds before program has to be launched
     */
    private int get_delay() {
        try {
            if (keyfile.has_key(ENTRY, DELAY)) {
                return keyfile.get_integer(ENTRY, DELAY);
            }
        }
        catch (KeyFileError error) {
            warning("%s", error.message);
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

    /*
     * Check for TryExec condition.
     *
     * @returns false only if condition exists and executable not in path or not runnable.
     */
    private bool tryexec_is_validated (KeyFile kf) {
        try {
            if (kf.has_key(ENTRY, TRYEXEC)) {
                string? tryexec = kf.get_string(ENTRY, TRYEXEC);
                if (tryexec != null) {
                    if (Environment.find_program_in_path (tryexec) == null)  {
                        return false;
                    }
                }
            }
        }
        catch (KeyFileError error) {
            warning("%s", error.message);
        }

        return true;
    }

    // find a pattern in the key list.
    private bool find_desktop(string category, KeyFile kf, string desktop) {
        string[] show_list;

        try {
            show_list = kf.get_string_list(ENTRY, category);
            foreach (string de in show_list) {
                if (de == desktop) {
                    return true;
                }
            }
        }
        catch (KeyFileError error) {
            warning("%s", error.message);
        }

        return false;
    }
}
