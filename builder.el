;;;; Config Variables

(defvar raxjs/description-index-page "
f00 bar

lallala

lsl
"
  "The text that is shown on the index.html page under the Description section")

(defvar raxjs/generate-out-dir ".generate"
  "Temp directory that is used for then index.org and $tag.org files")

(defvar raxjs/input-dir "./test-dir/"
  "The directory where your org files life")

(defvar raxjs/out-dir "./build/"
  "The directory where your generated html files life")

;;;; Install Dependencies

(require 'package)
(setq package-enable-at-startup nil)
(setq use-package-verbose nil)
(setq package-user-dir (expand-file-name "./.emacs-packages"))
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/")
	     '("org" . "https://orgmode.org/elpa/"))
(package-initialize)


(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))


(use-package htmlize
  :ensure t)
(load-file "ox-slimhtml.el")

(use-package org-roam
  :ensure t
  :init
    (setq org-roam-v2-ack t)
  :config
    (setq org-roam-directory (expand-file-name raxjs/input-dir)
	org-roam-db-location "./roam.db")
    (org-roam-db-sync))



;;;;;; Org Publish Settings

(require 'ox-publish)

(setq 
      org-publish-use-timestamps-flag t
      org-publish-timestamp-directory "./.org-cache/"
      org-html-metadata-timestamp-format "%Y-%m-%d"
      org-html-html5-fancy nil
      org-html-head-include-default-style nil
      org-html-head-include-scripts nil
      org-html-htmlize-output-type 'css
      htmlize-output-type 'css
      org-html-self-link-headlines t
      org-html-validation-link nil
      org-html-doctype "html5"
      org-html-head-extra (concat "<link rel='stylesheet' href='/css/master.css' />\n")
      
      )

(setq org-publish-project-alist
      `(
	("org" :components ("vcdb" "static" "generate"))


       ("vcdb"
        :base-directory ,(expand-file-name raxjs/input-dir)
        :base-extension "org"
        :publishing-directory ,(format "%svcdb/" (expand-file-name raxjs/out-dir))
        :recursive t
        :publishing-function ox-slimhtml-publish-to-html 
        :headline-levels 4 
        :auto-preamble t
        :section-numbers nil
        :with-toc nil
        :with-author nil
        :with-creator nil
        :html-link-home "/"
        :html-head-include-default-style nil
        :html-head-include-scripts nil
        )

       ("generate"
        :base-directory ,(expand-file-name raxjs/generate-out-dir)
        :base-extension "org"
        :publishing-directory ,(expand-file-name raxjs/out-dir)
        :recursive t
        :publishing-function ox-slimhtml-publish-to-html 
        :headline-levels 4 
        :auto-preamble t
        :section-numbers nil
        :with-toc nil
        :with-author nil
        :with-creator nil
        :html-link-home "/"
        :html-head-include-default-style nil
        :html-head-include-scripts nil
        )


      ("static"
	:base-directory "static/"
	:base-extension "css\\|js\\|png\\|jpg\\|gif"
	:publishing-directory ,(expand-file-name raxjs/out-dir)
	:recursive t
	:publishing-function org-publish-attachment
    
      )))




;;;; Generation of index and tag files via org-roam-node-* infos


(defun raxjs/tag-list-filter (tag-list)
    (seq-filter
	(lambda (el)
	  (when (not (or (string= el "vcdb")
			 ))
	    el
	   ))
	tag-list))

(defun raxjs/roam-tag-list ()
    (interactive)
    (raxjs/tag-list-filter
	(seq-uniq
	    (flatten-list
		(mapcar 'org-roam-node-tags (org-roam-node-list))))))

(defun raxjs/roam-tag-node-dict ()
    (let ((tag-dict (make-hash-table :test 'equal)))
	(dolist (node (org-roam-node-list))
	    (dolist (tag (org-roam-node-tags node))
		(puthash tag
		    (cons
			node
			(gethash tag tag-dict '()))
		    tag-dict)))
    tag-dict))


(defun raxjs/tag-link (tag)
    (format "- [[file:tag_%s.html][%s]]\n" tag tag))

(defun raxjs/generate-index-file ()
    (save-current-buffer
	(set-buffer (find-file-noselect
	     "*vcdb-tmp-buffer*"))
	(save-excursion
	    (delete-region (point-min) (point-max))
	    (goto-char (point-min))

	    ;; write stuff to tmp buffer
	    (insert (format "* Description\n %s" raxjs/description-index-page))
	    (insert "\n* Challenges\n")
	    (dolist (node (org-roam-node-list))
	      (insert (format "- [[file:vcdb/%s.html][%s]] \n\t%s\n"
			      (file-name-base (org-roam-node-file node))
			      (org-roam-node-title node)
			      (string-join (mapcar
					    'raxjs/tag-link
					    (raxjs/tag-list-filter
					       (org-roam-node-tags node))) "\n\t")
			      ))
	      )
	    (insert "\n* Tags\n")
	    (let ((tag-list (raxjs/roam-tag-list)))
		(dolist (tag tag-list)
		    (insert (raxjs/tag-link tag))
		    ))
	    (write-file (concat (expand-file-name raxjs/generate-out-dir) "/index.org"))
	    (kill-buffer)
	    )))



(defun raxjs/generate-tag-files ()
    (let ((tag-dict (raxjs/roam-tag-node-dict)))
        (dolist (tag (raxjs/roam-tag-list))
	    (save-current-buffer
		(set-buffer (find-file-noselect
		    "*vcdb-tmp-buffer*"))
	    (save-excursion
	    (delete-region (point-min) (point-max))
	    (goto-char (point-min))
	    (insert (format "* %s\n" tag))
	    ;; write stuff to tmp buffer
	    (insert "** Challenges\n")

	  ;; iter over all nodes that have a given tag 
	  ;; and write a link to that node (challenge file)
	  (dolist (node (gethash tag tag-dict))
	    (insert (format "- [[file:vcdb/%s.html][%s]]\n"
			    (file-name-base (org-roam-node-file node))
			    (org-roam-node-title node))))

        ;; write $tag.org
	(write-file (concat (expand-file-name raxjs/generate-out-dir) (format "/tag_%s.org" tag))))
	(kill-buffer)) ;; end of save-current-buffer

)))

(defun raxjs/generate-org-files ()
    (interactive)

    ;; make sure the output folder exists
    (make-directory raxjs/generate-out-dir t)

    (raxjs/generate-index-file)
    (raxjs/generate-tag-files))

(defun raxjs/build ()
  (interactive)
    (raxjs/generate-org-files)
    (org-publish-project "org"))
