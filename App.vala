using GLib;

class App {
    private string desktop_name;

    public App(string name) {
        desktop_name = name;
    }

    public void run(bool dry_run) {
        var reader = new DirectoryReader();
        var builder = new AutostartInfoBuilder(desktop_name);
        var launcher = new ProgramLauncher(dry_run);

        reader.read_all();

        foreach(string filename in reader.getFiles()) {
            launcher.add(builder.build(filename));
        }

        launcher.launch();
    }
}



public int main(string[] args)
{
    bool dry_run = false;
    string desktop = "Openbox";

    try {
        GLib.OptionEntry[] options = {
            GLib.OptionEntry () {
                long_name = "dry-run",
                short_name = 'n',
                flags = 0,
                arg = GLib.OptionArg.NONE,
                arg_data = &dry_run,
                description = "Perform a test.",
                arg_description = null },
            GLib.OptionEntry () {
                long_name = "desktop",
                short_name = 'd',
                flags = 0,
                arg = GLib.OptionArg.STRING,
                arg_data = &desktop,
                description = "Desktop name",
                arg_description = null },
            GLib.OptionEntry ()
        };

        var opt_context = new OptionContext(" - XDG autostart");
        opt_context.set_help_enabled(true);
        opt_context.add_main_entries(options, null);
        opt_context.parse(ref args);
    } catch (OptionError e) {
        stdout.printf("error: %s\n", e.message);
        stdout.printf("Run '%s --help' to view a full list of available command line pass_options\n", args[0]);
        return 1;
    }

    new App(desktop).run(dry_run);

    return 0;
}

