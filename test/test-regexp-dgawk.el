;; Press C-x C-e at the end of the next line to run this file test non-interactively
; (test-simple-run "emacs -batch -L %s -L %s -l %s" (file-name-directory (locate-library "test-simple.elc")) (file-name-directory (locate-library "realgud.elc")) buffer-file-name)

(require 'test-simple)
(require 'load-relative)
(require 'realgud)
(load-file "../dgawk/init.el")
(load-file "./regexp-helper.el")

(declare-function cmdbuf-loc-match      'realgud-regexp-helper)
(declare-function loc-match             'realgud-regexp-helper)
(declare-function prompt-match          'realgud-regexp-helper)
(declare-function __FILE__              'load-relative)

(test-simple-start)

(eval-when-compile
  (defvar dbg-name)   (defvar realgud-pat-hash)   (defvar realgud-bt-hash)
  (defvar loc-pat)    (defvar prompt-pat)         (defvar lang-bt-pat)
  (defvar file-group) (defvar line-group)         (defvar frame-pat)
  (defvar test-dbgr)  (defvar test-text)          (defvar frame-re)
)

(setq frame-pat  (gethash "selected-frame" realgud:dgawk-pat-hash))
(setq frame-re (realgud-loc-pat-regexp frame-pat))
;; Some setup usually done in setting up the buffer.
;; We customize this for this debugger.
;; FIXME: encapsulate this.
(setq dbg-name "dgawk")

(note "selected-frame matching")

(setq test-text "gawk> backtrace
#0	 main() at `xusers.awk':70
")

(setq num-group (realgud-loc-pat-num frame-pat))
(setq file-group (realgud-loc-pat-file-group frame-pat))
(setq line-group (realgud-loc-pat-line-group frame-pat))
(assert-equal 16 (string-match frame-re test-text))
(assert-equal "0" (substring test-text
			     (match-beginning num-group)
			     (match-end num-group)))
(assert-equal "xusers.awk"
	      (substring test-text
			 (match-beginning file-group)
			 (match-end file-group)))
(assert-equal "70"
	      (substring test-text
			 (match-beginning line-group)
			 (match-end line-group)))

(note "prompt")
(set (make-local-variable 'prompt-pat)
     (gethash "prompt" realgud:dgawk-pat-hash))
(prompt-match "dgawk> ")

(end-tests)
