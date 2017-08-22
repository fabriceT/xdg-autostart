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

class DirectoryReader {
    // Stores filenames and fullpaths when reading XDG config directories
    private HashTable<string, string> desktopFiles;

    private SList<string> autostart_files = new SList<string>();

    public DirectoryReader() {
        desktopFiles = new HashTable<string, string> (str_hash, str_equal);
    }

    // Read desktop files from config dirs (system & user dirs)
    // if same file exists in multiple directories, the last found is keept.
    public void read_all() {
        foreach (string dir in Environment.get_system_config_dirs())
        {
            read_from_dir(dir);
        }

        read_from_dir(Environment.get_user_config_dir ());
    }


    // List all desktop file from directory, put names and fullpaths in the HashTable table
    public void read_from_dir(string directory) {
        unowned string filename;

        // TODO this should be in another function
        string dir_path = Path.build_filename(directory, "autostart");

        try
        {
            Dir d = Dir.open(dir_path, 0);
            info(@"\nParsing $dir_path");

            while ((filename = d.read_name ()) != null) {
                if (filename.has_suffix(".desktop")) {
                    desktopFiles.replace(filename, Path.build_filename(dir_path, filename));
                }
            }
        }
        catch (FileError e) {
            warning("Error: %s\n", e.message);
        }
    }

    // return a list of autostart files
    public unowned SList<string> getFiles() {
        desktopFiles.foreach((x, y) => {
            autostart_files.append(y);
        });

        return autostart_files;
    }
}
