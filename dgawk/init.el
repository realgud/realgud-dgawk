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

;;; dgawk debugger

(eval-when-compile (require 'cl-lib))

(require 'realgud)
(require 'ansi-color)

(defvar realgud:dgawk-pat-hash)
(declare-function make-realgud-loc-pat (realgud-loc))

(defconst realgud:dgawk-frame-file-regexp
  (format "`\\(.+\\)':%s" realgud:regexp-captured-num))

(defconst realgud:dgawk-debugger-name "dgawk" "Name of debugger")

(defvar realgud:dgawk-pat-hash (make-hash-table :test 'equal)
  "hash key is the what kind of pattern we want to match:
backtrace, prompt, etc.  the values of a hash entry is a
realgud-loc-pat struct")

(declare-function make-realgud-loc "realgud-loc" (a b c d e f))

;; Regular expression that describes a dgawk location generally shown
;; before a command prompt.
;; For example:
;; Breakpoint 1, main() at `/usr/share/doc/lsof/examples/xusers.awk':35
(setf (gethash "loc" realgud:dgawk-pat-hash)
      (make-realgud-loc-pat
       :regexp (format "Breakpoint %s, .* at `%s"
		       realgud:regexp-captured-num realgud:dgawk-frame-file-regexp)
       :num 1
       :file-group 2
       :line-group 3))

;; Regular expression that describes a dgawk prompt
;; For example:
;;  dgawk>
(setf (gethash "prompt" realgud:dgawk-pat-hash)
      (make-realgud-loc-pat
       :regexp   "^dgawk> "
       ))

;; Regular expression that describes a "breakpoint set" line
;; For example:
;;   Breakpoint 1 set at file `/usr/share/doc/lsof/examples/xusers.awk', line 14
(setf (gethash "brkpt-set" realgud:dgawk-pat-hash)
      (make-realgud-loc-pat
       :regexp (format "^Breakpoint %s set at file `\\(.+\\)', line %s\n"
		       realgud:regexp-captured-num realgud:regexp-captured-num)
       :num 1
       :file-group 2
       :line-group 3))


(setf (gethash "font-lock-keywords" realgud:dgawk-pat-hash)
      '(
	;; The frame number and first type name, if present.
	("^\\(-->\\|   \\)? #\\([0-9]+\\)[ \t]+\\([^ ]*\\) at \\([^:]*\\):\\([0-9]*\\)"
	 (2 realgud-backtrace-number-face)
	 (3 font-lock-constant-face)        ; e.g. Object
	 (4 realgud-file-name-face)
	 (5 realgud-line-number-face))
	))


(defconst realgud:dgawk-frame-start-regexp
  "\\(?:^\\|\n\\)")

(defconst realgud:dgawk-frame-num-regexp
  (format "#%s" realgud:regexp-captured-num))

;; Top frame number
(setf (gethash "top-frame-num" realgud:dgawk-pat-hash) 0)

;; Regular expression that describes a dgawk "backtrace" command line.
;; #0	 main() at `/usr/share/doc/lsof/examples/xusers.awk':77
(setf (gethash "selected-frame" realgud:dgawk-pat-hash)
      (make-realgud-loc-pat
       :regexp 	(format "^%s.+[ ]+at %s"
			realgud:dgawk-frame-num-regexp
			realgud:dgawk-frame-file-regexp)
       :num 1
       :file-group 2
       :line-group 3)
      )

(setf (gethash "dgawk" realgud-pat-hash) realgud:dgawk-pat-hash)

;;  Prefix used in variable names (e.g. short-key-mode-map) for
;; this debugger

(setf (gethash "dgawk" realgud:variable-basename-hash) "realgud:dgawk")

(defvar realgud:dgawk-command-hash (make-hash-table :test 'equal)
  "Hash key is command name like 'continue' and the value is
  the dgawk command to use, like 'continue'")

(setf (gethash realgud:dgawk-debugger-name
	       realgud-command-hash) realgud:dgawk-command-hash)

(setf (gethash "break"    realgud:dgawk-command-hash) "break %l")
(setf (gethash "continue" realgud:dgawk-command-hash) "continue")
(setf (gethash "disable"  realgud:dgawk-command-hash) "disable breakpoints %p")
(setf (gethash "enable"   realgud:dgawk-command-hash) "enable breakpoints %p")
(setf (gethash "restart"  realgud:dgawk-command-hash) "run")

;; "print" is not quite a full eval, but it's the best gawk has
(setf (gethash "eval"  realgud:dgawk-command-hash) "print %s")

;; Unsupported features:
(setf (gethash "jump"     realgud:dgawk-command-hash) "*not-implemented*")
(setf (gethash "shell"    realgud:dgawk-command-hash) "*not-implemented*")


(provide-me "realgud:dgawk-")
