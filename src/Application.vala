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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
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

namespace ShowMyPictures {
    public class ShowMyPicturesApp : Gtk.Application {
        public string DB_PATH { get; private set; }
        public string CACHE_FOLDER { get; private set; }
        public string PREVIEW_FOLDER { get; private set; }

        ShowMyPictures.Settings settings;

        static ShowMyPicturesApp _instance = null;
        public static ShowMyPicturesApp instance {
            get {
                if (_instance == null) {
                    _instance = new ShowMyPicturesApp ();
                }
                return _instance;
            }
        }

        construct {
            this.flags |= GLib.ApplicationFlags.HANDLES_OPEN;
            this.application_id = "com.github.artemanufrij.showmypictures";
            settings = ShowMyPictures.Settings.get_default ();

            var action_reset = action_generator ("Escape", "reset-action");
            action_reset.activate.connect (
                () => {
                    var win = get_active_window ();
                    if (win == mainwindow) {
                        (win as MainWindow).reset_action ();
                    } else {
                        (win as FastViewWindow).close ();
                    }
                });

            var toggle_details = action_generator ("F4", "toggle-details-action");
            toggle_details.activate.connect (
                () => {
                    var win = get_active_window ();
                    if (win == mainwindow) {
                        (win as MainWindow).toggle_details_action ();
                    } else {
                        (win as FastViewWindow).toggle_details_action ();
                    }
                });

            var action_rename = action_generator ("F2", "rename-action");
            action_rename.activate.connect (
                () => {
                    var win = get_active_window ();
                    if (win == mainwindow) {
                        (win as MainWindow).rename_action ();
                    } else {
                        (win as FastViewWindow).rename_action ();
                    }
                });

            var action_back = action_generator ("<Alt>Left", "back-action");
            action_back.activate.connect (
                () => {
                    var win = get_active_window ();
                    if (win == mainwindow) {
                        (win as MainWindow).back_action ();
                    }
                });

            var action_forward = action_generator ("<Alt>Right", "forward-action");
            action_forward.activate.connect (
                () => {
                    var win = get_active_window ();
                    if (win == mainwindow) {
                        (win as MainWindow).forward_action ();
                    }
                });

            var action_rotate_right = action_generator ("<Ctrl>Right", "rotate-right-action");
            action_rotate_right.activate.connect (
                () => {
                    var win = get_active_window ();
                    if (win == mainwindow) {
                        (win as MainWindow).rotate_right_action ();
                    } else {
                        (win as FastViewWindow).rotate_right_action ();
                    }
                });

            var action_rotate_left = action_generator ("<Ctrl>Left", "rotate-left-action");
            action_rotate_left.activate.connect (
                () => {
                    var win = get_active_window ();
                    if (win == mainwindow) {
                        (win as MainWindow).rotate_left_action ();
                    } else {
                        (win as FastViewWindow).rotate_left_action ();
                    }
                });

            create_cache_folders ();
        }

        private SimpleAction action_generator (string command, string action) {
            var return_value = new SimpleAction (action, null);
            add_action (return_value);
            add_accelerator (command, "app.%s".printf (action), null);
            return return_value;
        }

        public void create_cache_folders () {
            var library_path = File.new_for_path (settings.library_location);
            if (settings.library_location == "" || !library_path.query_exists ()) {
                settings.library_location = GLib.Environment.get_user_special_dir (GLib.UserDirectory.PICTURES);
            }
            CACHE_FOLDER = GLib.Path.build_filename (GLib.Environment.get_user_cache_dir (), application_id);
            try {
                File file = File.new_for_path (CACHE_FOLDER);
                if (!file.query_exists ()) {
                    file.make_directory ();
                }
            } catch (Error e) {
                warning (e.message);
            }
            DB_PATH = GLib.Path.build_filename (CACHE_FOLDER, "database.db");

            PREVIEW_FOLDER = GLib.Path.build_filename (CACHE_FOLDER, "preview");
            try {
                File file = File.new_for_path (PREVIEW_FOLDER);
                if (!file.query_exists ()) {
                    file.make_directory ();
                }
            } catch (Error e) {
                warning (e.message);
            }
        }

        private ShowMyPicturesApp () {
        }

        public MainWindow mainwindow { get; private set; default = null; }

        GLib.List<FastViewWindow> fastviews = null;

        protected override void activate () {
            create_instance ();
            mainwindow.present ();
        }

        public override void open (File[] files, string hint) {
            if (settings.use_fastview) {
                if (fastviews == null) {
                    fastviews = new GLib.List<FastViewWindow> ();
                }

                var fastview = create_fastview ();
                fastview.open_files (files);
                fastview.present ();
            } else {
                var first_call = mainwindow == null;
                create_instance (true);
                mainwindow.present ();
                mainwindow.open_files (files, first_call);
            }
        }

        private void create_instance (bool open_files = false) {
            if (mainwindow == null) {
                mainwindow = new MainWindow (open_files);
                mainwindow.application = this;
                mainwindow.delete_event.connect (
                    () => {
                        mainwindow = null;
                        return false;
                    });
            }
        }

        private FastViewWindow create_fastview () {
            if (fastviews.length () > 0 && !settings.use_fastview_multiwindow) {
                return fastviews.last ().data;
            }

            var fastview = new FastViewWindow ();
            fastview.application = this;
            fastview.delete_event.connect (
                () => {
                    fastviews.remove (fastview);
                    fastview = null;
                    return false;
                });

            fastviews.append (fastview);
            return fastview;
        }
    }
}

public static int main (string [] args) {
    var app = ShowMyPictures.ShowMyPicturesApp.instance;
    return app.run (args);
}