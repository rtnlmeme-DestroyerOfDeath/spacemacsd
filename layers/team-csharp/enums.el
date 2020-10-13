
(defun team-csharp/enum-values ()
  "Catch enum values around point.
This evaluates to a list of lists. Each element is of the form
(NAME NUM). NUM is optional if there is a \" = digit\" part in the definition of the enum."
  (team-helm/hs-block)
  (let ((res '()))
    (team/while-reg
     "\\(?:^.*//.*$\\)\\|\\([[:blank:]]\\(\\w+\\)\\(?: = \\([[:digit:]]+\\)\\)?\\)"
     (when (match-string-no-properties 2)
       (push (list (match-string-no-properties 2)
                   (match-string-no-properties 3))
             res)))
    (nreverse res)))




(defun team-csharp/append-to-enum (name &optional num-syntax)
  "Append NAME to the botton of enum around point. When NUM-SYNTAX is non nil,
also add a number, which is either the +1 the last of such numbers, or +1 the count of enum elements."
  (team/a-when
   (team-csharp/enum-values)
   (team/skip-until "}")
   (forward-line -2)
   (team/in-new-line
    (format "%s%s," name
            (or (and num-syntax
                     (format " = %d"
                             (+ 1
                                (string-to-number
                                 (or (cadar (last it))
                                     (length it)))))) "")))))
