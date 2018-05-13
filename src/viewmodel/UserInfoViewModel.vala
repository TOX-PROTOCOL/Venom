/*
 *    UserInfoViewModel.vala
 *
 *    Copyright (C) 2018 Venom authors and contributors
 *
 *    This file is part of Venom.
 *
 *    Venom is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    Venom is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with Venom.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Venom {
  public class UserInfoViewModel : GLib.Object {
    public string username { get; set; }
    public string statusmessage { get; set; }
    public Gdk.Pixbuf avatar { get; set; }
    public string tox_id { get; set; }
    public Gdk.Pixbuf tox_qr_code { get; set; }

    private ILogger logger;
    private UserInfo user_info;
    private UserInfoViewListener listener;
    private bool avatar_set;

    public UserInfoViewModel(ILogger logger, UserInfo user_info, UserInfoViewListener listener) {
      logger.d("UserInfoViewModel created.");
      this.logger = logger;
      this.user_info = user_info;
      this.listener = listener;

      update_info();
    }

    private void update_info() {
      logger.d("UserInfoViewModel update_info.");
      username = user_info.name;
      statusmessage = user_info.status_message;
      avatar = user_info.avatar;
      tox_id = user_info.tox_id;
    }

    public void on_apply_clicked() {
      logger.d("UserInfoViewModel on_apply_clicked.");
      try {
        listener.set_self_name(username);
        listener.set_self_status_message(statusmessage);
        if (avatar_set) {
          listener.set_self_avatar(avatar);
        } else {
          listener.reset_self_avatar();
        }
      } catch (GLib.Error e) {
        logger.e("UserInfoViewModel cannot set user info: " + e.message);
      } finally {
        update_info();
      }
    }

    private async void set_file_async(GLib.File file) {
      try {
        var stream = file.read();
        avatar = yield new Gdk.Pixbuf.from_stream_at_scale_async(stream, 128, 128, true);
      } catch (GLib.Error e) {
          logger.e("UserInfoViewModel can not read file: " + e.message);
      }
    }

    public void set_file(GLib.File file) {
      logger.d("UserInfoViewModel set_file.");
      avatar_set = true;
      set_file_async.begin(file);
    }

    public void reset_file() {
      avatar_set = false;
      avatar = pixbuf_from_resource(R.icons.default_contact, 128);
    }

    ~UserInfoViewModel() {
      logger.d("UserInfoViewModel destroyed.");
    }
  }

  public interface UserInfoViewListener : GLib.Object {
    public abstract void set_self_name(string name) throws GLib.Error;
    public abstract void set_self_status_message(string status_message) throws GLib.Error;
    public abstract void set_self_avatar(Gdk.Pixbuf pixbuf) throws GLib.Error;
    public abstract void reset_self_avatar() throws GLib.Error;
  }
}
