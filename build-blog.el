(require 'ox-publish)
(require 'htmlize)

(setq org-html-validation-link nil)
(setq org-html-head-include-scripts nil)
(setq org-html-head-include-default-style nil)
;; (setq org-html-preamble-format '(("en" "")))
(setq org-html-postamble-format '(("en" "")))
(setq org-html-indent t)

(setq org-publish-project-alist
      '(("content-org"
         :base-directory "~/Projects/jrasband-blog/content-org/"
         :base-extension "org"
         :publishing-directory "~/Projects/jrasband-blog/public/"
         :publishing-function org-html-publish-to-html
         :recursive t
         :section-numbers nil
         :with-toc nil
         :html-preamble t
         :html-postamble t
         :auto-sitemap t
         :sitemap-filename "index.org"
         :sitemap-title "Joshua Rasband's blog"
         :html-head "<link rel=\"stylesheet\" href=\"https://cdn.simplecss.org/simple.min.css\" />"
         ;; :html-head "<link rel=\"stylesheet\" href=\"css/stylesheet.css\" type=\"text/css\"/>"
         ;;:sitemap-function jem/sitemap-format ;; TODO fix
         :sitemap-sort-files alphabetically)
        
        ("blog-static"
         :base-directory "~/Projects/jrasband-blog/static/"
         :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf"
         :publishing-directory "~/Projects/jrasband-blog/public/"
         :recursive t
         :publishing-function org-publish-attachment)

        ("blog" :components ("content-org" "blog-static"))))

(org-publish "blog")

;; (denote-directory-files "_blogpost")
