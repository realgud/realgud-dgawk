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

(eval-when-compile (require 'cl-lib))

(require 'realgud)

(declare-function realgud:expand-file-name-if-exists 'realgud-core)
(declare-function realgud-lang-mode? 'realgud-lang)
(declare-function realgud-parse-command-arg 'realgud-core)
(declare-function realgud-query-cmdline 'realgud-core)

;; FIXME: I think the following could be generalized and moved to
;; realgud-... probably via a macro.
(defvar realgud:dgawk-minibuffer-history nil
  "minibuffer history list for the command `dgawk'.")

(easy-mmode-defmap realgud:dgawk-minibuffer-local-map
  '(("\C-i" . comint-dynamic-complete-filename))
  "Keymap for minibuffer prompting of gud startup command."
  :inherit minibuffer-local-map)

;; FIXME: I think this code and the keymaps and history
;; variable should be generalized, perhaps via a macro.
(defun realgud:dgawk-query-cmdline (&optional opt-debugger)
  (realgud-query-cmdline
   'realgud:dgawk-suggest-invocation
   realgud:dgawk-minibuffer-local-map
   'realgud:dgawk-minibuffer-history
   opt-debugger))

(defun realgud:dgawk-parse-cmd-args (orig-args)
  "Parse command line ARGS for the annotate level and name of script to debug.

ORIG_ARGS should contain a tokenized list of the command line to run.

We return the a list containing
* the name of the debugger given (e.g. dgawk) and its arguments - a list of strings
* the awk script name
* the script name and its arguments - list of strings

For example for the following input
  (map 'list 'symbol-name
   '(dgawk -f columnize.awk -n ./gcd.awk a b))

we might return:
   ((\"dgawk\" \"-f\" \"columnize.awk\' \"-n\") \"columnize.awk\" \"(a b\")

Note that path elements have been expanded via `expand-file-name'.
"

  ;; Parse the following kind of pattern:
  ;;  dgawk dgawk-options script-name script-options
  (let (
	(args orig-args)
	(pair)          ;; temp return from

	;; One dash is added automatically to the below, so
	;; "f" is really "-f" and "-file" is really "--file".
	(dgawk-two-args '("f" "-file" "F" "e" "-source" "E" "-exec" "R" "-command"))
	(dgawk-opt-two-args '("L" "-lint"))

	;; Things returned
	(script-name nil)
	(debugger-name nil)
	(debugger-args '())
	(script-args '()))

    (if (not (and args))
	;; Got nothing: return '(nil nil nil nil)
	(list debugger-args nil script-args nil)
      ;; else
      (progn

	;; Remove "dgawk" from "dgawk --dgawk-options script
	;; --script-options"
	(setq debugger-name (file-name-sans-extension
			     (file-name-nondirectory (car args))))
	(unless (string-match "^[d]?gawk.*" debugger-name)
	  (message
	   "Expecting debugger name `%s' to start `dgawk or gawk'"
	   debugger-name))
	(setq debugger-args (list (pop args)))

	;; Skip to the first non-option argument.
	(while (and args (not script-name))
	  (let ((arg (car args)))
	    (cond
	     ;; Annotation or emacs option with level number.
	     ;; Options with arguments.
	     ((string-match "^-" arg)
	      (setq pair (realgud-parse-command-arg
			  args dgawk-two-args dgawk-opt-two-args))
	      (nconc debugger-args (car pair))
	      (if (or (equal "-f" (caar pair))
		      (equal "--file" (cadr pair)))
		  (setq script-name (copy-sequence (cadar pair))))
	      (setq args (cadr pair)))
	     ;; Anything else must be the script to debug.
	     (t (setq script-name arg)
		(setq script-args args))
	     )))
	(list debugger-args script-name script-args)))))

(defvar realgud:dgawk-command-name)

(defun realgud:dgawk-executable (file-name)
"Return a priority for wehther file-name is likely we can run dgawk on"
  (let ((output (shell-command-to-string (format "file %s" file-name))))
    (cond
     ((string-match "ASCII" output) 2)
     ((string-match "ELF" output) 7)
     ((string-match "executable" output) 6)
     ('t 5))))


(defun realgud:dgawk-suggest-invocation (&optional debugger-name)
  "Suggest a dgawk command invocation. Here is the priority we use:
* an executable file with the name of the current buffer stripped of its extension
* any executable file in the current directory with no extension
* the last invocation in dgawk:minibuffer-history
* any executable in the current directory
When all else fails return the empty string."
  (let* ((file-list (directory-files default-directory))
	 (priority 2)
	 (best-filename nil)
	 (try-filename (file-name-base (or (buffer-file-name) "dgawk"))))
    (when (member try-filename (directory-files default-directory))
	(setq best-filename try-filename)
	(setq priority (+ (realgud:dgawk-executable try-filename) 2)))

    ;; FIXME: I think a better test would be to look for
    ;; c-mode in the buffer that have a corresponding executable
    (while (and (setq try-filename (car-safe file-list)) (< priority 8))
      (setq file-list (cdr file-list))
      (if (and (file-executable-p try-filename)
	       (not (file-directory-p try-filename)))
	  (if (equal try-filename (file-name-sans-extension try-filename))
	      (progn
		(setq best-filename try-filename)
		(setq priority (1+ (realgud:dgawk-executable best-filename))))
	    ;; else
	    (progn
	      (setq best-filename try-filename)
	      (setq priority (realgud:dgawk-executable best-filename))
	      ))
	))
    (if (< priority 8)
	(cond
	 (realgud:dgawk-minibuffer-history
	  (car realgud:dgawk-minibuffer-history))
	 ((equal priority 7)
	  (concat "dgawk " best-filename))
	 (t "dgawk "))
      ;; else
      (concat "dgawk " best-filename))
    ))

(defun realgud:dgawk-reset ()
  "Dgawk cleanup - remove debugger's internal buffers (frame,
breakpoints, etc.)."
  (interactive)
  ;; (dgawk-breakpoint-remove-all-icons)
  (dolist (buffer (buffer-list))
    (when (string-match "\\*dgawk-[a-z]+\\*" (buffer-name buffer))
      (let ((w (get-buffer-window buffer)))
        (when w
          (delete-window w)))
      (kill-buffer buffer))))

;; (defun dgawk-reset-keymaps()
;;   "This unbinds the special debugger keys of the source buffers."
;;   (interactive)
;;   (setcdr (assq 'dgawk-debugger-support-minor-mode minor-mode-map-alist)
;; 	  dgawk-debugger-support-minor-mode-map-when-deactive))


(defun realgud:dgawk-customize ()
  "Use `customize' to edit the settings of the `realgud:dgawk' debugger."
  (interactive)
  (customize-group 'realgud:dgawk))

(provide-me "realgud:dgawk-")
