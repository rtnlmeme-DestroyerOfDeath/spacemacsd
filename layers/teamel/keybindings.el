(team/spacemacs-define-keys
 "oi"
 "teamel"
 '("l" . teamel/curl-yank)
 '("b" . teamel-add-debug-button)
 '("B" . teamel-add-debug-button-with-region)
 '("S" . teamel/yank-idlegame-sln)
 '("s" . teamel/open-sources)
 '("k" . teamel/add-config-here)
 '("r" . teamel/add-config-here)
 '("a" . teamel/do-awk)
 '("d" . teamel/find-file-downloads)
 '("v" . cos-find-view)
 )

(team/spacemacs-declare-keys
 "oi0"
 "tools"
 "u" #'teamel/add-used-implicitly
 "p" #'teamel/open-this-unity-proj
 "c" #'cog-target-ask
 "C" #'teamel/cog-target
 )

(defun cog-target-ask ()
  (interactive)
  (teamel/cog-target 1))

(team/spacemacs-declare-keys
    "oi1"
    "gitlab"
  "R" #'teamel/digest-resharper-warnings
  "r" #'teamel/next-resharper-warning
    )


(spacemacs/set-leader-keys
  "ea"  'flycheck-display-error-at-point)
