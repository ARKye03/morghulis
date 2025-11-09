public class NotifPopItemsCenter : MorghulWindow {
    private AstalNotifd.Notifd _notifd;
    private Gtk.ListBox _notif_list_box;
    private GSound.Context _scontext;
    private uint _notif_count = 0;
    private uint _default_notification_timeout;
    private Queue<NotificationOperation?> _operation_queue;
    private uint _batch_process_timeout_id = 0;
    private uint _sound_timeout_id = 0;
    private bool _sound_playing = false;

    private const int MAX_NOTIFICATIONS = 6;
    private const uint SOUND_COOLDOWN_MS = 1000;

    public NotifPopItemsCenter(WindowAnchor x_anchor = WindowAnchor.RIGHT) {
        Object(
            title: "Notifications",
            anchor: WindowAnchor.TOP | x_anchor,
            default_width: 330,
            default_height: 0,
            margin: 5,
            css_classes: new string[] { "all_unset" },
            overflow: Gtk.Overflow.HIDDEN,
            namespace : "Morghulis.Notifications"
        );

        _default_notification_timeout = Morghulis.gsettings.get_uint("notifications-default-timeout");
        _operation_queue = new Queue<NotificationOperation?>();

        setup_sound();
        setup_window();
        setup_notifications();
    }

    private void setup_window() {
        this.notify["visible"].connect(() => {
            if (visible) {
                this.default_height = -1;
            } else {
                this.default_height = 0;
            }
        });

        this._notif_list_box = new Gtk.ListBox() {
            selection_mode = Gtk.SelectionMode.NONE,
            css_classes = { "boxed-list-separate" }
        };

        this.content = _notif_list_box;
    }

    private void setup_notifications() {
        this._notifd = AstalNotifd.Notifd.get_default();
        this._notifd.notified.connect((id, replace) => this.queue_notification(id, replace));
        this._notifd.resolved.connect((id) => this.queue_removal(id));
    }

    private void queue_notification(uint notification_id, bool replace) {
        NotificationOperation op = NotificationOperation() {
            id = notification_id,
            is_addition = true,
            is_replaced = replace
        };

        _operation_queue.push_tail(op);
        schedule_batch_process();
    }

    private void queue_removal(uint notification_id) {
        NotificationOperation op = NotificationOperation() {
            id = notification_id,
            is_addition = false,
            is_replaced = false
        };

        _operation_queue.push_tail(op);
        schedule_batch_process();
    }

    private void schedule_batch_process() {
        if (_batch_process_timeout_id > 0) {
            return;
        }

        _batch_process_timeout_id = Timeout.add(50, () => {
            process_batch();
            _batch_process_timeout_id = 0;
            return Source.REMOVE;
        });
    }

    private void process_batch() {
        bool should_play_sound = false;

        while (!_operation_queue.is_empty()) {
            var op = _operation_queue.pop_head();

            if (op.is_addition) {
                if (op.is_replaced) {
                    remove_notification_by_id(op.id);
                }

                if (process_addition(op.id)) {
                    should_play_sound = true;
                }
            } else {
                remove_notification_by_id(op.id);
            }
        }

        if (_notif_count > 0) {
            this.visible = true;
        } else {
            this.visible = false;
        }

        if (should_play_sound) {
            schedule_notification_sound();
        }
    }

    private bool process_addition(uint notification_id) {
        var notification = _notifd.get_notification(notification_id);

        if (notification == null) {
            return false;
        }

        if (_notifd.dont_disturb && notification.urgency != AstalNotifd.Urgency.CRITICAL) {
            return false;
        }

        if (_notif_count >= MAX_NOTIFICATIONS) {
            var oldest = (PopupNotificationItem)_notif_list_box.get_last_child();
            if (oldest != null) {
                remove_notification_immediately(oldest);
            }
        }

        var notif_item = new PopupNotificationItem(notification);
        this._notif_list_box.prepend(notif_item);
        this._notif_count++;

        uint timeout_ms = notification.expire_timeout > 0
                                                  ? notification.expire_timeout * 1000
                                                  : _default_notification_timeout;
        Timeout.add(timeout_ms, () => {
            queue_removal(notification_id);
            return Source.REMOVE;
        });

        return true;
    }

    private void remove_notification_by_id(uint notification_id) {
        PopupNotificationItem? notif_item = (PopupNotificationItem)_notif_list_box.get_first_child();

        while (notif_item != null) {
            if (notif_item.notification.id == notification_id) {
                remove_notification_with_animation(notif_item);
                return;
            }
            notif_item = (PopupNotificationItem)notif_item.get_next_sibling();
        }
    }

    private void remove_notification_with_animation(PopupNotificationItem notif_item) {
        if (notif_item.get_parent() == null) {
            return;
        }

        notif_item.dismiss_notif(false);
        Timeout.add(notif_item.transition_duration + 50, () => {
            if (notif_item.get_parent() != null) {
                this._notif_list_box.remove(notif_item);
                this._notif_count--;
                if (this._notif_count == 0) {
                    this.visible = false;
                }
            }
            return Source.REMOVE;
        });
    }

    private void remove_notification_immediately(PopupNotificationItem notif_item) {
        if (notif_item.get_parent() != null) {
            this._notif_list_box.remove(notif_item);
            this._notif_count--;
        }
    }

    private void schedule_notification_sound() {
        if (_sound_playing) {
            return;
        }

        if (_sound_timeout_id > 0) {
            return;
        }

        _sound_timeout_id = Timeout.add(0, () => {
            play_notification_sound.begin();
            _sound_timeout_id = 0;
            return Source.REMOVE;
        });
    }

    private void setup_sound() {
        try {
            this._scontext = new GSound.Context();
            this._scontext.init();
        } catch (Error e) {
            warning("Failed to create sound context: %s", e.message);
        }
    }

    private async void play_notification_sound() {
        if (_sound_playing) {
            return;
        }

        _sound_playing = true;

        if (!this._notifd.dont_disturb) {
            try {
                yield this._scontext.play_full(
                    null,
                    GSound.Attribute.EVENT_ID,
                    "message"
                );
            } catch (Error e) {
                warning("Failed to play sound: %s", e.message);
            }
        }

        Timeout.add(SOUND_COOLDOWN_MS, () => {
            _sound_playing = false;
            return Source.REMOVE;
        });
    }
}
