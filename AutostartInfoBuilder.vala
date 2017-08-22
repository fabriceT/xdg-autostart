using GLib;

class AutostartInfoBuilder {
    const string ENTRY = "Desktop Entry";
    const string SHOWIN = "OnlyShowIn";
    const string HIDEIN = "NotShowIn";
    const string DELAY = "X-GNOME-Autostart-Delay";
    const string TRYEXEC = "TryExec";

    private string desktop;

    public AutostartInfoBuilder(string desktop) {
        this.desktop = desktop;
    }

    public AutostartInfo build(string path) {
        KeyFile keyfile = new KeyFile();
        AutostartInfo info = AutostartInfo();

        info.visibility = true;
        info.filename = path;

        if (keyfile.load_from_file (path, KeyFileFlags.NONE)) {

            /*
             * Is autostart application is not visible if:
             *  - it doesn't exists in OnlyShowIn list
             *  - if it exists in NotShowIn list
             *
             * Overwise, it's visible.
            */
            if (keyfile.has_key(ENTRY, SHOWIN)) {
                info.visibility = find_desktop(SHOWIN, keyfile, desktop);
            }
            else if (keyfile.has_key(ENTRY, HIDEIN)) {
                info.visibility = !find_desktop(HIDEIN, keyfile, desktop);
            }

            // No need to continue.
            if (info.visibility == false) {
                message(@"$path, not in $desktop desktop ");
                return info;
            }

            // Get Executable name
            if (tryexec_isvalidated(keyfile))
            {
                info.executable = keyfile.get_string (ENTRY, "Exec");
            }

            // No executable found or runnable.
            if (info.executable == null) {
                info.visibility = false;
                return info;
            }

            // how many seconds should be spent before execution? (default: 0 )
            if (keyfile.has_key(ENTRY, DELAY)) {
                info.delay = keyfile.get_integer(ENTRY, DELAY);
            }
        }

        return info;
    }

    // Check if the TryExec condition is satisfied
    // If the condition doesn't exist, return true;
    // If it exists, check if executable is in path and runnable
    private bool tryexec_isvalidated (KeyFile kf) {
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
