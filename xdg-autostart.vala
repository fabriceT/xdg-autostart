/*
 * xdg-autostart
 * Copyright (c) 2011-2014 Fabrice THIROUX <fabrice.thiroux@free.fr>.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; either version 3 of the License, or any
 * later version. See http://www.gnu.org/copyleft/lgpl.html the full text
 * of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 */

struct DesktopFileInfo {
	int delay;
	string exec;
}


class DesktopFileUtils
{
	// Returns true if Hidden is set in KeyFile, false otherwise.
	protected static bool is_hidden(GLib.KeyFile kf)
	{
		try
		{
			/* Hidden desktop file don't have to be launched */
			if (kf.has_key ("Desktop Entry", "Hidden"))
				return kf.get_boolean("Desktop Entry", "Hidden");
		}
		catch (KeyFileError e) {
			warning("KeyFileError: %s\n", e.message);
		}
		return false;
	}


	// Returns true if 'desktop' appears if OnlyShowIn or not in NotShowIn
	// or if none of these keys are set.
	protected static bool is_visible(GLib.KeyFile kf, string desktop)
	{
		bool found = false;
		string[] show_list;

		try
		{
			/* Check if the desktop file is launched in current desktop environment */
			if (kf.has_key("Desktop Entry", "OnlyShowIn"))
			{
				show_list = kf.get_string_list("Desktop Entry", "OnlyShowIn");
				foreach (string de in show_list)
				{
					if (de == desktop)
					{
						found = true;
						break;
					}
				}
				/* Current desktop is not found in the OnlyShowIn list */
				if (found == false)
				{
					//message ("Not found in OnlyShowIn list, aborting.");
					return false;
				}
			}
			/* Check if the desktop file is not launched in current desktop environment */
			else if (kf.has_key("Desktop Entry", "NotShowIn"))
			{
				show_list = kf.get_string_list("Desktop Entry", "NotShowIn");
				foreach (string de in show_list)
				{
					if (de == desktop)
					{
						//message ("Found in NotShowIn list, aborting.");
						return false;
					}
				}
			}
		}
		catch (KeyFileError e) {
			warning ("KeyFileError: %s\n", e.message);
		}
		return true;
	}

	// Get Exec field. Returns null if TryExec fails or if Exec is not set
	protected static string? get_exec(GLib.KeyFile kf)
	{
		string? tryexec;

		try {
			/* Lookup for TryExec file and check if it's found in path */
			if (kf.has_key("Desktop Entry", "TryExec")) {
				tryexec = kf.get_string("Desktop Entry", "TryExec");
				if (tryexec != null) {
					if (Environment.find_program_in_path (tryexec) == null) {
						message("Can't find %s from TryExec key, aborting.", tryexec);
						return null; // Exec is not found in path => exit
					}
				}
			}
			return kf.get_string ("Desktop Entry", "Exec");
		}
		catch (KeyFileError e) {
			warning("KeyFileError: %s\n", e.message);
		}

		return null;
	}

	// Returns X-GNOME-Autostart-Delay value or 0.
	protected static int get_delay(GLib.KeyFile kf)
	{
		try
		{
			if (kf.has_key("Desktop Entry", "X-GNOME-Autostart-Delay"))
			{
				return kf.get_integer("Desktop Entry", "X-GNOME-Autostart-Delay");
			}
		}
		catch (KeyFileError e)
		{
			warning("KeyFileError: %s\n", e.message);
		}

		return 0;
	}

	// Return a DesktopFileInfo struct containing Exec and Delay fields.
	public static DesktopFileInfo? get_info(string filename, string desktop)
	{
		GLib.KeyFile kf =new KeyFile();
		DesktopFileInfo info = DesktopFileInfo();

		try {
			if (kf.load_from_file (filename, KeyFileFlags.NONE)) {

				if (DesktopFileUtils.is_hidden(kf) == true)
					return null;

				if (!DesktopFileUtils.is_visible(kf, desktop))
					return null;

				info.exec = DesktopFileUtils.get_exec(kf);

				if (info.exec == null)
					return null;

				info.delay = DesktopFileUtils.get_delay(kf);
				return info;
			}
		}
		catch (KeyFileError e) {
			warning ("Error: %s\n", e.message);
		}
		return null;
	}
}


class Autostart
{
	static string desktop;
	static SList<DesktopFileInfo?> desktopfileinfos;
	static int loop_count = 0;		// counter for the seconds
	static int max_delay = 0;		// max execution time
	static MainLoop loop;				// GLib loop

	private static bool timer_cb()
	{
		foreach (DesktopFileInfo? info in desktopfileinfos)
		{
			if (info.delay == loop_count)
			{
				try {
					message("Launching: %s (delay %d)", info.exec, loop_count);
					Process.spawn_command_line_async (info.exec);
				}
				catch (SpawnError e) {
					warning("Error launching: %s\n", e.message);
				}
			}
		}

		stdout.flush();

		loop_count++;

		if (loop_count > max_delay)
		{
			loop.quit();
			return false;
		}
		else
			return true;
	}


	static void launch_file(string key, string filename)
	{
		DesktopFileInfo? info = DesktopFileUtils.get_info(filename, desktop);
		if (info != null)
		{
			//stdout.printf("adding %s\n", info.exec);
			desktopfileinfos.append(info);

			if (info.delay > max_delay)
			{
				max_delay = info.delay;
			}
		}
	}


	static void get_files_in_dir(HashTable<string, string> table, string directory)
	{
		unowned string filename;
		string dir_path = Path.build_filename(directory, "autostart");

		try
		{
			Dir d = Dir.open(dir_path, 0);

			while ((filename = d.read_name ()) != null)
			{
				if (filename.has_suffix(".desktop"))
				{
					table.replace(filename, Path.build_filename(dir_path, filename));
				}
			}
		}
		catch (FileError e) {
			warning ("Error: %s\n", e.message);
		}
	}


	static int main(string[] args)
	{
		HashTable<string, string> desktop_files = new HashTable<string, string> (str_hash, str_equal);
		weak string[] dirs = Environment.get_system_config_dirs();

		if (args.length > 1)
		{
			desktop = args[1];
		}
		else
		{
			desktop = "Openbox";
		}

		foreach (string dir in dirs)
		{
			get_files_in_dir(desktop_files, dir);
		}

		get_files_in_dir(desktop_files, Environment.get_user_config_dir ());

		if (desktop_files.size() > 0)
		{
			desktop_files.for_each(launch_file);
			loop = new MainLoop ();
			GLib.Timeout.add_seconds (1, timer_cb);
			loop.run ();
		}

		return 0;
	}
}
