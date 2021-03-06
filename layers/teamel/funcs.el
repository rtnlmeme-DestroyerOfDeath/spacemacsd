(require 'team-yas-snippets)

(defconst teamel-debug-buttons-file (concat idlegame-project-root "Assets/Editor/BestGlobals/DebugButtons.cs"))

(defun teamel/curl-yank ()
  "Usage: Click view complete raw in the job log, copy url into clipboard.
Expects some valid url in the unamed register"
  (interactive)
  (with-current-buffer-window
      "*curl-yank*"
      nil
      nil
      (teamel/curl-last-yank-this-buff)))

(defun teamel/curl-last-yank-this-buff ()
  (start-process
   "curl-website"
   (current-buffer)
   "curl"
   (teamel/last-yank)))


(defalias 'teamel/last-yank #'my/last-yank)
(defun my/last-yank ()
  (with-temp-buffer
    (yank)
    (buffer-string)))

(defmacro my/with-yank-buffer (&rest body)
  `(with-temp-buffer
     (yank)
     (->gg)
     ,@body))


(defun teamel/these-resharper-warning-files ()
  (-uniq (-map #'car teamel/these-resharper-warnings)))


(defun teamel/fix-menu-items-for-these-resharper-warnings ()
  "Depends on `teamel/these-resharper-warnings' being set,
add UsedImplicitly to all menu item syntax."
  (--map
   (team/with-file
    it
    (open-line 1)
    ;; FIXME there is a potential bug it the file already has
    ;; this names space
    (insert "using JetBrains.Annotations;")
    (team/while-reg
     "MenuItem"
     (->$ "[UsedImplicitly]")))
   (teamel/these-resharper-warning-files)))




;; todo
;;(defun teamel-delete-scriptass ())

(defun teamel-add-debug-button (&optional init)
  "Open debug buttons file and insert some stuff for a quick debug button.
If INIT is given, put it as start string for the method body."
  (interactive)
  (find-file teamel-debug-buttons-file)
  (goto-char (point-min))
  (re-search-forward "Ensures that the GoToGlobals button goes last")
  (forward-line 2)
  (insert
   "\n
    [Button(40)]
    [MenuItem(\"Best/besttest\")]
    public void besttest() {

    }
")
  (forward-line -2)
  (or (and init (insert init))
      (insert (make-string 2 ?\t)))
  (evil-insert-state))



(defun teamel-add-debug-button-with-region ()
  "Uses `teamel-add-debug-button' as subroutine.
Add debug button with region as init method body."
  (interactive)
  (teamel-add-debug-button (buffer-substring-no-properties (region-beginning) (region-end))))



(defun teamel-open-latest-video ()
  "Open latest file in ~/Videos with vlc."
  (interactive)
  ;; TODO use prefered app instead of vlc
  (start-process "latest-vid" "latest-vid" "vlc" (latest-file
                                                  "~/Videos")))



;; (helm :sources helm-benj-git-diff-lines-source)

;; (defun benj-git-diff-lines ()
;;   "Git diff output as lines."
;;   (let ((default-directory (magit-toplevel)))
;;     (process-lines "git" "diff" "-p" )))
;; (with-eval-after-load 'helm
;;   (defvar helm-benj-git-diff-lines-source
;;     (helm-build-sync-source "GitDiff" :candidates (benj-git-diff-lines))))


;; works
;;(helm :sources (helm-build-sync-source "name" :candidates '(( "best" . "bestreal" ) ("hehe" . "hehereal"))))

(defun teamel/idlegame-cog (&optional target)
  "Run cog idlegame."
  (interactive)
  (let ((default-directory "/home/benj/repos/codegen/"))
    (magit-run-git "clean" "-fd")
    (magit-run-git "reset" "--hard" "HEAD")
    (magit-run-git "pull" "origin" "refs/heads/master")
    (with-current-buffer-window
        "*cogg-idlegame*"
        nil
        nil
      (start-process
       "cogg-idlegame"
       (current-buffer)
       "python3"
       "runner.py"
       (or target idlegame-project-root)
       "-s"))))

(defun teamel/cog-target (&optional arg)
  "Run cog with file or directory.
If prefix ARG is non nil, ask for the file,
else run with current file"
  (interactive"P")
  (teamel/idlegame-cog
   (if arg (read-file-name "File to cogg: ")
     (progn
      (unless (buffer-file-name) (user-error "Buffer is not visiting a file."))
      (buffer-file-name)))))



(defun teamel/open-this-unity-proj ()
  "Open the untiy proj at PATH.
Use `projectile-locate-dominating-file' to get the unity proj root"
  (interactive)
  (when-let* ((proj (projectile-locate-dominating-file default-directory "Assets"))
              (name (file-name-base (directory-file-name proj))))
    (shell-command (format "unity-open %s %s" name proj))))


(defvar benj-flycheck/last-error-messages
  nil
  "Last error strings that `flycheck-pos-tip-error-messages' function was called with.")
(defun benj-flycheck/display-error-messages-advice (errors)
  "Advice after `flycheck-display-error-messages'. Set `benj-flycheck/last-error-messages' and also set register f with it."
  (evil-set-register
   ?f
   (setq benj-flycheck/last-error-messages (flycheck-help-echo-all-error-messages errors))))

(advice-add 'flycheck-pos-tip-error-messages :after #'benj-flycheck/display-error-messages-advice)


;; idlegame stuff

(defun teamel/yank-idlegame-sln ()
  (interactive)
  (kill-new (string-trim idlegame-sln-path)))


(defun teamel/yank-prefabs-for-rewrite ()
  "Try to search /IdleGame/prefab-analzyer-warnings.txt for paths and put them into /IdleGame/prefabs-for-rewrite.txt."
  (interactive)
  (let ((default-directory cos-dir))
    (team/with-file
     "IdleGame/prefabs-for-rewrite.txt"
     (insert
      (mapconcat
       #'identity
       (-uniq
        (team/with-file
         "prefab-analzyer-warnings.txt"
         (let ((res))
           (while (re-search-forward "Assets/Prefabs" nil t)
             (push (cadr (split-string (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
                   res))
           res)))
       "\n")))))

(defun teamel/open-sources ()
  (interactive)
  (let ((default-directory (concat idlegame-assets-dir "#/Sources")))
    (helm-find-files-1 " ")))



;; this function seems to be quite imperative. It would be a good exercise to rewrite in functional style
(defun teamel/add-config-here ()
  "Take the current field at point. Search in the same file for some config syntax
and expand a snippet for a 'With...(this config)' method."
  (interactive)
  (save-excursion
    (let ((class-name)
          (field-name)
          (interface-name)
          (type))
      (save-excursion
        (beginning-of-line)
        (re-search-forward
         "public \\([^ ]+\\) \\(\\w+\\)"
         (line-end-position))
        (setq field-name (match-string-no-properties 2))
        (setq type (match-string-no-properties 1))
        (re-search-backward
         "public \\(?:\\(?:struct\\)\\|\\(?:class\\)\\) \\(\\w+\\) \\(?:: \\(\\w+\\)\\)?"
         nil)
        (team/a-when (match-string-no-properties 2)
                     (setq interface-name it)
                     (save-excursion
                       (when (re-search-backward (concat "interface " it) nil t))
                       (team/in-new-line
                        (format "%s %s {get;set;}" type field-name))))
        (setq class-name (match-string-no-properties 1))
        (unless (re-search-forward "public static class" nil t)
          (->gm)
          (team/->new-line)
          (team-yas/expand-csharp-snippet
           "conf-ext-class-template"
           `((class-name ,class-name))))
        (team/csharp-snippet-insert
         "autobconf"
         "public static class "
         `((class-name ,(if interface-name "TConfig" class-name))
           (field-name ,field-name)
           (type ,type)
           (generic-type-part ,(if interface-name "<TConfig>" ""))
           (type-constraint-part
            ,(team/a-if interface-name (format " where TConfig : %s" it)
               ""))
           (field-name-capital ,(team/capitalize-first-letter field-name)))
         1)
        (re-search-backward "public static class" nil)
        (->$)
        (open-line 1))
      (kill-new (concat "config." field-name))
      (kill-new (concat "With" (team/capitalize-first-letter field-name)))))
  (forward-line 1))

(defun teamel/add-used-implicitly ()
  (interactive)
  (save-excursion
    (->gg)
    (team/in-new-line "using JetBrains.Annotations;")
    (team/while-reg
     "\\(\\[Button.*\\]\\)\\|\\(MenuItem\\)"
     (team/in-new-line " [UsedImplicitly]"))))





(defface teamel/flycheck-err-face
  '((((class grayscale) (background light))
     :foreground "DimGray" :weight bold :slant italic)
    (((class grayscale) (background dark))
     :foreground "LightGray" :weight bold :slant italic)
    (((class color) (min-colors 88) (background light))
     :foreground "Firebrick")
    (((class color) (min-colors 88) (background dark))
     :foreground "chocolate1"
     :background "DarkSlateBlue")
    (((class color) (min-colors 16) (background light))
     :foreground "red")
    (((class color) (min-colors 16) (background dark))
     :foreground "red1")
    (((class color) (min-colors 8) (background light))
     :foreground "red")
    (((class color) (min-colors 8) (background dark))
     :foreground "yellow")
    (t :weight bold :slant italic))
  "Face to display team flycheck errs."
  :group 'teamel/faces)



(defun teamel/flycheck-momentary-string-display-function (errors)
  "Not documented."
  (momentary-string-display
   (with-temp-buffer
     (insert (flycheck-help-echo-all-error-messages errors))
     (put-text-property
      (point-min) (point-max)
      'face 'teamel/flycheck-err-face)
     (buffer-string))
   (save-excursion
     (or (team/search-proximite "^$" -10) (progn (forward-line -1) (point))))
   ?f))


(defun team/search-proximite (reg reach)
  "Search for REG around point, going REACH forward and backward.
If REACH is a negative number, search backward first, else search forward first."
  (or (team/search-proximite1 reg reach)
      (team/search-proximite1 reg (* -1 reach))))

(defun team/search-proximite1 (reg reach)
  "Not documented."
  (funcall
   (if (= -1 (signum reach))
       #'re-search-backward
     #'re-search-forward)
   reg
   (save-excursion
     (forward-line reach)
     (point))
   t 1))

(defun team/setup-flycheck-display-function ()
  (setq flycheck-display-errors-function
        #'teamel/flycheck-momentary-string-display-function))


;; (add-hook 'flycheck-mode-hook #'team/setup-flycheck-display-function)




(defvar teamel/current-awk-script-func '())
;; (defvar teamel/current-awk-script-proc-func '())
(defun teamel/fire-up-awk ()
  (interactive)
  (unless (buffer-file-name)
    (user-error "You should visit a file for this."))
  (let ((target-file (buffer-file-name))
        (script-file "/tmp/awk-script.awk"))
    (split-window)
    (find-file script-file)
    (insert "{print $1}")
    ;; (setq teamel/current-awk-script-proc-func

    ;;       )
    (setq
     teamel/current-awk-script-func
     `(lambda (&optional buff)
         (interactive)
       (with-current-buffer-window
           "out"
           nil
           nil
         (set-process-sentinel
          (start-process
           "awk"
           (or buff (current-buffer))
           "awk"
           "-f"
           ,script-file
           ,target-file)
          (lambda (proc evnt)
            (pop-to-buffer (process-buffer proc))
            (->gg))))))))

(defun teamel/do-awk (arg)
  "Start an awk scripting session.
Abort current if ARG is non nil"
  (interactive"P")
  (when arg
    (setq teamel/current-awk-script-func nil))
  (funcall
   (--first
    (and (functionp it) it)
    (list
     teamel/current-awk-script-func
     #'teamel/fire-up-awk))))

(defun teamel/insert-this-awk ()
  "Take current `teamel/current-awk-script-func', put the output into the current buffer."
  (interactive)
  (when (functionp teamel/current-awk-script-func)
    (apply teamel/current-awk-script-func (list (current-buffer)))))


;; cos fixes

(defun team/cos-delete-metas-with-conflict-markers ()
  (team/with-default-dir
   cos-dir
   (let ((buff-name "meta-conflicts"))
     (with-current-buffer
         (get-buffer-create buff-name)
       (erase-buffer)
       (team/proc-cb-sentinel
        (start-process-shell-command
         "rg"
         (current-buffer)
         "rg -lN \"<<<<<<<\"")
        (lambda ()
          (with-current-buffer
              buff-name
            (->gg)
            (team/while-reg
             ".*\.meta$"
             (delete-file (match-string-no-properties 0))))))))))




(defun teamel/find-file-downloads ()
  (interactive)
  (let ((default-directory
          "~/Downloads/"))
    (call-interactively
     (lambda (file)
       (interactive"f")
       (find-file file))
     nil)))
