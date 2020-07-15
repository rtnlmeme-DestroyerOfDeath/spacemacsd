(spacemacs/declare-prefix-for-mode 'csharp-mode "o" "own")

(spacemacs/set-leader-keys-for-major-mode 'csharp-mode "or" 'benj-dotnet-run)
(spacemacs/set-leader-keys-for-major-mode 'csharp-mode "oE" 'benj-csharp-exclude-region)
(spacemacs/set-leader-keys-for-major-mode 'csharp-mode "oe" 'benj-csharp-exclude-buffer)
(spacemacs/set-leader-keys-for-major-mode 'csharp-mode "oo" 'omnisharp-show-overloads-at-point)
(spacemacs/set-leader-keys-for-major-mode 'csharp-mode "ol" 'omnisharp-show-last-auto-complete-result)
(spacemacs/set-leader-keys-for-major-mode 'csharp-mode "os" 'benj-csharp/string-interp-sourrund)
