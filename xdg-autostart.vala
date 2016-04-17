/*
 * xdg-autostart
 * Copyright (c) 2011-2016 Fabrice THIROUX <fabrice.thiroux@free.fr>.
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
	/**
	* Returns true if Hidden is set in KeyFile, false otherwise.
	**/
	private static bool Hidden(GLib.KeyFile kf)
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

	/**
	* Returns true if 'desktop' appears in OnlyShowIn or not in NotShowIn
	* or if none of these keys are set.
	**/
	private static bool Visible(GLib.KeyFile kf, string desktop)
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
		catch (KeyFileError e)
		{
			warning("KeyFileError: %s\n", e.message);
		}
		return true;
	}

	/** 
	* Returns null if TryExec fails or if Exec is not set
	**/
	private static string? Exec(GLib.KeyFile kf)
	{
		string? tryexec;

		try
		{
			/* Lookup for TryExec file and check if it's found in path */
			if (kf.has_key("Desktop Entry", "TryExec")) {
				tryexec = kf.get_string("Desktop Entry", "TryExec");
				if (tryexec != null)
				{
					if (Environment.find_program_in_path (tryexec) == null)
					{
						message("Can't find %s from TryExec key, aborting.", tryexec);
						return null; // Exec is not found in path => exit
					}
				}
			}
			return kf.get_string ("Desktop Entry", "Exec");
		}
		catch (KeyFileError e)
		{
			warning("KeyFileError: %s\n", e.message);
		}

		return null;
	}

	/**
	* Returns X-GNOME-Autostart-Delay value or 0.
	**/
	private static int Delay(GLib.KeyFile kf)
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

	/**
	* Returns a DesktopFileInfo struct containing Exec and Delay fields.
	*/
	public static DesktopFileInfo? get_info(string filename, string desktop)
	{
		GLib.KeyFile kf = new KeyFile();

		try
		{
			if (kf.load_from_file (filename, KeyFileFlags.NONE))
			{	
				// We don't care about hidden or not visible app.							
				if (DesktopFileUtils.Hidden(kf) == true)
					return null;

				if (!DesktopFileUtils.Visible(kf, desktop))
					return null;

				// So far so good. let's create a new DesktopFileInfo struct.
				DesktopFileInfo info = DesktopFileInfo() {
					exec = DesktopFileUtils.Exec(kf),
					delay = DesktopFileUtils.Delay(kf)
				};
				
				// Useless if Exec is null.
				if (info.exec == null)
					return null;

				return info;
			}
		}
		catch (KeyFileError e)
		{
			warning("Error: %s\n", e.message);
		}
		return null;
	}
}


class XDG
{
	int seconds = 0;
	MainLoop main_loop;
	private string desktop;
	SList<DesktopFileInfo?> dfi_files = new SList<DesktopFileInfo?>();
	

	public XDG(string desktop)
	{
		this.desktop = desktop;
		
		// Contains <Filename, FullPath>
		HashTable<string, string> table = new HashTable<string, string> (str_hash, str_equal);
		
		foreach (string dir in Environment.get_system_config_dirs())
		{
			get_desktopfiles_from_dir(table, dir);
		}
		
		get_desktopfiles_from_dir(table, Environment.get_user_config_dir ());
		
		convert_table_to_DesktopFileInfos(table);	
	}
	
	
	/**
	* List all desktop file from directory, put their names and fullpath in the HashTable table
	*/
	private void get_desktopfiles_from_dir(HashTable<string, string> table, string directory)
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
		catch (FileError e)
		{
			warning("Error: %s\n", e.message);
		}
	}
	
	
	private void convert_table_to_DesktopFileInfos(HashTable<string, string> table)
	{
		table.foreach((k,v) =>
		{
			DesktopFileInfo? r = DesktopFileUtils.get_info(v, desktop);
			if (r != null)
			{
				dfi_files.append(r);
			}
		});
	}
	
	/**
	* Launch applications every timer pulse.
	**/
	private bool timer_cb()
	{
		dfi_files.foreach((x) =>
			{
				if (x.delay == seconds)
					{
					try {
						message("Launching: %s (delay %d)", x.exec, seconds);
						Process.spawn_command_line_async (x.exec);
						dfi_files.remove(x);
					}
					catch (SpawnError e)
					{
						warning("Error launching: %s\n", e.message);
					}
				}
			}
		);

		// There is no more application to launch	
		if (dfi_files.length() == 0) {
			main_loop.quit();
			return false;			
		}
		
		seconds++;
		return true;
	}
	
	
	public void Launch()
	{
		main_loop = new MainLoop ();
		GLib.Timeout.add_seconds (1, timer_cb);
		main_loop.run ();
	}
}

class Autostart
{
	static int main(string[] args)
	{
		var xdg = new XDG((args.length > 1) ? args[1] : "Openbox");
		xdg.Launch();

		return 0;
	}
}
