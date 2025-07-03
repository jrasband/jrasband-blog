;;; publish.el --- Generate my static webpage using org-publish  -*- lexical-binding: t; -*-

;; Copyright (C) 2025  Joshua Rasband

;; Author: Joshua Rasband <joshuarasband@Joshuas-Laptop.local>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Much of this code is taken from `https://git.sr.ht/~peregrinator/peregrinator.site'

;;; Code:

;;;; package installation
(require 'package)

;; Set the package installation directory so that packages aren't stored in the
;; ~/.emacs.d/elpa path.
(setq package-user-dir (expand-file-name "./.packages"))

;; Don't make backup files
(setq make-backup-files nil)

;; prevent built-in versions of org from loading
(assq-delete-all 'org package--builtins)
(assq-delete-all 'org package--builtin-versions)

(package-initialize)

(unless package-archive-contents
  (add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/") t)
  (add-to-list 'package-archives '("melpa"  . "https://melpa.org/packages/")     t)
  (package-refresh-contents))

(dolist (pkg '(org org-contrib htmlize ox-rss))
  (unless (package-installed-p pkg)
    (package-install pkg)))

;;;; requires
(require 'org)
(require 'org-id) ;; NOTE: not sure what this is used for
(require 'ox-publish)
(require 'htmlize)
(require 'ox-icalendar)
(require 'ox-rss)

;;;; variables
(defvar website-title "jrasband's blog"
  "The title of the website.")
(defvar website-base-url "https://jrasband.com/")

;; Author contact
(setq user-full-name "Joshua Rasband")
(setq user-mail-address "contact@jrasband.com")

;; Customize HTML output
(setq org-export-with-section-numbers nil)
(setq org-export-with-toc nil)
(setq org-html-metadata-timestamp-format "%d %b %Y")
(setq org-html-html5-fancy t)
(setq org-html-doctype "html5")
(setq org-html-htmlize-output-type 'css)
(setq org-html-validation-link nil)
(setq org-html-head-include-scripts nil)
(setq org-html-head-include-default-style nil)
(setq org-html-divs '((preamble "header" "top")
                      (content "main" "content")
                      (postamble "footer" "postamble")))
(setq org-html-container-element "section")

(defvar footer-date-format "%a %d.%m.%Y %H:%M")

(setq org-export-global-macros
      '(("timestamp" . "@@html:<time class=\"datetime\">$1</time>@@")))

;;;; functions

(defun format-date-entry (file project)
  "Format the date found in FILE of PROJECT."
  (format-time-string "%d %b %Y" (org-publish-find-date file project)))

(defun sitemap-with-date (entry style project)
  "Format for sitemap ENTRY, as a string.
ENTRY is a file name.  STYLE is the style of the sitemap.
PROJECT is the current project."
  (unless (equal entry "404.org")
    (format "{{{timestamp(%s)}}} [[file:%s][%s]]"
	    (format-date-entry entry project)
	    entry
	    (org-publish-find-title entry project))))

;; partials for header, footer, etc
(defun read-template (filename)
  "Read template contents from FILENAME."
  (with-temp-buffer
    (insert-file-contents filename)
    (buffer-string)))

(setq index-heading-template (read-template "content/partials/index-header.html"))
(setq posts-heading-template (read-template "content/partials/post-header.html"))
(setq pages-heading-template (read-template "content/partials/page-header.html"))
(setq posts-footer-template (read-template "content/partials/post-footer.html"))
(setq pages-footer-template (read-template "content/partials/page-footer.html"))
(setq head-template (read-template "content/partials/head.html"))

;; stuff for `html-head-extra'?
;; add meta tags dynamically
;; from https://gitlab.com/to1ne/blog/blob/master/elisp/publish.el#L60-126
(defun rw/org-html-close-tag (tag &rest attrs)
  "Return close-tag for string TAG.
ATTRS specify additional attributes."
  (concat "<" tag " "
          (mapconcat (lambda (attr)
                       (format "%s=\"%s\"" (car attr) (cadr attr)))
                     attrs
                     " ")
	  ">"))

