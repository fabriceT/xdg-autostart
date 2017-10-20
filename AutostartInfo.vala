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

struct AutostartInfo {
    public string filename;
    public bool visibility;
    public int delay;
    public string executable;

    public bool is_launchable() {
        return visibility && executable != null;
    }

    public string to_string() {
        StringBuilder sb = new StringBuilder();
        if (filename != null) {
            sb.append(@"$filename: ");
        }

        if (is_launchable()) {
            sb.append(@"'$executable' will be launched in $delay sec.");
        }
        else {
            sb.append("ignored");
        }

        return sb.str;
    }
}
