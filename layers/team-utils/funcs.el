;;; Code:
(defun team-create-temp-file-on-region ()
  "Create a file in temp data folder from active region,
return the file name of the create file"
  (interactive)
  (when (region-active-p)
    (let ((file (make-temp-file "team-file" nil nil (buffer-substring (region-beginning) (region-end)))))
      (find-file file)
      file)))


(defun team/find-duplicates (list)
  "Return a list that contains each element from LIST that occurs more than once."
  (--> list
       (-group-by #'identity it)
       (-filter (lambda (ele) (> (length ele) 2)) it)
       (mapcar #'car it)))


(defun team-make-backup-file ()
  "Make backup file of currently visited file."
  (interactive)
  (when (buffer-file-name)
    (copy-file (buffer-file-name) (concat (buffer-file-name ".bak")) t)))

(defun team-rename-thing-at-point ()
  "Prompt to rename the word-to-replace at point. In buffer."
  (interactive)
  (let* ((word-to-replace (thing-at-point 'word))
         (replace-with (read-from-minibuffer "Rename to: " word-to-replace)))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward word-to-replace nil t)
        (replace-match replace-with t)))))


(defun latest-file (path &optional reg)
  "Get latest file (excluding .. and .) in PATH."
  (let ((its-time (lambda (it) (nth-value 5 it))))
    (caar
     (--sort
      (time-less-p (funcall its-time other) (funcall its-time it))
      (directory-files-and-attributes path t (or reg "\\w+"))))))






(defvar team/eldoc-previous-message "")
(defun team/eldoc-save-last-message (orig &rest args)
  "Meant as an advice for `eldoc-message'."
  ;; override register e always with last msg
  (evil-set-register
   ?e
   (setq team/eldoc-previous-message
         ;; when eldoc clears the buffer this will be the empty string.
         ;; only keep track of the actual value
         (or (apply orig args) team/eldoc-previous-message))))
(advice-add 'eldoc-message :around #'team/eldoc-save-last-message)

(defun team/last-eldoc-csharp-no-type ()
  (interactive)
  (when team/eldoc-previous-message
    (evil-set-register ?a (string-trim-left team/eldoc-previous-message "\\w+ "))))


(defun team/evil-pop-register ()
  "Pop register 1, move all registers up. So 2 becomes and so on."
  (interactive))




(defmacro team/with-default-dir (dir &rest body)
  "Set `default-directory' to DIR and eval BODY."
  (declare (debug body))
  `(let ((default-directory ,dir))
     ,@body))


(defun team/mklist (obj)
  (if (listp obj) obj (list obj)))

(defmacro team/with-file (file &rest body)
  "Goto temp file FILE, insert file contents and evaluate BODY in there.
This also goes to point min point."
  (declare (debug body))
  (declare (indent 2))
  (let ((file-g (gensym)))
    `(let ((,file-g ,file))
       (with-temp-file
            ,file-g
          (insert-file-contents-literally ,file-g)
          (goto-char (point-min))
          ,@body))))

(defmacro team/--with-cs-files (dir &rest forms)
  "Eval FORMS with all cs files. Anaphoric it as the file name."
  `(--map
    (team/with-file it ,@forms)
    (directory-files-recursively ,dir "\\.cs$")))

(defmacro team/regexp-opt (&rest strings)
  `(regexp-opt '(,@strings)))




(defun team/regex-builder-with-region ()
  "Copy region into a temp file and start regex builder there"
  (interactive)
  (let ((str (region-str)))
    (find-file (team-create-temp-file-on-region))
    (delete-other-windows)
    (regexp-builder)
    (with-current-buffer
        (get-buffer reb-buffer)
      (insert str))))




(defvar team/yank-to-letter nil
  "The last used register for `yanks-to-letter-registers'")
(defun team/toggle-yank-to-letter ()
  "Toggle putting yanks into letter registers."
  (interactive)
  (setq  team/yank-to-letter (if team/yank-to-letter nil (- ?a 1)))
  (message
   (if team/yank-to-letter
       "yanks are stored in a,b,c.."
     "not yanking to a,b,c.. anymore")))

(defun team/yank--to-register-adv (func &rest args)
  "Advice for `evil-set-register'."
  (when (characterp team/yank-to-letter)
    (setq team/yank-to-letter
          (team/next-letter-register team/yank-to-letter))
    (evil-set-register team/yank-to-letter (teamel/last-yank))
    (when (> team/yank-to-letter
             (+ ?a 24))
      (setq team/yank-to-letter ?a))))


(advice-add #'evil-yank :after #'team/yank--to-register-adv)

(defun team/special-register-p (character)
  (pcase character
    (?e t)
    (?f t)
    (_ nil)))

(defun team/next-letter-register (it)
  (let ((next (+ 1 it)))
    (or
     (and (team/special-register-p
           next)
          (team/next-letter-register next))
     next)))





(defun team/path-parts (path)
  (--filter (not
             (string-empty-p it))
            (split-string path "/")))


(defun team/relative-path (a-path b-path)
  "The relative path looking from B-PATH to A-PATH, which should be
absolute paths. B-PATH can either be a directory, or a file name."
  (let ((a-parts (team/path-parts a-path))
        (b-parts (team/path-parts (file-name-directory b-path)))
        (res)
        (common-part-index)
        (common-part-over))
    (--map-indexed
     (when (not common-part-over)
       (if (equal (nth-value it-index b-parts) it)
           (setq common-part-index it-index)
         (setq common-part-over t)))
     a-parts)
    (setq res
          (subseq a-parts (+ common-part-index 1)))
    (--dotimes (- (length b-parts) (+ common-part-index 1))
      (push ".." res))
    (mapconcat #'identity res "/")))





(defmacro // (arglist &rest body)
  "Define a lambda with ARGLIST and BODY."
  (declare (indent 2))
  `(lambda ,arglist ,@body))


(defmacro team/when1 (form &rest forms)
  "Eval FORM, and then FORMS, if FORM returns non nil.
Return FORM value like `prog1' and `when' combined."
  (declare (debug form))
  (declare (debug forms))
  `(let ((res ,form))
     (when res
       ,@forms)
     res))

(defun team/nums (until)
  (let ((res))
    (--dotimes until
      (push it res))
    (nreverse res)))

(defmacro team/a-if (test then-form &rest else-forms)
  "If TEST form returns non nil, bind anaphoric it to it, then
eval THEN-FORM and return the return value of THEN-FORM.
Else eval ELSE-FORMS with implicit progn."
  (declare (debug then-form))
  (declare (debug else-forms))
  `(let ((it ,test)) (if it ,then-form ,@else-forms)))

(defmacro team/a-when (test &rest body)
  "Bind the value of TEST to it. When it is non nil, eval BODY with implicit progn."
  (declare (debug body))
  `(let ((it ,test)) (when it ,@body)))


(defmacro team/a-when-all (form &rest args)
  "Make a list out of ARGS, unless any item is nil, eval FORM,
with it anaphorically bound to a list of ARGS."
  (declare (debug form))
  `(let ((it (list ,@args)))
     (when (-all-p #'identity it)
       ,form)))



;; symbols and strings

(defun mkstr (&rest args)
  (with-output-to-string
    (dolist (elm args) (princ elm))))

(defun symb (&rest args)
  (intern (apply #'mkstr args)))



;; procs

(defun team/start-proc (name buffer program &rest args)
  "See `start-process', flatten args. If BUFFER is nil, user current buffer."
  (apply
   #'start-process
   (-flatten
    `(,name
      ,(or buffer (current-buffer))
      ,program
      ,@args))))

(defun team/start-buffer-process (name program &rest args)
  "Start proccess in a buffer NAME. See `start-process'. Return the buffer."
  (let ((buff (get-buffer-create name)))
    (with-current-buffer
        name
      (erase-buffer)
      (team/start-proc name nil program `,@args))
    buff))



;; elisp

(defun team/copy-file-re-replace (file reg replace)
  "Create a copy of FILE. Regex replace REG with REPLACE in file path,
return the name of the new file."
  (let ((new-file
         (team/re-replace-in-string file reg replace)))
    (unless (file-exists-p (file-name-directory new-file))
      (make-directory
       (file-name-directory new-file) t))
    (copy-file
     template-file
     new-file t)
    new-file))

(defun team/find-file (file line &optional coll)
  "Find file and goto LINE. When COLL is non nil, goto coll."
  (find-file file)
  (->gg)
  (forward-line line)
  (team/a-when coll (forward-char coll)))

(defun team/append-line-to-file (string file)
  "Thin wrapper around `append-to-file'. STRING the string to add, FILE the filename."
  (with-temp-buffer
    (insert string)
    (open-line 1)
    (append-to-file
     nil
     nil
     file)))

(defun team/skip-until (s)
  (skip-chars-forward (format "^" s)))

(defun mk-lines (list)
  (mapconcat 'identity list "\n"))
(defun mk-separated (list)
  (mapconcat 'identity list " "))

(defun team/delete-this-line ()
  (delete-region (- (point-at-bol) 1) (point-at-eol)))

(defmacro team/each-line (buffer-or-name-form &rest body)
  "Set buffer current to what BUFFER-OR-NAME-FORM evals.
Froeach line anaphorically set it to the line content, then run body."
  `(with-current-buffer
       ,buffer-or-name-form
     (->gg)
     (while (and (> (point-max) (point))
                 (re-search-forward "^.*$" nil t))
       (let ((it (match-string-no-properties 0)))
         ,@body))))

;; This doesn't exist in my whole emacs?
(defun my/marker-there (p)
  "Return the marker at point p."
  (save-excursion
    (progn (goto-char p) (point-marker))))

(defun my/region-end-marker ()
  "Return the marker at region end, when region is active."
  (when (region-active-p)
    (my/marker-there (region-end))))

(defun my/region-beginning-marker ()
  "Return the marker at region beginning, when region is active."
  (when (region-active-p)
    (my/marker-there (region-beginning))))

(defun team/proc-cb-sentinel (procc op)
  "Set PROCCs sentinel to a lambda that executes OP with no arguments,
if the exit status is 0. Else throw an error."
  (set-process-sentinel
   procc
   (lambda (p e)
     (when (string-equal "finished\n" e)
       (if (= 0 (process-exit-status p))
           (funcall op)
         (error  "Process %s exited abnormally with code %d"
                 (process-name p)
                 (process-exit-status p)))))))

(defmacro team/a-when-reg-this-line (reg match &rest body)
  "Search for REG on this line.
If search was succesfull bind match MATCH to it and eval BODY
with implicit progn"
  `(when (team/re-this-line ,reg t)
     (let ((it (match-string-no-properties ,match)))
       ,@body)))


(defun team/buff-content (buffer-or-name)
  (with-current-buffer
      buffer-or-name
    (buffer-string)))

(defun team/erase-that-buff (buffer-or-name)
  "Erase contents of BUFFER-OR-NAME."
  (with-current-buffer
      (get-buffer-create buffer-or-name)
    (erase-buffer)))

(defun team/build-append-to-buff (buffer-or-name &optional command)
  "Return a closure that takes one argument STRING and
appends STRING into BUFFER-OR-NAME."
  `(lambda (string)
     ,(when command
        '(interactive))
     (with-current-buffer
         (get-buffer-create ,buffer-or-name)
       (team/insert-line string))))

(defun line-> (line)
  "Goto LINE in curr buffer.
This is the version that the manual recommends for going to a line in lisp programs."
  (goto-char (point-min))
  (forward-line (- line 1)))

(defun line->> (line)
  "Goto to the end of LINE. See `line->'"
  `(progn
     (line->
         ,line)
     (goto-char (point-at-eol))))

(defun ->$ (&optional text)
  "Goto the end of the line.
With TEXT, insert TEXT at the end of the line."
  (goto-char (point-at-eol))
  (when text (insert text)))

(defun ->0 ()
  "Goto beginning of line"
  (goto-char (point-at-bol)))

(defmacro team/when-re-this-line (reg &rest body)
  "Execute BODY when REG is succesful on current line."
  `(save-excursion
    (->0)
    (when (re-search-forward ,reg (point-at-eol) t)
      ,@body)))

(defun team/re-this-line (reg &optional no-error)
  "Search for REG on current line. If NO-ERROR is non nil,
 do not err, if there is no match"
  (save-excursion
    (->0)
    (re-search-forward reg (point-at-eol) no-error)))

(defmacro team/^$-replace (reg replace &optional no-error)
  `(progn
     (team/re-this-line ,reg ,no-error)
     (replace-match ,replace)))

(defun region-str ()
  (buffer-substring-no-properties (region-beginning) (region-end)))

(defmacro team/--each-file (files &rest body)
  (declare (debug body))
  `(--map
    (team/with-file
     it
     ,@body)
    ,files))

(defmacro team/while-reg (reg &rest body)
  `(while (re-search-forward
           ,reg
           nil t)
     ,@body))

(defmacro team/while-file-reg (file reg &rest body)
  `(team/with-file
    ,file
    (team/while-reg
     ,reg
     ,@body)))

(defmacro team/re-replace (reg replace &optional fixedcase)
  `(team/while-reg
    ,reg
    (replace-match ,replace ,fixedcase)))


(defmacro team/re-replace-in-file (file reg replace)
  `(team/with-file
    ,file
    (team/re-replace
     ,reg ,replace)))

(defun team/->new-line ()
  "Open new line and forward to there."
  (open-line 1)
  (forward-line 1))


(defun team/insert-line (string)
  (insert string)
  (team/->new-line))

(defun team/in-new-line (string)
  "Insert STRING in new line and indent."
  (line->$)
  (team/->new-line)
  (insert string)
  (when (looking-back "\n")
    (forward-line -1))
  (indent-according-to-mode))

;; the default func for that is really wierd to use
(defmacro team/re-replace-in-string (string re replace &optional fixedcase)
  `(with-temp-buffer
    (insert ,string)
    (->gg)
    (team/re-replace ,re ,replace ,fixedcase)
    (buffer-string)))


(defun team/touch-empty-file (file)
  (write-region "" nil file))


(defun team/collect--reg (reg &optional match)
  "Collect REG matches into a list.
MATCH: The match data group to collect."
  (let ((res '()))
     (team/while-reg
      reg
      (setq res (cons (match-string-no-properties (or match 0)) res)))
     res))

(defun team/collect-reg (file reg match)
  "Collect all REG matcher in FILE.
MATCH: The match data group to collect."
  (team/with-file
   file
   (team/collect--reg reg match)))

(defun line->$ ()
  "Goto end of line."
  (goto-char (point-at-eol)))

(defun line->0 ()
  "Goto beginning of line"
  (goto-char (point-at-bol)))

(defun ->gg ()
  "Go to char min."
  (goto-char (point-min)))

(defun ->G ()
  "Go to char max"
  (goto-char (point-max)))

(defun team/capitalize-first-letter (s)
  (concat (capitalize (substring s 0 1)) (substring s 1)))

(defun team/un-capitalize (s)
  (concat (downcase (subseq s 0 1)) (subseq s 1)))


(defmacro teamel/a-indent (&rest body)
  "Bind current indent to indent and execute body"
  (declare (indent 2))
  `(let ((indent (current-indentation)))
     ,@body))

(defun team/collect-reg-to-buff (file reg match)
  "Collec REG in FILE. Put the output into a buffer and return that buffer."
  (let ((buff (get-buffer-create "collect-reg-buff")))
    (with-current-buffer buff
      (erase-buffer))
    (cl-flet
        ((insert-it
          (it)
          (with-current-buffer
              buff
            (team/insert-line it))))
      (team/while-file-reg
       file
       (insert-it (match-string-no-properties match))))
    buff))

(defmacro team/then-indent-like-here (&rest body)
  "Take the current indent and point, execute body.
Then indent between current point and the old point."
  (declare (debug body))
  `(let ((p (point-marker))
         (indent (current-indentation)))
     ,@body
     (indent-region (min p (point)) (max p (point)) indent)))

(defun team/insert-indented (&rest strings)
  (team/then-indent-like-here
   (--each
       strings
     (insert it))))


(defun team/make-null-term (&optional file)
  "Replace newline for null char in FILE, or the buffer file."
  (interactive)
  (team/re-replace-in-file
   (or file
       (buffer-file-name)
       (user-error "No file provided and buffer is not visiting a file either."))
   "\n"
   "\0"))


;; lists

(defun group (source n)
  (when (zerop n) (error "zero length"))
  (labels ((rec (source acc)
                (let ((rest (nthcdr n source)))
                  (if (consp rest)
                      (rec rest (cons (subseq source 0 n) acc))
                    (nreverse (cons source acc))))))
    (if source (rec source nil) nil)))



;; should move stuff that is not really utils
(defconst team/stack-buff "*team/stack*")
(defalias 'team/push-to-stack-buff (team/build-append-to-buff team/stack-buff t))

(defun team/push-to-stack-buff ()
  (interactive)
  (team/build-append-to-buff team/stack-buff))

(defun team/push-region-to-stack ()
  (interactive)
  (team/push-to-stack-buff (region-str)))

(defun team/stack-buff-contents ()
  (team/buff-content
   team/stack-buff))

;; (defun benj-slack/msg-stack-buff ()
;;   (interactive)
;;   (slack-im-select)
;;   (slack-message-send-from-buffer)
;;   (insert team/stack-buff-contents))

(defun team/pop-stack-buff ()
  (interactive)
  "Flush the whole contents of `team/stack-buff' into the current buffer."
  (insert (team/stack-buff-contents))
  (team/erase-that-buff team/stack-buff))



(provide 'team-utils)