(defun rw/html-head-extra (file project)
  "Return <meta> elements for nice unfurling on Twitter and Slack."
  (let* ((info (cdr project))
         (org-export-options-alist
          `((:title "TITLE" nil nil parse)
            (:date "DATE" nil nil parse)
            (:meta-type "META_TYPE" nil ,(plist-get info :meta-type) nil)))
         (title (org-publish-find-title file project))
         (date (org-publish-find-date file project))
         (author (org-publish-find-property file :author project))
         (description (org-publish-find-property file :description project))
	 (extension (or (plist-get info :html-extension) org-html-extension))
	 (rel-file (org-publish-file-relative-name file info))
	 (link-home (file-name-as-directory (plist-get info :html-link-home)))
         (type (org-publish-find-property file :meta-type project))
	 (full-url (concat link-home (file-name-sans-extension rel-file) "." extension)))
    (mapconcat 'identity
               `(,(rw/org-html-close-tag "link" '(rel canonical) `(href ,full-url))
		 ,(rw/org-html-close-tag "meta" '(property og:title) `(content ,title))
		 ,(and description
                       (rw/org-html-close-tag "meta" '(property og:description) `(content ,description)))
		 ,(rw/org-html-close-tag "meta" '(property og:type) `(content ,type))
		 ,(rw/org-html-close-tag "meta" '(property og:url) `(content ,full-url))
		 ,(and (equal type "article")
                       (rw/org-html-close-tag "meta" '(property article:published_time) `(content ,(format-time-string "%FT%T%z" date))))

		 ,(rw/org-html-close-tag "meta" '(property twitter:title) `(content ,title))
		 ,(rw/org-html-close-tag "meta" '(property twitter:url) `(content ,full-url))
		 ,(and description
                       (rw/org-html-close-tag "meta" '(property twitter:description) `(content ,description)))
		 ,(and description
                       (rw/org-html-close-tag "meta" '(property twitter:card) '(content summary)))

		 )
	       "\n")))

(defun rw/org-html-publish-to-html (plist filename pub-dir)
  "Wrapper function to publish an file to html.

PLIST contains the properties, FILENAME the source file and
  PUB-DIR the output directory."
  (let ((project (cons 'rw plist)))
    (plist-put plist :html-head-extra
               (rw/html-head-extra filename project))
    (org-html-publish-to-html plist filename pub-dir)))


;; RSS feed
;; see: https://nicolasknoebber.com/posts/blogging-with-emacs-and-org.html#org9edef43
;; from : https://github.com/knoebber/nicolasknoebber.com/blob/6b05e9163e02d6d62034425c87056f3f97b2d4f2/src/site.el#L84C1-L117C1
(setq org-rss-image-url (concat website-base-url "public/favicon-32x32.png"))

(defun publish-posts-rss-feed (plist filename dir)
  "Publish PLIST to RSS when FILENAME is rss.org.
DIR is the location of the output."
  (if (equal "feed.org" (file-name-nondirectory filename))
      (org-rss-publish-to-rss plist filename dir)))

(defun generate-posts-rss-sitemap (title list)
  "Generate a sitemap of posts that is exported as a RSS feed.
TITLE is the title of the RSS feed.  LIST is an internal
representation for the files to include.  PROJECT is the current
project."
  (concat
   "#+TITLE: " title "\n\n"
   (org-list-to-subtree list)))


(defun format-posts-rss-feed-entry (entry _style project)
  "Format ENTRY for the posts RSS feed in PROJECT."
  (let* (
	 (file (org-publish--expand-file-name entry project))
	 (title (org-publish-find-title entry project))
	 (link (concat (file-name-sans-extension entry) ".html"))
	 (pubdate (format-time-string (car org-time-stamp-formats)
				      (org-publish-find-date entry project))))
    (format "\n%s
:properties:
:rss_permalink: %s
:pubdate: %s
:end:
#+INCLUDE: %s :lines \"3-\" \n"
	    title
	    link
	    pubdate
	    file
	    )))

;;;; define publishing project
(setq org-publish-project-alist
      (list
       (list "css"
             :base-directory "./content/css"
             :base-extension "css"
             :publishing-directory "./public"
             :publishing-function 'org-publish-attachment)
       (list "static"
             :recursive t
	         :base-extension "txt\\|png\\|jpg\\|jpeg\\|gif\\|pdf\\|woff\\|woff2"
	         :base-directory "./content/static"
	         :publishing-directory "./public"
	         :publishing-function 'org-publish-attachment)
       (list "pages"
             :recursive nil
             :base-directory "./content/pages"
             :publishing-function 'rw/org-html-publish-to-html
             :publishing-directory "./public"
             :with-toc nil
             :with-title nil
             :html-head head-template
             :html-link-home website-base-url
             :meta-type "page"
             :html-preamble pages-heading-template
	         :html-postamble pages-footer-template)
       (list "blog posts"
	         :recursive t
	         :base-extension "org"
	         :base-directory "./content/blog"
	         :publishing-directory "./public/blog"
	         :publishing-function 'rw/org-html-publish-to-html
	         :exclude "feed.org"
	         :with-title nil
	         :with-author nil
	         :with-creator nil
	         :with-toc nil
	         :section-numbers nil
	         :time-stamp-file nil
	         :auto-sitemap t
	         :sitemap-title "Posts archive"
	         :sitemap-filename "blog-archive.org"
	         :sitemap-sort-files 'anti-chronologically
	         :sitemap-date-format "%d.%m.%Y"
	         :sitemap-format-entry 'sitemap-with-date
	         ;; heading anchors
	         ;; :html-format-headline-function 'my-org-html-format-headline-function
	         :html-head head-template
	         :html-link-home website-base-url
	         :meta-type "article"
	         :html-preamble posts-heading-template
	         :html-postamble posts-footer-template
	         :htmlized-source t)
       (list "blog-rss"
             :base-directory "./content/blog"
             :publishing-directory "./public/blog/"
	         :base-extension "org"
             :exclude "blog-archive.org"
             :publishing-function 'publish-posts-rss-feed
	         :rss-extension "xml"
             :html-link-home website-base-url
             :html-link-use-abs-url t
	         :html-link-org-files-as-html t
	         :auto-sitemap t
	         :sitemap-title website-title
	         :sitemap-filename "feed.org"
	         :sitemap-sort-files 'anti-chronologically
	         ;; :sitemap-style 'list
	         :sitemap-function 'generate-posts-rss-sitemap
	         :sitemap-format-entry 'format-posts-rss-feed-entry
	         :author "Joshua Rasband"
	         :email "contact@jrasband.com")
       (list "home"
             :recursive nil
             :base-directory "./content"
	         :publishing-function 'org-html-publish-to-html
	         :publishing-directory "./public"
	         ;; :exclude "emacs.org"
	         :with-toc nil
	         :with-title: nil
	         :html-head head-template
	         :meta-type "website"
	         :html-head-extra "<link rel=\"canonical\" href=\"https://peregrinator.site/\">
<meta property=\"og:url\" content=\"https://jrasband.com\">
<meta property=\"og:type\" content=\"website\">
<meta property=\"og:title\" content=\"jrasband's website\">"
	         :html-preamble index-heading-template
	         :html-postamble pages-footer-template)))

;; Generate site output
(org-publish-all t)

(message "Build complete!")

;;; Provide:
(provide 'publish)
;;; publish.el ends here
