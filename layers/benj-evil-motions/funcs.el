
(defun benj-avy/jump (arg action &optional beg end)
  (setq avy-all-windows t)
  (avy-with avy-goto-word-0
    (avy-jump avy-goto-word-0-regexp
              :window-flip arg
              :beg beg
              :end end
              :action action)))

(defmacro benj-avy/point-action (&rest body)
  "Return a lambda form that takes one argument, a point.
Then goto hell with safe excursion and eval BODY.
Point arg is anaphorically bound to p."
  `(// (p)
       (save-excursion
         (goto-char p)
         ,@body)))

(defmacro benj-avy/yank-excursion (arg action-form &rest body)
  "Eval ACTION-FORM at avy destination. Use `avy-jump'.
When ACTION-FORM evals to non nil, bind it to it and execute BODY."
  (declare (debug body))
  (declare (indent 2))
  `(let ((it))
     (save-window-excursion
       (benj-avy/jump
        ,arg
        (benj-avy/point-action
         (setq it ,action-form))))
     ,@body))

(defun benj-avy/copy-word (&optional arg)
  (interactive"P")
  (benj-avy/yank-excursion
   arg
   (progn (kill-new (buffer-substring (point) (progn (forward-word) (point)))) t)
   (yank)))

(defun benj-avy/take-word (&optional arg)
  (interactive "P")
  (benj-avy/yank-excursion
   arg
   (progn (kill-word 1)
          (delete-region (point) (progn (forward-word) (point)))
          t)
   (yank)))

(defun benj-avy/move-region (&optional arg)
  (interactive"P")
  (let ((sel))
    (save-excursion
      (benj-avy/jump-timer-action
       arg
       (// (p)
           (print p)
         (setq sel (cons p sel)))))
    ;; (cl-labels
    ;sdfg;     ((put-point (place)
    ;;                 (save-excursion
    ;;                   (benj-avy/jump-timer-action
    ;;                    arg
    ;;                    (// (p) (print p) (setq place (cons p place)))))))
    ;;   (put-point sel)
    ;;   ;; (print sel)
    ;;   ;; (evil-delete (car sel) (cdr sel))
    ;;   ;; (evil-paste-after))
    ;;   )
    )
  )

(defadvice spacemacs/avy-open-url (around my/spacemacs-avy-open-url-adv activate)
  (avy-jump "https?://"
            :action
            (benj-avy/point-action
              (browse-url-at-point))))


(defun benj-avy/jump-timer-action (window-flip action)
  (setq avy-action (or action avy-action))
  (let ((avy-all-windows
         (if window-flip
             (not avy-all-windows)
           avy-all-windows)))
    (avy-with avy-goto-char-timer
      (setq avy--old-cands (avy--read-candidates))
      (avy-process avy--old-cands))))






;; evil mc

(defun my/insert-evil-mc-nums-simple (&optional arg)
  "Insert a number at each evil mc cursor, incremented by cursor index.
Start either at 0 or prefix ARG, if given."
  (interactive"P")
  (let ((num (or arg 0)))
    (evil-mc-execute-for-all-cursors
     (lambda (cursor)
       (insert
        (number-to-string
         (+ num
            (let ((it (evil-mc-get-cursor-property cursor :index)))
              (if (= it 0) (length evil-mc-cursor-list) (- it 1))))))))))






(defun my/re-replace-dwim (re replace)
  (let (res)
    (let ((bounds (or (and (region-active-p) (car (region-bounds))) (cons (point-at-bol) (point-at-eol)))))
      (save-excursion
        (goto-char (car bounds))
        (let ((end (my/marker-there (cdr bounds))))
          (while
              (and (> end (point))
                   (re-search-forward re end t))
            (replace-match replace)
            (setq res t)))))
    res))

(defmacro my/re--toggle-body (left right)
  `(or (my/re-replace-dwim ,left ,right)
      (my/re-replace-dwim ,right ,left)))

(defmacro my/define-re-toggle (left right)
  "Define an interactive func called my/re-toggle-LEFT-RIGHT that swappes the stirng returned by LEFT and RIGHT."
  (declare (indent defun))
  `(defun  ,(symb 'my/re-toggle- left '- right) ()
     (interactive)
     (my/re--toggle-body ,left ,right)))


(my/define-re-toggle
  "pet"
  "hero")
(my/define-re-toggle
  "left"
  "right")
(my/define-re-toggle
  "green"
  "red")
(my/define-re-toggle
  "menu"
  "overlay")
(my/define-re-toggle
  "week"
  "day")
(my/define-re-toggle
  "true"
  "false")
(my/define-re-toggle
  "up"
  "down")
(my/define-re-toggle
  "target"
  "actionButton")

(defun my/re-commata-newline ()
  "Replace occurances of , to a new line in region or line."
  (interactive)
  (my/re--toggle-body "," "\n"))






(defun my/evil-visual-line-around-here ()
  "Search backward and forward stopping at empty lines.
Then select with `evil-visual-line'. "
  (interactive)
  (-some-->
      (re-search-backward "^$" nil t)
    (and (forward-line 1)
         (point))
    (and
     (re-search-forward "^$" nil t)
     (forward-line -1)
     it)
    (evil-visual-line it (point))))

