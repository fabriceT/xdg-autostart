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

//[CCode(cname="GETTEXT_PACKAGE")] extern const string GETTEXT_PACKAGE;
//[CCode(cname="LOCALEDIR")] extern const string LOCALEDIR;

class App {
    private string desktop_name;
    public bool verbose = false;
    public bool dry_run = false;

    public App(string name) {
        stdout.printf(@"Setting desktop name to $name\n");
        desktop_name = name;
    }

    public int run() {
        var reader = new DirectoryReader();
        var builder = new AutostartInfoBuilder(desktop_name);
        var launcher = new ProgramLauncher(dry_run);

        reader.read_all();

        foreach(string filename in reader.getFiles()) {
            AutostartInfo info = builder.build(filename);
            if (verbose) {
                stdout.printf("%s\n", info.to_string());
            }
            launcher.add(info);
        }

        return launcher.launch();
    }
}


public int main(string[] args)
{
    string desktop = "Openbox";
    bool dry_run = false;
    bool verbose= false;

    GLib.Intl.setlocale(GLib.LocaleCategory.ALL, "");
    GLib.Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    GLib.Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
    GLib.Intl.textdomain (Config.GETTEXT_PACKAGE);

    try {
        GLib.OptionEntry[] options = {
            GLib.OptionEntry () {
                long_name = "dry-run",
                short_name = 'n',
                flags = 0,
                arg = GLib.OptionArg.NONE,
                arg_data = &dry_run,
                description = _("Perform a test."),
                arg_description = null },
            GLib.OptionEntry () {
                long_name = "verbose",
                short_name = 'v',
                flags = 0,
                arg = GLib.OptionArg.NONE,
                arg_data = &verbose,
                description = _("Display more informations."),
                arg_description = null },
            GLib.OptionEntry () {
                long_name = "desktop",
                short_name = 'd',
                flags = 0,
                arg = GLib.OptionArg.STRING,
                arg_data = &desktop,
                description = _("Desktop name"),
                arg_description = null },
            GLib.OptionEntry ()
        };

        var opt_context = new OptionContext(@" - XDG autostart " + Config.VERSION);
        opt_context.set_help_enabled(true);
        opt_context.add_main_entries(options, null);
        opt_context.parse(ref args);
    }
    catch (OptionError e) {
        stdout.printf("error: %s\n", e.message);
        stdout.printf("Run '%s --help' to view a full list of available command line pass_options\n", args[0]);
        return 1;
    }

    var app = new App(desktop);

    // Set up app options.
    app.verbose = verbose;
    app.dry_run = dry_run;

    return app.run();
}

