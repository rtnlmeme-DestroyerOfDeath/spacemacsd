(defconst sharpel-repo-root "/home/benj/repos/csharp/roslyn-stuff/Sharpel/")
(defconst sharpel-proj-dir (concat sharpel-repo-root "Sharpel/"))
(defconst sharpel-sln-path (concat sharpel-repo-root "Sharpel.sln"))
(defconst sharpel-release-exe-dir (concat sharpel-proj-dir "bin/Release/netcoreapp3.0/"))
(defconst sharpel-debug-exe-dir (concat sharpel-proj-dir "bin/Debug/netcoreapp3.0/"))
(defconst sharpel-release-exe-path (concat sharpel-release-exe-dir "Sharpel.dll"))
(defconst sharpel-debug-exe-path (concat sharpel-debug-exe-dir "Sharpel.dll"))
(defconst sharpel-buff-name "*sharpel*")

(defvar sharpel-process nil)

(defun sharpel-start-proc ()
  "Start roslyn proc and switch to output buffer"
  (let ((default-directory sharpel-proj-dir))
    (setq sharpel-process (start-process "benj-roslyn" sharpel-buff-name "dotnet" "run"))
   (switch-to-buffer-other-window sharpel-buff-name)))

(defun sharpel--start (&rest args)
  "Start sharpel with ARGS"
  (let ((default-directory sharpel-proj-dir))
    (setq sharpel-process (benj-start-proccess-flatten-args "sharpel" sharpel-buff-name "dotnet" "run" args))
    (switch-to-buffer-other-window sharpel-buff-name)))

(defun sharpel-build (config)
  "Compile the sharpel project. CONFIG is either 'Release' or 'Debug' "
  (interactive)
  (sharpel-clean-proc)
  (benj-msbuild-sln sharpel-sln-path config))


(defun sharpel-clean-proc ()
  "Delete process and reset state."
  (interactive)
  (when (processp sharpel-process)
    (progn (delete-process sharpel-process) (setq benj-roslyn-process nil))))

(defun sharpel-ensure-proc ()
  "Ensure that there is a benj roslyn process"
  (unless (and sharpel-process (processp sharpel-process) (process-live-p sharpel-process))
          (sharpel-start-proc)))


(defun sharpel-refresh-proc ()
  "Refresh sharpel compilation. And create new proc."
  (interactive)
  ;; (sharpel-build "Debug") ;; dotnet run is good enough
  (sharpel-clean-proc)
  (sharpel-ensure-proc))


(defun sharpel-logsyntax-req ()
  "Send active region as logsyntax request"
  (interactive)
  (sharpel--runner
   (concat ":logsyntax:\n"
           (replace-regexp-in-string "[ \t\n\r]+" " " (buffer-substring (region-beginning) (region-end)))
           ;; (replace-regexp-in-string "[\n\r]+" (make-string 1 ?\0) (buffer-substring (region-beginning) (region-end)))
           "\n"))
  (org-mode))


(defun sharpel-file-command-on-region ()
  "Create a file command using a temp file created from region."
  (interactive)
  (sharpel--send-file-name-command (team-create-temp-file-on-region)))

(defconst sharpel-command-kinds
  '((:filename . ":filename:")
    (:logsyntax . ":logsyntax:")
    (:rewrite-file . ":rewrite-file:"))
  "Possible cammands send to sharpel proc.")

(defvar sharpel-last-input nil)
(defvar sharpel-last-file-send nil)

;; TODO maybe select file, default to buffer file
(defun sharpel-send-file-name-command ()
  "Send current buffer file name command to sharpel."
  (interactive) ;; interactive list form
  (sharpel--send-file-name-command buffer-file-name))

(defun sharpel-rewrite-file (file-name)
  "Run sharpel with rewrite reqeust and FILE-NAME"
  (interactive "fFile for const rewrite: ")
  (sharpel-run-cmd :rewrite-file file-name))

(defun sharpel--send-file-name-command (file-name)
  "Send FILE-NAME as input to sharpel."
  (setq sharpel-last-file-send file-name)
  (sharpel-run-cmd :filename file-name))

(defun sharpel--command (cmd body)
  "Build sharpel command input. With header CMD and BODY.
Valid options for CMD are defined in `sharpel-command-kinds'."
  (concat (cdr (assoc cmd sharpel-command-kinds)) "\n" body "\n"))

(defun sharpel-rerun-last-file-command ()
  "Rerun last file command, if set."
  (interactive)
  (if sharpel-last-file-send (sharpel--send-file-name-command sharpel-last-file-send)
    (message "No previous file send command.")))

(defun sharpel-run-cmd (cmd body)
  "See `sharpel--runner'. Run sharpel with command CMD, which must be one of `sharpel-command-kinds' and input BODY."
  (sharpel--runner (sharpel--command cmd body)))

(defun sharpel--runner (input)
  "Ensure sharpel and run input"
  (sharpel-ensure-proc)
  (setq sharpel-last-input input)
  (process-send-string sharpel-process input)
  (unless (string-equal (buffer-name) sharpel-buff-name)
    (pop-to-buffer sharpel-buff-name))
  (csharp-mode))

(defun sharpel-rerun-last ()
  "Rerun the last sharpel command."
  (interactive)
  (if sharpel-last-input (sharpel--runner sharpel-last-input)))




(defun sharpel-one-shot (&rest args)
  "Call one shot sharpel with ARGS"
  (interactive)
  (shell-command-to-string (format "sharpel %s" (mapconcat 'identity args " "))))

(defun sharpel-split-classes (file)
  "Call sharpel split classes with FILE arg"
  (sharpel-one-shot "--split-classes" file))


(defun sharpel-try-compilation ()
  (interactive)

  (sharpel-one-shot "--try-compilation"))