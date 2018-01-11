/*-
 * Copyright (c) 2018-2018 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace ShowMyPictures.Utils {
    public static string get_default_album_title (int year, int month, int day) {
        string return_value = _("No Date");

        if (year > 0 && month > 0 && day > 0) {
            var date_time = new DateTime.local (year, month, day, 0, 0, 0);
            return_value = date_time.format ("%e. %b, %Y");
        }

        return return_value;
    }

    public static string get_month_name (int month) {
        var date_time = new DateTime.local (1, month, 1, 0, 0, 0);
        return date_time.format ("%B");
    }
}
