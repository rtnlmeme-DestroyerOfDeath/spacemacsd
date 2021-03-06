(require 'slack)

(setq slack-prefer-current-team t)
(setq slack-buffer-emojify t)
(setq slack-thread-also-send-to-room nil)
(setq slack-typing-visibility 'never)
(setq slack-enable-wysiwyg t)
(setq alert-default-style 'notifier)

(add-hook
 'slack-file-info-buffer-mode-hook
 #'(lambda ()
     (flyspell-mode -1)))


(spacemacs/set-leader-keys-for-major-mode
  'slack-message-compose-buffer-mode
  ","
  #'slack-message-send-from-buffer)

(defun benj-slack-updload (file &optional file-type)
  "Upload FILE, if FILE-TYPE is not given, read from user."
  (slack-file-upload file
                     (or file-type (slack-file-select-filetype (file-name-extension file)))
                     (read-from-minibuffer "Filename: " (file-name-nondirectory file))))


(defun benj-slack-upload-latest-screenshot ()
  "Upload the latest file in pictures dir."
  (interactive)
  (benj-slack-updload (or (benj-latest-screenshot)
                          (user-error "Nothing inside pictures directory.")) "png"))

(defun benj-slack-upload-latest-vid ()
  "Upload the latest file in vid dir."
  (interactive)
  (benj-slack-updload (latest-file "~/Videos/") "mp4"))



;; message notifier

(defun benj/slack-notifier (message room team)
  "Custom notifier using notifiy send and a sound."
  ;; TODO I want to use alert.el
  ;; see `slack-message-notify-alert'
  (if (slack-message-notify-p message room team)
      ;; hack
      (let* ((team-name (or (oref team name) "SingularityGroup"))
             (room-name (slack-room-name room team))
             (text (with-temp-buffer
                     (goto-char (point-min))
                     (insert (slack-message-to-alert message team))
                     (slack-buffer-buttonize-link)
                     (buffer-substring-no-properties (point-min)
                                                     (point-max))))
             (user-name (slack-message-sender-name message team))
             (title (if (slack-im-p room)
                        (funcall slack-message-im-notification-title-format-function
                                 team-name room-name (slack-thread-message-p message))
                      (funcall slack-message-notification-title-format-function
                               team-name room-name (slack-thread-message-p message))))
             (body (if (slack-im-p room) text (format "%s: %s" user-name text))))
        (if (and (eq alert-default-style 'notifier)
                 (slack-im-p room)
                 (or (eq (aref text 0) ?\[)
                     (eq (aref text 0) ?\{)
                     (eq (aref text 0) ?\<)
                     (eq (aref text 0) ?\()))
            (setq text (concat "\\" text)))

        ;; the only reason this exists is because I didnt' check `alert' enough to understand how to make it throw more
        ;; in you face notifications
        ;; (notifications-notify :body body
        ;;                       ;; :icon slack-alert-icon
        ;;                       :title title
        ;;                       ;; :sound-file (rand-element (split-string (shell-command-to-string (format "fd -I -e wav . %s" idlegame-project-root))))
        ;;                       ;; :urgency 'critical
        ;;                       )

        (alert body :icon slack-alert-icon :title title :category 'slack)
        ;; sounds are annoying when I play
        (benj/play-idlegame-sound)
        ))


  ;; TODO
  ;; store all messages in "~/org/slack-msgs/"
  ;; keep track which messagees are not seen
  ;; I could keep track of which rooms I looked at
  ;; could have a list of 'unseen' rooms on my disk

  )




(setq slack-message-custom-notifier 'benj/slack-notifier)








(defun benj-slack/upload-snippet-on-region ()
  "Create a temp file on region, call `slack-file-upload' with it."
  (interactive)
  (let ((file (team-create-temp-file-on-region)))
    ;; todo if the behaviour is too shit, then I take their room select thing there and open the buffer
    (slack-im-select)
    (benj-slack-updload file)))


(defun benj-slack/default-candidates ()
  "See `slack-im-select'"
  (cl-loop for team in (list team)
           for ims = (cl-remove-if #'(lambda (im)
                                       (not (oref im is-open)))
                                   (slack-team-ims team))
           nconc ims))

(defun benj-slack/im-select-pure ()
  (interactive)
  (let* ((team (slack-team-select))
         (candidates (cl-loop for team in (list team)
                              for ims = (cl-remove-if #'(lambda (im)
                                                          (not (oref im is-open)))
                                                      (slack-team-ims team))
                              nconc ims)))
    (slack-room-select candidates team)))



;; TODO read, good resource
;; https://medium.com/@justincbarclay/my-descent-into-madness-hacking-emacs-to-send-text-to-slack-bc6cf3780129
(defun jb/send-region-to-slack-code ()
  "Send selected region to slack"
  (interactive)
  (let ((team (slack-team-select)) ;; Select team
        (room (slack-room-select
               (cl-loop for team in (list team)
                        for channels = (oref team channels)
                        nconc channels)))) ;; Get all rooms from selected team
    (slack-message-send-internal (concat "```" (filter-buffer-substring (region-beginning) (region-end)) "```")
                                 (oref room id)
                                 team)))


(defun benj/play-idlegame-sound ()
  "Play some random idlegame sound."
  (interactive)
  (start-process
   "benj-slack-notifiy-sound"
   "*slack-notify-sound*"
   "aplay"
   ;; (rand-element (split-string (shell-command-to-string (format "fd -I -e wav rock %s" idlegame-project-root))))
   ))



(defun benj-slack/open-last-downloaded-file ()
  (interactive)
  (spacemacs//open-in-external-app
   (latest-file
    (expand-file-name slack-file-dir))))








(defconst benj-slack-leader-keys "o;")

(spacemacs/declare-prefix benj-slack-leader-keys "slack")

(progn
  (mapc (lambda (x)
          (spacemacs/set-leader-keys (concat benj-slack-leader-keys (car x)) (cdr x)))
        '(("u" . slack-file-upload)
          ("s" . benj-slack-upload-latest-screenshot)
          ("v" . benj-slack-upload-latest-vid)
          ("c" . benj-slack/upload-snippet-on-region)
          ("b" . slack-message-write-another-buffer))))


(dolist (mode '(slack-mode slack-message-buffer-mode slack-thread-message-buffer-mode))
  (spacemacs/set-leader-keys-for-major-mode mode
    "j" 'slack-channel-select
    "g" 'slack-group-select
    "r" 'slack-select-rooms
    "d" 'slack-im-select
    "p" 'slack-room-load-prev-messages
    "e" 'slack-message-edit
    "t" 'slack-thread-show-or-create
    "q" 'slack-ws-close
    "mm" 'slack-message-embed-mention
    "mc" 'slack-message-embed-channel
    "k" 'slack-select-rooms
    "@" 'slack-message-embed-mention
    "#" 'slack-message-embed-channel
    ")" 'slack-message-add-reaction
    "(" 'slack-message-remove-reaction)
  (let ((keymap (symbol-value (intern (concat (symbol-name mode) "-map")))))
    (evil-define-key 'insert keymap
      (kbd "@") 'slack-message-embed-mention
      (kbd "#") 'slack-message-embed-channel

      ;; override emojis, takes long and there is a bug atm
      (kbd ":") 'self-insert-command)))
