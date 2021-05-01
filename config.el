;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Yuan Wang"
      user-mail-address "me@yuanwang.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font (font-spec :family "PragmataPro" :size 18))
;;(setq doom-font (font-spec :family "Iosevka Term Medium" :size 24))
;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; doom-palenight is also nice
(setq doom-theme 'doom-palenight)
;(setq doom-theme 'doom-vibrant)
(after! doom-themes
  (setq
   doom-themes-enable-bold t
   doom-themes-enable-italic t))

(defun +org/opened-buffer-files ()
  "Return the list of files currently opened in Emacs."
  (delq nil
        (mapcar (lambda (x)
                  (if (and (buffer-file-name x)
                           (string-match "\\.org.gpg$"
                                         (buffer-file-name x)))
                      (buffer-file-name x)))
                (buffer-list))))

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/work/org/"
      org-roam-directory (concat org-directory "roam/")
      org-roam-encrypt-files t
      deft-extensions '("org" "gpg")
      deft-directory org-directory
      org-agenda-file-regexp "\\`[^.].*\\.org.gpg\\'"
      org-agenda-files (append (file-expand-wildcards (concat org-directory "*.org.gpg"))
                               (file-expand-wildcards (concat org-directory "*.org"))
                               (file-expand-wildcards (concat org-directory "agenda/*.org"))
                               (file-expand-wildcards (concat org-directory "projects/*.org"))
                               (file-expand-wildcards (concat org-directory "projects/*.org.gpg"))
                               )
      org-default-notes-file (concat org-directory "agenda/inbox.org")
      +org-capture-notes-file (concat org-directory "agenda/inbox.org")
      +org-capture-todo-file (concat org-directory "agenda/inbox.org")
      org-refile-targets '((+org/opened-buffer-files :maxlevel . 9)))


;;; :tools direnv
;;(setq direnv-always-show-summary nil)
;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type nil)

(after! org
  (setq org-agenda-dim-blocked-tasks nil)
  (setq org-agenda-inhibit-startup t)
  (setq org-agenda-use-tag-inheritance nil)
  (setq org-modules
   (quote
    (org-habit org-bibtex ))))

(require 'org-habit)
;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c g k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c g d') to jump to their definition and see how
;; they are implemented.
;; (use-package lsp-haskell
;;  :ensure t
;;  :config
;;  (setq lsp-haskell-process-path-hie "haskell-language-server-wrapper")
;;  ;; Comment/uncomment this line to see interactions between lsp client/server.
;;  ;;(setq lsp-log-io t)
;;)
