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

namespace ShowMyPictures.Objects {
    public class Picture : GLib.Object {
        public signal void preview_created ();

        int _ID = 0;
        public int ID {
            get {
                return _ID;
            } set {
                _ID = value;
                if (value > 0) {
                    preview_path = GLib.Path.build_filename (ShowMyPicturesApp.instance.PREVIEW_FOLDER, ("picture_%d.png").printf (this.ID));
                }
            }
        }

        public string preview_path { get; private set; }

        string _path = "";
        public string path {
            get {
                return _path;
            } set {
                _path = value;
                if (ID == 0) {
                    exclude_exif ();
                }
            }
        }

        public string mime_type { get; set; default = ""; }
        public int year { get; set; default = 0; }
        public int month { get; set;  default = 0; }
        public int day { get; set;  default = 0; }
        public int rotation { get; private set; default = 1; }

        public Album? album { get; set; default = null; }

        Gdk.Pixbuf? _preview = null;
        public Gdk.Pixbuf? preview {
            get {
                if (_preview == null) {
                    create_preview.begin ();
                }
                return _preview;
            } private set {
                if (_preview != value) {
                    _preview = value;
                    preview_created ();
                }
            }
        }

        bool preview_creating = false;

        public Picture (Album? album = null) {
            this.album = album;
        }

        public string get_default_album_title () {
            return Utils.get_default_album_title (year, month, day);
        }

        public void exclude_exif () {
            var exif_data = Exif.Data.new_from_file (path);
            exif_data.foreach_content ((content, user) => {
                content.foreach_entry ((entry, user) => {
                    var tag = entry.tag;
                    var tag_string  = entry.get_string ();
                    if (tag == Exif.Tag.DATE_TIME_ORIGINAL) {
                        var date_string = tag_string.split (" ")[0];
                        Date date = {};
                        date.set_parse (date_string);
                        (user as Objects.Picture).year = date.get_year ();
                        (user as Objects.Picture).month = date.get_month ();
                        (user as Objects.Picture).day = date.get_day ();
                    } else if (entry.tag == Exif.Tag.ORIENTATION) {
                        (user as Objects.Picture).rotation = Exif.Convert.get_short (entry.data, Exif.ByteOrder.INTEL);
                    }
                }, user);
            }, this);
        }

        public async void create_preview () {
            if (preview_creating) {
                return;
            }
            new Thread<void*> (null, () => {
                preview_creating = true;
                if (GLib.FileUtils.test (preview_path, GLib.FileTest.EXISTS)) {
                    try {
                        preview = new Gdk.Pixbuf.from_file (preview_path);
                    } catch (Error err) {
                        warning (err.message);
                    }
                }
                if (preview != null) {
                    preview_creating = false;
                    return null;
                }
                try {
                    var pixbuf = new Gdk.Pixbuf.from_file (path);
                    if (rotation == 3) {
                        pixbuf = pixbuf.rotate_simple (Gdk.PixbufRotation.UPSIDEDOWN);
                    } else if (rotation == 6) {
                        pixbuf = pixbuf.rotate_simple (Gdk.PixbufRotation.CLOCKWISE);
                    } else if (rotation == 8) {
                        pixbuf = pixbuf.rotate_simple (Gdk.PixbufRotation.COUNTERCLOCKWISE);
                    }
                    pixbuf = Utils.align_and_scale_pixbuf_for_preview (pixbuf);
                    pixbuf.save (preview_path, "png");
                    preview = pixbuf;
                    pixbuf.dispose ();
                } catch (Error err) {
                    warning (err.message);
                }
                preview_creating = false;
                return null;
            });
        }
    }
}
