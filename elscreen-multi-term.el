;;; elscreen-multi-term.el --- Multi term for elscreen

;; Author: wamei <wamei.cho@gmail.com>
;; Keywords: elscreen, multi term
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.4") (elscreen "1.4.6") (multi-term "1.3"))

;; License:

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

;; This makes elscreen can manage multi term buffer each screen.
;;
;; To use this, add the following line somewhere in your init file:
;; ;; When you use this with elscreen-separate-buffer-list, you need to
;; ;; add this before (require 'elscreen-separate-buffer-list)
;;
;;      (require 'elscreen-multi-term)
;;
;; Function: emt-multi-term
;;   Create multi-term buffer related to screen.
;;   When the multi-term  buffer already exists, switch to the buffer.
;;
;; Function: emt-toggle-multi-term
;;   Toggle between current buffer and the multi-term buffer.

;;; Code:

(eval-when-compile (require 'cl))
(require 'elscreen)
(require 'multi-term)

(defvar emt-term-buffer-name "*screen terminal<%d>*")

(defun emt-multi-term (&optional number)
  "NUMBERに対応するTERMを立ち上げる."
  (interactive)
  (let* ((number (or number (elscreen-get-current-screen)))
         (buffer (get-buffer (format emt-term-buffer-name number))))
    (cond (buffer
           (switch-to-buffer buffer))
          (t
           (setq buffer (multi-term))
           (with-current-buffer buffer
             (rename-buffer (format emt-term-buffer-name number)))
           (switch-to-buffer buffer)))))

(defun emt-toggle-multi-term ()
  "直前のBUFFERとTERMを切り替える."
  (interactive)
  (let* ((screen-number (elscreen-get-current-screen))
         (buffer (get-buffer (format emt-term-buffer-name screen-number))))
    (cond ((equal buffer (current-buffer))
           (switch-to-prev-buffer))
          (buffer
           (switch-to-buffer buffer))
          (t
           (emt-multi-term screen-number)))))

(defun emt-screen-kill:around (origin &rest args)
  "SCREENの削除時に対応するTERMを削除する."
  (let* ((screen (or (and (integerp (car args)) (car args))
                     (elscreen-get-current-screen)))
         (origin-return (apply origin args))
         (buffer (get-buffer (format emt-term-buffer-name screen))))
    (when origin-return
      (cond (buffer
             (delete-process buffer)
             (kill-buffer buffer))))
    origin-return))

(defun emt-screen-swap:around (origin &rest args)
  "SCREENのSWAP時に対応するTERMを入れ替える."
  (let ((origin-return (apply origin args)))
    (when origin-return
      (let* ((current-screen (elscreen-get-current-screen))
             (previous-screen (elscreen-get-previous-screen))
             (current-buffer (get-buffer (format emt-term-buffer-name current-screen)))
             (previous-buffer (get-buffer (format emt-term-buffer-name previous-screen))))
        (if current-buffer
          (with-current-buffer current-buffer
            (rename-buffer (format (concat emt-term-buffer-name "-tmp") previous-screen))
            (when previous-buffer
              (with-current-buffer previous-buffer
                (rename-buffer (format emt-term-buffer-name current-screen))))
            (rename-buffer (format emt-term-buffer-name previous-screen)))
          (when previous-buffer
            (with-current-buffer previous-buffer
              (rename-buffer (format emt-term-buffer-name current-screen)))))))
    origin-return))

(advice-add 'elscreen-kill :around 'emt-screen-kill:around)
(advice-add 'elscreen-swap :around 'emt-screen-swap:around)

(provide 'elscreen-multi-term)

;;; elscreen-multi-term.el ends here
