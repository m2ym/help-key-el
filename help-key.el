;;; help-key.el --- Keystroke helper

;; Copyright (C) 2013  Tomohiro Matsuyama

;; Author: Tomohiro Matsuyama <tomo@cx4a.org>
;; Keywords: help

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

;;; Commentary:

;; 

;;; Code:

(defgroup help-key nil
  "Keystroke helper"
  :group 'help
  :prefix "help-key-")

(defcustom help-key-polling-interval 0.1
  "Polling interval to describe key bindings."
  :type 'float
  :group 'help-key)

(defcustom help-key-describe-delay echo-keystrokes
  "Delay to describe key bindings."
  :type 'float
  :group 'help-key)

(defvar help-key-keys nil)

(defvar help-key-duration 0)

(defvar help-key-described-p nil)

(defvar help-key-timer nil)

(defun help-key-indirect-keymap-p (object)
  "Return t if OBJECT is a keymap or a symbol whose function cell
is a keymap."
  (or (keymapp object)
      (and (symbolp object)
           (fboundp object)
           (keymapp (symbol-function object)))))

(defun help-key-buffer ()
  (get-buffer-create "*Help-Key*"))

(defun help-key-describe (prefix)
  (setq help-key-described-p t)
  (let* ((buffer (current-buffer))
         (prefix-desc (key-description prefix))
         (prefix-re (concat "^" (regexp-quote prefix-desc) " ")))
    (with-current-buffer (help-key-buffer)
      (erase-buffer)
      (describe-buffer-bindings buffer prefix)
      (let ((point (point-min)))
        (goto-char point)
        (save-excursion
          (while (re-search-forward prefix-re nil t)
            (delete-region point (point))
            (forward-line 1)
            (setq point (point))))))
    (display-buffer (help-key-buffer))))

(defun help-key-finish ()
  (setq help-key-keys nil
        help-key-duration 0
        help-key-described-p nil)
  (kill-buffer (help-key-buffer)))

(defun help-key-tick ()
  (let ((keys (this-command-keys)))
    (if (and (> (length keys) 0)
             (equal keys help-key-keys))
        (progn
          (incf help-key-duration help-key-polling-interval)
          (when (and (<= help-key-describe-delay help-key-duration)
                     (not help-key-described-p)
                     (help-key-indirect-keymap-p (key-binding keys)))
            (help-key-describe keys)))
      (help-key-finish))))

(define-minor-mode help-key-mode
  "Help-Key mode."
  :global t
  (if help-key-mode
      (setq help-key-timer (run-with-timer t help-key-polling-interval 'help-key-tick))
    (cancel-timer help-key-timer)))

(provide 'help-key)

;;; help-key.el ends here
