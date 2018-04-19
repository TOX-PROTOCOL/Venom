/*
 *    ToxAdapterConferenceListener.vala
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
  public class ToxAdapterConferenceListenerImpl : ToxAdapterConferenceListener, ConferenceWidgetListener, ConferenceInfoWidgetListener, CreateGroupchatWidgetListener, GLib.Object {
    private unowned ToxSession session;
    private ILogger logger;
    private ObservableList contacts;
    private NotificationListener notification_listener;
    private GLib.HashTable<IContact, ObservableList> conversations;

    private GLib.HashTable<uint32, IContact> conferences;

    public ToxAdapterConferenceListenerImpl(ILogger logger, ObservableList contacts, GLib.HashTable<IContact, ObservableList> conversations, NotificationListener notification_listener) {
      logger.d("ToxAdapterConferenceListenerImpl created.");
      this.logger = logger;
      this.contacts = contacts;
      this.conversations = conversations;
      this.notification_listener = notification_listener;

      conferences = new GLib.HashTable<uint32, IContact>(null, null);
    }

    ~ToxAdapterConferenceListenerImpl() {
      logger.d("ToxAdapterConferenceListenerImpl destroyed.");
    }

    public virtual void attach_to_session(ToxSession session) {
      this.session = session;
      session.set_conference_listener(this);
    }

    public virtual void on_remove_conference(IContact c) throws Error {
      var contact = c as Conference;
      session.conference_delete(contact.conference_number);
    }

    public virtual void on_change_conference_title(IContact c, string title) throws Error {
      var contact = c as Conference;
      session.conference_set_title(contact.conference_number, title);
    }

    public virtual void on_send_conference_message(IContact c, string message) throws Error {
      var conference = c as Conference;
      session.conference_send_message(conference.conference_number, message);
    }

    public virtual void on_create_groupchat(string title, GroupchatType type) throws Error {
      session.conference_new(title);
    }

    public virtual void on_conference_new(uint32 conference_number, string title) {
      logger.d("on_conference_new");
      var contact = new Conference(conference_number, title);
      contacts.append(contact);
      conferences.@set(conference_number, contact);
      var conversation = new ObservableList();
      conversation.set_list(new GLib.List<IMessage>());
      conversations.@set(contact, conversation);
    }

    public virtual void on_conference_deleted(uint32 conference_number) {
      logger.d("on_conference_deleted");
      var contact = conferences.@get(conference_number);
      contacts.remove(contact);
      conversations.remove(contact);
      conferences.remove(conference_number);
    }

    public virtual void on_conference_title_changed(uint32 conference_number, uint32 peer_number, string title) {
      var contact = conferences.@get(conference_number) as Conference;
      contact.title = title;
      contact.changed();
    }

    public virtual void on_conference_peer_list_changed(uint32 conference_number, ToxConferencePeer[] peers) {
      var contact = conferences.@get(conference_number) as Conference;
      var gcpeers = contact.get_peers();
      gcpeers.clear();
      for(var i = 0; i < peers.length; i++) {
        var peer_number = peers[i].peer_number;
        var peer_key = Tools.bin_to_hexstring(peers[i].peer_key);;
        var peer = new ConferencePeer(peer_number, peer_key, peers[i].peer_name, peers[i].is_known, peers[i].is_self);
        gcpeers.@set(peer_number, peer);
      }
      contact.changed();
    }

    public virtual void on_conference_peer_renamed(uint32 conference_number, ToxConferencePeer peer) {
      var contact = conferences.@get(conference_number) as Conference;
      var peers = contact.get_peers();
      var peer_number = peer.peer_number;
      var gcpeer = peers.@get(peer_number);
      gcpeer.peer_key = Tools.bin_to_hexstring(peer.peer_key);
      gcpeer.peer_name = peer.peer_name;
      gcpeer.is_known = peer.is_known;
      gcpeer.is_self = peer.is_self;
      contact.changed();
    }

    public virtual void on_conference_message(uint32 conference_number, uint32 peer_number, ToxCore.MessageType type, string message) {
      logger.d("on_conference_message");
      var contact = conferences.@get(conference_number) as Conference;
      var conversation = conversations.@get(contact);
      var peer = contact.get_peers().@get(peer_number);
      var msg = new ConferenceMessage.incoming(conference_number, peer.peer_key, peer.peer_name, message);
      notification_listener.on_unread_message(msg, contact);
      contact.unread_messages++;
      contact.changed();
      conversation.append(msg);
    }

    public virtual void on_conference_message_sent(uint32 conference_number, string message) {
      logger.d("on_conference_message_sent");
      var contact = conferences.@get(conference_number) as Conference;
      var conversation = conversations.@get(contact);
      var msg = new ConferenceMessage.outgoing(conference_number, message);
      msg.received = true;
      conversation.append(msg);
    }
  }
}
