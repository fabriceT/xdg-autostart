class ProgramLauncher {
    private int seconds = 0;
    private MainLoop main_loop;
    private List<AutostartInfo?> files = new List<AutostartInfo?>();

    public void add(AutostartInfo file) {
        if (file.is_launchable()) {
            files.append(file);
        }
    }

    private bool runner() {
        files.foreach((x) => {
            if (x.delay == seconds) {
                try {
                    message("Launching: %s (delay: %d, file: %s)",
                            x.executable,
                            seconds,
                            x.filename);
                    Process.spawn_command_line_async (x.executable);
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
        main_loop = new MainLoop();
        GLib.Timeout.add_seconds (1, runner);
        main_loop.run ();
    }
}

