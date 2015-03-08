;;; mana.el --- Start ManaPlus without writing credentials

;; Copyright © 2014 Alex Kost

;; Author: Alex Kost <alezost@gmail.com>
;; Created: 12 Nov 2014
;; Version: 0.1
;; URL: https://github.com/alezost/mana.el
;; Keywords: games

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

;; ManaPlus is a 2D MMORPG client, see <http://manaplus.org/>.

;; This package provides a command for starting ManaPlus using Emacs
;; facility to get credentials from authinfo file.  So you can keep your
;; user and password for "The Mana World" game in "~/.authinfo.gpg" and
;; do not bother about writing those every time you start manaplus.

;; To install this package manually, add the following to your emacs
;; init file:
;;
;;   (add-to-list 'load-path "/path/to/dir-with-mana-package")
;;   (autoload 'mana-start "mana" nil t)

;; Then add a line like the following to an authinfo file you use (one of
;; the files from `auth-sources' variable):
;;
;;   machine server.themanaworld.org login <your-user> password <your-password>

;; Once it is done, "M-x mana-start" and enjoy :-)

;; TODO:
;;
;; This package can be easily modified to use different servers and to
;; ask a user which one he wants to connect.  And it should support
;; other analogous games (like Evol Online <http://evolonline.org/>) but
;; as I play only "The Mana World" and I'm the only user of this
;; package, currently it is limited to the main server of TMW.  But if
;; you somehow found this package and you want it to support other
;; servers, contact me and I will gladly add such support.

;;; Code:

(require 'cl-lib)
(require 'auth-source)

(defgroup mana nil
  "Interface for starting manaplus client using authinfo file.
See info node `(auth) Help for users' to learn how to use
authentication files from `auth-sources' variable."
  :link '(url-link "http://manaplus.org/")
  :link '(info-link "(auth) Help for users")
  :group 'games)

(defcustom mana-server "server.themanaworld.org"
  "Default server to connect."
  :type 'string
  :group 'mana)

(defcustom mana-program "manaplus"
  "Filename of the client program."
  :type 'string
  :group 'mana)

(defcustom mana-character nil
  "Name of the character to be automatically chosen after a game start."
  :type '(choice (const :tag "No default character")
                 (string :tag "Name"))
  :group 'mana)

(defvar mana-process-name "mana"
  "Name of a process used by `start-process'.")

(defvar mana-buffer-name "*mana-output*"
  "Name of a buffer used by `start-process'.")

(cl-defstruct
    (mana-credentials
     (:constructor nil)                 ; no default constructor
     (:constructor mana-make-credentials (user password))
     (:copier nil))
  user password)

(defun mana-credentials ()
  "Return credentials from authinfo file."
  (let ((auth (car (auth-source-search :host mana-server)))
        user password)
    (when auth
      (let ((secret (plist-get auth :secret)))
        (setq user (plist-get auth :user)
              password (if (functionp secret)
                           (funcall secret)
                         secret))))
    (or user
        (setq user (read-string "User name: ")))
    (or password
        (setq password (read-passwd "Password: ")))
    (mana-make-credentials user password)))

(defun mana-argument (key val)
  "Return a 'long-option' shell argument by KEY and VAL."
  (and val
       (concat "--" key "=" (shell-quote-argument val))))

(defun mana-arguments ()
  "Return list of arguments for a client program."
  (let* ((credentials (mana-credentials))
         (user        (mana-credentials-user     credentials))
         (password    (mana-credentials-password credentials)))
    (delq nil
          (list (mana-argument "server"    mana-server)
                (mana-argument "username"  user)
                (mana-argument "password"  password)
                (mana-argument "character" mana-character)))))

;;;###autoload
(defun mana-start ()
  "Start manaplus client."
  (interactive)
  (apply #'start-process
         mana-process-name mana-buffer-name
         mana-program (mana-arguments)))

(provide 'mana)

;;; mana.el ends here
