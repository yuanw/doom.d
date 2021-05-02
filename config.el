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
(setq doom-font (font-spec :family "Roboto Mono" :size 24))
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
(use-package! org-roam
  :init
  (map! :leader
        :prefix "n"
        :desc "org-roam" "l" #'org-roam-buffer-toggle
        :desc "org-roam-node-insert" "i" #'org-roam-node-insert
        :desc "org-roam-node-find" "f" #'org-roam-node-find
        :desc "org-roam-ref-find" "r" #'org-roam-ref-find
        :desc "org-roam-show-graph" "g" #'org-roam-show-graph
        :desc "org-roam-capture" "c" #'org-roam-capture
        :desc "org-roam-dailies-capture-today" "j" #'org-roam-dailies-capture-today)
  (setq org-roam-db-gc-threshold most-positive-fixnum
        org-id-link-to-org-use-id t
        org-directory "~/work/org/"
        org-roam-directory (concat org-directory "roam/")
        org-roam-encrypt-files t
      ;;deft-extensions '("org" "gpg")
      ;;deft-directory org-directory
      ;;org-agenda-file-regexp "\\`[^.].*\\.org.gpg\\'"
      org-agenda-files (append (file-expand-wildcards (concat org-directory "*.org.gpg"))
                               (file-expand-wildcards (concat org-directory "*.org"))
                               (file-expand-wildcards (concat org-directory "agenda/*.org"))
                               (file-expand-wildcards (concat org-directory "projects/*.org"))
                               (file-expand-wildcards (concat org-directory "projects/*.org.gpg"))
                               )
      org-default-notes-file (concat org-directory "agenda/inbox.org")
      +org-capture-todo-file (concat org-directory "agenda/inbox.org")
      org-refile-targets '((+org/opened-buffer-files :maxlevel . 9)))


  (add-to-list 'display-buffer-alist
               '(("\\*org-roam\\*"
                  (display-buffer-in-direction)
                  (direction . right)
                  (window-width . 0.33)
                  (window-height . fit-window-to-buffer))))
  :config
  (setq org-roam-mode-sections
        (list #'org-roam-backlinks-insert-section
              #'org-roam-reflinks-insert-section
              ;; #'org-roam-unlinked-references-insert-section
              ))
  (org-roam-setup)
  (setq org-roam-capture-templates
        '(("d" "default" plain
           "%?"
           :if-new (file+head "${slug}.org"
                              "#+title: ${title}\n")
           :immediate-finish t
           :unnarrowed t)))
  (setq org-roam-capture-ref-templates
        '(("r" "ref" plain
           "%?"
           :if-new (file+head "${slug}.org"
                              "#+title: ${title}\n")
           :unnarrowed t)))

  (setq org-roam-dailies-directory "daily/")
  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry
           "* %?"
           :if-new (file+head "daily/%<%Y-%m-%d>.org"
                              "#+title: %<%Y-%m-%d>\n"))))
  (set-company-backend! 'org-mode '(company-capf)))

(defun org-roam-v1-to-v2 ()
  ;; Create file level ID
  (org-with-point-at 1
    (org-id-get-create))
  ;; Replace roam_key into properties drawer roam_ref
  (when-let* ((refs (cdar (org-collect-keywords '("roam_key")))))
    (org-set-property "ROAM_REFS" (combine-and-quote-strings refs))
    (let ((case-fold-search t))
      (org-with-point-at 1
        (while (re-search-forward "^#\\+roam_key:" (point-max) t)
          (beginning-of-line)
          (kill-line)))))

  ;; Replace roam_alias into properties drawer roam_aliases
  (when-let* ((aliases (cdar (org-collect-keywords '("roam_alias")))))
    (org-set-property "ROAM_ALIASES" (combine-and-quote-strings aliases))
    (let ((case-fold-search t))
      (org-with-point-at 1
        (while (re-search-forward "^#\\+roam_alias:" (point-max) t)
          (beginning-of-line)
          (kill-line)))))
  (save-buffer))

;; Step 1: Convert all v1 files to v2 files
(dolist (f (org-roam--list-all-files))
  (with-current-buffer (find-file-noselect f)
    (org-roam-v1-to-v2)))

;; Step 2: Build cache
(org-roam-db-sync)

;; Step 3: Replace all file links with id links where possible
(defun org-roam-replace-file-links-with-id ()
  (org-with-point-at 1
    (while (re-search-forward org-link-bracket-re nil t)
      (let* ((mdata (match-data))
             (path (match-string 1))
             (desc (match-string 2)))
        (when (string-prefix-p "file:" path)
          (setq path (expand-file-name (substring path 5)))
          (when-let ((node-id (caar (org-roam-db-query [:select [id] :from nodes
                                                        :where (= file $s1)
                                                        :and (= level 0)] path))))
            (set-match-data mdata)
            (replace-match (org-link-make-string (concat "id:" node-id) desc))))))))

(dolist (f (org-roam--list-all-files))
  (with-current-buffer (find-file-noselect f)
    (org-roam-replace-file-links-with-id)))
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

(require 'org-id)
(require 'org-habit)
;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package' for configuring packagesss
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
