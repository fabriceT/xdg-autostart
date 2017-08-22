struct AutostartInfo {
    public string filename;
    public bool visibility;
    public int delay;
    public string executable;


    public bool is_launchable() {
        return visibility && executable != null;
    }
}
