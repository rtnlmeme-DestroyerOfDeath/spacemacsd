
;; rg
(setq-default helm-grep-ag-command "rg --color=always --smart-case --no-heading --line-number %s %s %s")
(setq-default helm-ag-use-grep-ignore-list 't)
(setq-default helm-candidate-number-limit 100)
(setq-default helm-ag-base-command "rg --color=never --no-heading" )


(defun benj/helm-find-file-recursively ()
  "Recursively find files in glob manner, in the specified directory."
  (interactive)
  (helm-find 'ask-for-dir))



;; swoop advice against big buffers

(advice-add 'helm-swoop :before-while #'benj/helm-swoop-advice)
(defun benj/helm-swoop-advice (&rest args)
  "Meant to advice before-until `helm-swoop'."
  (if (> (line-number-at-pos (point-max)) 10000)
      (progn
        (message "Buffer is a bit big for swoop. Use `spc s f' instead.")
        nil)
    t))



;; blockwise swoop

(defun team-helm/hs-block ()
  "Set point to beginning of block, evaluate to point at end of block. See `hs-hide-block'"
  (require 'hideshow)
  (interactive)
  (let ((comment-reg (hs-inside-comment-p)))
    (cond
     ((and comment-reg (or (null (nth 0 comment-reg))
                     (<= (count-lines (car comment-reg) (nth 1 comment-reg)) 1)))
      (message "(Not enough comment lines)"))
     ((or comment-reg
	        (hs-looking-at-block-start-p)
          (hs-find-block-beginning))
      (if comment-reg
          (error "Comments not supported yet.")
          ;; (hs-hide-comment-region (car comment-reg) (cadr comment-reg) end)
        (when (hs-looking-at-block-start-p)
          (let ((mdata (match-data t))
                (header-end (match-end 0))
                p q ov)
	          ;; `p' is the point at the end of the block beginning, which
	          ;; may need to be adjusted
	          (save-excursion
	            (goto-char (funcall (or hs-adjust-block-beginning #'identity)
			                            header-end))
	            (setq p (line-end-position)))

	          ;; `q' is the point at the end of the block
	          (hs-forward-sexp mdata 1)
	          (setq q (if (looking-back hs-block-end-regexp nil)
		                    (match-beginning 0)
		                  (point)))
            (when (and (< p q) (> (count-lines p q) 1))
              (set-mark q))
            (goto-char (min p header-end)))))))))


(defun team-helm/swoop-block-swoop ()
  "Narrow the buffer to the current block and run `helm-swoop'.
For many use cases, see `narrow-to-defun', "
  (interactive)
  (team-helm/hs-block)
  (narrow-to-region (point) (mark))
  (helm-swoop))

(defun team-helm/swoop-narrow-fun ()
  "Narrow the buffer to the current defun and run `helm-swoop'."
  (interactive)
  (narrow-to-defun)
  (helm-swoop))


;; TODO i though about advising `helm-swoop--get-content' or something inside thre
;; (defvar team-helm/narrow-swoop-to-region nil)
;; to have a helm swoop without narrowing the buffer









;; helm rg

(defmacro benj-helm-ag/define-proj-search (name init-form &rest args)
  "Define a proj search. INIT-FORMAT is a form that evaluates to the initial helm input.
ARGS are additional arguments for the rg search."
  (let ((name (intern (concat "benj-helm-ag/" (symbol-name name)))))
    `(defun ,name ()
     (interactive)
     (let ((helm-ag-base-command
            ,(if args
                 (concat helm-ag-base-command " "
                         (mapconcat #'identity (-flatten args) " "))
               helm-ag-base-command)))
        (helm-do-ag
         (projectile-project-root)
         nil
         ,init-form)))))

(benj-helm-ag/define-proj-search
 comp-matcher
 (format "Matcher(?s:.)? \\. (?s:.)? \\b%s\\b" (thing-at-point 'evil-word))
 "-U")

(benj-helm-ag/define-proj-search
 comp-value
 (format "\\.((Get)|(Is))<%s>\\(\\)\(\\.value\)?" (thing-at-point 'evil-word)))

(benj-helm-ag/define-proj-search
 comp-value-set
 (format "\\.((Add)|(Set)|(Replace))<%s>\\(" (thing-at-point 'evil-word)))

(benj-helm-ag/define-proj-search
 flag-set
 (format "\\.Set<%1$s>\\(%1$s\\)" (thing-at-point 'evil-word)))

(benj-helm-ag/define-proj-search
 implementations
 (format "\\w+\\s+%s\\(.*\\{" (thing-at-point 'evil-word)))


;; helm-do-ag
;; targets
;; eg
;; (list "Market" "Merchant")



(defun benj-helm-ag/do-ag-prefixed (&optional arg)
  "Run `helm-do-ag'.
Prefix arg can be:
0 - public
1 - public class {
2 - public \\\( \\\)
3 - public static \\\( \\\)"
  (interactive"P")
  (helm-do-ag
   (projectile-project-root)
   nil
   (pcase arg
     (0 "public")
     (1 "public class {")
     (2 "public \\( \\)")
     (3 "public static \\( \\)")
     (_ (user-error "invalid prefix arg %d" arg)))))


;; something where you (first) fuzzily filter for files
;; and then only search matching files




(with-eval-after-load
    'rg
    (rg-define-search sailor-rg-project-multiline
      "See `sailor-rg-search-in-project' allow multiline matches"
      :files current
      :dir project
      :flags '("--multiline"))

    (defun sailor-find-comp-matched ()
      "Search for matcher syntax with things at point."
      (interactive)
      (sailor-rg-project-multiline (sailor--matcher-syntax (thing-at-point 'evil-word))))

    (defun sailor--matcher-syntax (comp)
      "Get matcher syntax for COMP."
      (format "Matcher(\n)?(\n\r)?\.(\n)?(\n\r)?.*%s\\b" comp)))












;; TEMP hack because somebody fucked up, the helm-aif part can return `t' instead of a number
(defun benj/temp-helm-update-source-p-hack (source)
  "Benj TEMP hack. Whether SOURCE needs updating or not."
  (let ((len (string-width
              (if (assq 'multimatch source)
                  ;; Don't count spaces entered when using
                  ;; multi-match.
                  (replace-regexp-in-string " " "" helm-pattern)
                helm-pattern))))
    (and (or (not helm-source-filter)
             (member (assoc-default 'name source) helm-source-filter))
         (>= len
             (let ((res (helm-aif (assq 'requires-pattern source) (or (cdr it) 1) 0)))
               (or (and (number-or-marker-p res) res) 0)))
         ;; Entering repeatedly these strings (*, ?) takes 100% CPU
         ;; and hang emacs on MacOs preventing deleting backward those
         ;; characters (issue #1802).
         (not (string-match-p "\\`[*]+\\'" helm-pattern))
         ;; These incomplete regexps hang helm forever
         ;; so defer update. Maybe replace spaces quoted when using
         ;; multi-match.
         (not (member (replace-regexp-in-string "\\s\\ " " " helm-pattern)
                      helm-update-blacklist-regexps)))))

(advice-add 'helm-update-source-p :around #'(lambda (orig-func &rest args) (benj/temp-helm-update-source-p-hack (car args))))
