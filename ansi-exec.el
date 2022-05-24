;;; ansi-exec.el --- Run shell commands with ANSI output -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 Nan0Scho1ar
;;
;; Author: Nan0Scho1ar <scorch267@gmail.com>
;; Maintainer: Nan0Scho1ar <scorch267@gmail.com>
;; Created: May 25, 2022
;; Modified: May 25, 2022
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/nan0scho1ar/ansi-exec
;; Package-Requires: ((emacs "25.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Run shell commands with ANSI output
;;
;;; Code:

(require 'ansi-color)

(define-derived-mode ansi-exec-mode
  fundamental-mode "Ansi-Exec"
  "Major mode for ansi-exec.")

(defun ansi-exec-build-control-sequence-regexp (regexps)
  "Build control sequence regexp from list of REGEXPS."
  (mapconcat (lambda (regexp)
               (concat "\\(?:" regexp "\\)"))
             regexps "\\|"))

(defvar ansi-exec-non-sgr-control-sequence-regexp
  (ansi-exec-build-control-sequence-regexp
   '(;; icon name escape sequences
     "\033\\][0-2];.*?\007"
     ;; non-SGR CSI escape sequences
     "\033\\[\\??[0-9;]*[^0-9;m]"
     ;; noop
     "\012\033\\[2K\033\\[1F"
     ;; tput sgr0
     "\033(B"
     ))
  "Regexps which matches non-SGR control sequences.")

(defun ansi-exec/filter-non-sgr-control-sequences-in-region (begin end)
  "Remove non-SRG control sequences in region from BEGIN to END."
  (save-excursion
    (goto-char begin)
    (while
        (re-search-forward ansi-exec/non-sgr-control-sequence-regexp end t)
      (replace-match ""))))

(defun ansi-exec (cmd &optional buffname procname mode)
  "Run shell command CMD as process PROCNAME in buffer BUFFNAME and major-mode MODE."
  (unless buffname (setq buffname (format "* Ansi-Exec %s *" cmd)))
  (unless procname (setq procname (format "Ansi-Exec - %s" cmd)))
  (unless mode (setq mode #'ansi-exec/mode))
  (let ((buffer (get-buffer-create buffname)))
    (with-current-buffer buffer (erase-buffer) (funcall mode))
    (make-process :name procname
                  :buffer buffer
                  :command (list "bash" "-c" (format "TERM=xterm %s" cmd))
                  :noquery t
                  :sentinel #'ansi-exec/sentinel)))

(defun ansi-exec/sentinel (proc _event)
  "Handle output from PROC."
  (when (memq (process-status proc) '(exit signal))
    (with-current-buffer (process-buffer proc)
      (ansi-color-apply-on-region (point-min) (point-max))
      (ansi-exec/filter-non-sgr-control-sequences-in-region (point-min) (point-max)))
    (pop-to-buffer (process-buffer proc))))

(provide 'ansi-exec)
;;; ansi-exec.el ends here
