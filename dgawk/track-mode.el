;;; track-mode.el ---
;;; Copyright (C) 2016 Rocky Bernstein <rocky@gnu.org>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; dgawk tracking a comint or eshell buffer.

(eval-when-compile (require 'cl))

(require 'realgud)

(require-relative-list '("core" "init") "realgud:dgawk-")

(realgud-track-mode-vars "realgud:dgawk")

(declare-function realgud-track-mode 'realgud-track-mode)
(declare-function realgud:track-mode-hook 'realgud-track-mode)
(declare-function realgud-track-mode-setup 'realgud-track-mode)
(declare-function realgud:track-set-debugger 'realgud-track-mode)

(define-key realgud:dgawk-track-mode-map
  (kbd "C-c !b") 'realgud:goto-debugger-backtrace-line)

(defun realgud:dgawk-track-mode-hook()
  (use-local-map realgud:dgawk-track-mode-map)
  (realgud-track-mode-setup 't)
  (message "realgud:dgawk track-mode-hook called")
)

(define-minor-mode realgud:dgawk-track-mode
  "Minor mode for tracking dgawk inside a process shell via realgud.

If called interactively with no prefix argument, the mode is toggled. A prefix argument, captured as ARG, enables the mode if the argument is positive, and disables it otherwise.

Key bindings:
\\{realgud:dgawk-track-mode-map}
"
  :init-value nil
  ;; :lighter " dgawk"   ;; mode-line indicator from realgud-track is sufficient.
  ;; The minor mode bindings.
  :global nil
  :group 'realgud:dgawk
  :keymap realgud:dgawk-track-mode-map
  (realgud:track-set-debugger "realgud:dgawk")
  (if realgud:dgawk-track-mode
      (progn
        (realgud-track-mode-setup t)
        (realgud:dgawk-track-mode-hook))
    (progn
      (setq realgud-track-mode nil)
      ))
)

(provide-me "realgud:dgawk-")
;;; track-mode.el ends here
