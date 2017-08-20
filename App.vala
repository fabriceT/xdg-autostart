
class App {
    private string desktop_name;

    public App(string name) {
        desktop_name = name;
    }

    public void run() {
        var reader = new DirectoryReader();
        var builder = new AutostartInfoBuilder(desktop_name);
        var launcher = new ProgramLauncher();

        reader.read_all();

        foreach(string filename in reader.getFiles()) {
            launcher.add(builder.build(filename));
        }

        launcher.launch();
    }
}


public int main(string[] args)
{
    string desktop = (args.length > 1) ? args[1] : "Openbox";
    new App(desktop).run();

    return 0;
}