(defun my/evil-mc-make-cursors-around-here ()
  "Use `my/evil-visual-line-around-here' to select a region,
then make cursors"
  (interactive)
  (my/evil-visual-line-around-here)
  (evil-mc-make-cursor-in-visual-selection-beg)
  (evil-force-normal-state))


;; meta the meta
(defvar my/temp-devel-kbd "ott")

(defun my/eval-and-bind-func (&optional arg)
  "Eval func at point. Set keybinding to `my/temp-devel-kbd'.
When ARG is non nil prompt the user for the key binding following the <spcot> leader keys,"
  (interactive"P")
  ;; TODO find a way to check how many bindings we have and do a-z0-9, maybe regexing `describe-bindings' is good enough
  (spacemacs/set-leader-keys
    (if arg (concat "ot" (read-from-minibuffer "Key: ")) my/temp-devel-kbd)
    (eval-defun nil)))




















  ;; bookmarks

  ;; could try out how it would be to have a bookmark foreach workspace
  ;; (defvar my/last-bookmarked-file '())
  ;; (defun my/last-change-bookmark-funtion ()
  ;;   "If buffer is visiting a file different from `my/last-bookmarked-file',
  ;; Store a new book mark named \"last-work\"."
  ;;   (team/a-when
  ;;    (buffer-file-name)
  ;;    (unless (string-equal my/last-bookmarked-file it)
  ;;      (bookmark-set "last-work"))))


  

(defvar my/last-bookmarked-eyebrowse '())
(defvar my/last-bookmarks-lut (make-hash-table))
(defun my/last-change-bookmark-funtion ()
  "If buffer is visiting a file different from `my/last-bookmarked-file',
Store a new book mark named \"last-work\"."
  (team/a-when
   (buffer-file-name)
   (unless
       (string-equal it
                     (gethash my/last-bookmarked-eyebrowse my/last-bookmarks-lut))
     (setf (gethash my/last-bookmarked-eyebrowse my/last-bookmarks-lut) it)
     (let ((name (format "last-work-%s" my/last-bookmarked-eyebrowse)))
       (setq my/last-bookmarked-eyebrowse (eyebrowse--get 'current-slot))
       (bookmark-set name)))))

(defun my/last--bookmark-name (slot)
  (format "last-work-%s" slot))
(defun my/last--jump-bookmark (slot)
  (bookmark-jump (bookmark-get-bookmark (my/last--bookmark-name slot))))

(defun my/jump-last-bookmark ()
  "Jump to the last bookmark made by `my/last-change-bookmark-funtion'."
  (interactive)
  (eyebrowse-switch-to-window-config my/last-bookmarked-eyebrowse)
  (my/last--jump-bookmark my/last-bookmarked-eyebrowse))

(defun my/jump-last-bookmark-this-slot ()
  "Jump to last bookmark made for current eyebrowse slot."
  (interactive)
  (my/last--jump-bookmark (eyebrowse--get 'current-slot)))


(add-hook 'post-self-insert-hook
          #'my/last-change-bookmark-funtion)



;; chsarp syntax analysis example
;; (defun my/csharp-eldoc-to-param ()
;;   (interactive)
;;   (team/a-when
;;    team/eldoc-previous-message
;;    (print it)
;; (omnisharp--cs-element-stack-at-point
;;  (let ((type-string it))
;;    (lambda (stack)
;;      (setq best-elm (car (last stack)))
;;      (-let* (((&alist 'Kind kind
;;                       'Ranges ranges) (car (last stack)))
;;              ((&alist 'name  name) ranges)
;;              ((&alist 'Start start
;;                       'End end) name)
;;              ((&alist 'Line line
;;                       'Collumn coll) start))
;;        (->gg)
;;        (forward-line
;;         (- line 1))
;;        (forward-char coll)
;;        (insert "MOFOFO")
;;        )
;;      ;; (--> (car (last stack))
;;      ;;      ))))))





(defun my/comment-or-uncomment-sexpr ()
  "Use evilnc to toggle comment on sexpr."
  (interactive)
  (evil-lisp-state-prev-opening-paren)
  (evilnc--invert-comment
   (point)
   (save-excursion
     (evil-jump-item)
     (forward-char 1)
     (when (looking-at-p ")")
       (insert "\n")
       (indent-according-to-mode)
       (forward-line -1))
     (point)))
  (evil-normal-state))
