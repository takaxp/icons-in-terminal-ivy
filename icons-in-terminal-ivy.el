;;; icons-in-terminal-ivy.el --- Shows icons while using ivy and counsel  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Takaaki Ishikawa
;; Copyright (C) 2017 asok

;; Author: Takaaki Ishikawa
;; Version: 0.0.1
;; Keywords: faces
;; Package-Requires: ((emacs "24.4") (icons-in-terminal "0.1.0") (ivy "0.8.0"))

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
;; To use this package, do
;;
;; (icons-in-terminal-ivy-setup)
;;
;; Or if you prefer to only set transformers
;; for a subset of ivy commands:
;;
;; (require 'icons-in-terminal-ivy)
;; (ivy-set-display-transformer 'ivy-switch-buffer 'icons-in-terminal-ivy-buffer-transformer)
;;
;; Note: This elisp is mostly copied from `all-the-icons-ivy.el'. Thanks to asok!

;;; Code:

(require 'icons-in-terminal)
(require 'ivy)

(defface icons-in-terminal-ivy-dir-face
  '((((background dark)) :foreground "white")
    (((background light)) :foreground "black"))
  "Face for the dir icons used in ivy"
  :group 'icons-in-terminal-faces)

(defgroup icons-in-terminal-ivy nil
  "Shows icons while using ivy and counsel."
  :group 'ivy)

(defcustom icons-in-terminal-ivy-buffer-commands
  '(ivy-switch-buffer ivy-switch-buffer-other-window counsel-projectile-switch-to-buffer)
  "Commands to use with `icons-in-terminal-ivy-buffer-transformer'."
  :type '(repeat function)
  :group 'icons-in-terminal-ivy)

(defcustom icons-in-terminal-spacer
  "\t"
  "The string used as the space between the icon and the candidate."
  :type 'string
  :group 'icons-in-terminal-ivy)

(defcustom icons-in-terminal-ivy-family-fallback-for-buffer
  'icons-in-terminal-faicon
  "Icon font family used as a fallback when no icon for buffer transformer can be found."
  :type 'function
  :group 'icons-in-terminal-ivy)

(defcustom icons-in-terminal-ivy-name-fallback-for-buffer
  "sticky-note-o"
  "Icon font name used as a fallback when no icon for buffer transformer can be found."
  :type 'string
  :group 'icons-in-terminal-ivy)

(defcustom icons-in-terminal-ivy-file-commands
  '(counsel-find-file
    counsel-file-jump
    counsel-recentf
    counsel-projectile
    counsel-projectile-find-file
    counsel-projectile-find-dir
    counsel-git)
  "Commands to use with `icons-in-terminal-ivy-file-transformer'."
  :type '(repeat function)
  :group 'icons-in-terminal-ivy)

(defun icons-in-terminal-ivy--buffer-propertize (b s)
  "If buffer B is modified apply `ivy-modified-buffer' face on string S."
  (if (and (buffer-file-name b)
           (buffer-modified-p b))
      (propertize s 'face 'ivy-modified-buffer)
    s))

(defun icons-in-terminal-ivy--icon-for-mode (mode)
  "Apply `icons-in-terminal-for-mode' on MODE but either return an icon or nil."
  (let ((icon (icons-in-terminal-icon-for-mode mode)))
    (unless (symbolp icon)
      icon)))

(defun icons-in-terminal-ivy--buffer-transformer (b s)
  "Return a candidate string for buffer B named S preceded by an icon.
Try to find the icon for the buffer's B `major-mode'.
If that fails look for an icon for the mode that the `major-mode' is derived from."
  (let ((mode (buffer-local-value 'major-mode b)))
    (format (concat "%s" icons-in-terminal-spacer "%s")
            (propertize "\t" 'display (or
                                       (icons-in-terminal-ivy--icon-for-mode mode)
                                       (icons-in-terminal-ivy--icon-for-mode (get mode 'derived-mode-parent))
                                       (funcall
                                        icons-in-terminal-ivy-family-fallback-for-buffer
                                        icons-in-terminal-ivy-name-fallback-for-buffer)))
            (icons-in-terminal-ivy--buffer-propertize b s))))

(defun icons-in-terminal-ivy-icon-for-file (s)
  "Return icon for filename S.
Return the octicon for directory if S is a directory.
Otherwise fallback to calling `icons-in-terminal-icon-for-file'."
  (cond
   ((string-match-p "\\/$" s)
    (icons-in-terminal-octicon "file-directory" :face 'icons-in-terminal-ivy-dir-face))
   (t (icons-in-terminal-icon-for-file s))))

(defun icons-in-terminal-ivy-file-transformer (s)
  "Return a candidate string for filename S preceded by an icon."
  (format (concat "%s" icons-in-terminal-spacer "%s")
          (propertize "\t" 'display (icons-in-terminal-ivy-icon-for-file s))
          s))

(defun icons-in-terminal-ivy-buffer-transformer (s)
  "Return a candidate string for buffer named S.
Assume that sometimes the buffer named S might not exists.
That can happen if `ivy-switch-buffer' does not find the buffer and it
falls back to `ivy-recentf' and the same transformer is used."
  (let ((b (get-buffer s)))
    (if b
        (icons-in-terminal-ivy--buffer-transformer b s)
      (icons-in-terminal-ivy-file-transformer s))))

;;;###autoload
(defun icons-in-terminal-ivy-setup ()
  "Set ivy's display transformers to show relevant icons next to the candidates."
  (dolist (cmd icons-in-terminal-ivy-buffer-commands)
    (ivy-set-display-transformer cmd 'icons-in-terminal-ivy-buffer-transformer))
  (dolist (cmd icons-in-terminal-ivy-file-commands)
    (ivy-set-display-transformer cmd 'icons-in-terminal-ivy-file-transformer)))

(provide 'icons-in-terminal-ivy)

;;; icons-in-terminal-ivy.el ends here
