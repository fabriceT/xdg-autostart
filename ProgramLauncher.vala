class ProgramLauncher {
    private int seconds = 0;
    private bool dry_run;
    private MainLoop main_loop;
    private List<AutostartInfo?> files = new List<AutostartInfo?>();

    public ProgramLauncher(bool dry_run) {
        this.dry_run = dry_run;
    }

    public void add(AutostartInfo file) {
        if (file.is_launchable()) {
            files.append(file);
        }
    }

    private bool runner() {
        files.foreach((x) => {
            if (x.delay == seconds) {
                try {
                    if (dry_run) {
                        message("Time: %d sec. - %s (filename: %s)",
                            seconds,
                            x.executable,
                            x.filename);
                    } else {
                        Process.spawn_command_line_async (x.executable);
                    }
                }
                catch (SpawnError e) {
                    warning("Error launching: %s\n", e.message);
                }
                files.remove(x);
            }
        });

        // There is no more application to launch
        if (files.length() == 0) {
            main_loop.quit();
            return false;
        }

        // loop
        seconds++;
        return true;
    }

    public void launch() {
        // Speed it up when in dry run mode.
        var delay = (dry_run) ? 0 : 1;

        main_loop = new MainLoop();
        GLib.Timeout.add_seconds (delay, runner);
        main_loop.run ();
    }
}

