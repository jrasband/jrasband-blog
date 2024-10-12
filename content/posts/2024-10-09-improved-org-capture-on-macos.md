+++
title = "Improved org-capture on MacOS"
author = ["Joshua Rasband"]
date = 2024-10-09
tags = ["emacs"]
draft = false
+++

I read [this post](https://macowners.club/posts/org-capture-from-everywhere-macos/) and it got me excited about using `emacsclient` to capture from
anywhere on MacOS. I was particular about getting the capture frame to show only
capture-related buffers, so I needed to make some modifications to the original
code based on comments on [this stackoverflow question](https://emacs.stackexchange.com/questions/46460/org-capture-frame-with-no-splits).

Here's my solution:

```text
(defun my/make-org-capture-frame ()
  "Create a new frame and run `org-capture'."
  (interactive)
  (make-frame '((name . "capture")
                (top . 300)
                (left . 700)
                (width . 80)
                (height . 25)))
  (select-frame-by-name "capture")
  (delete-other-windows)
  (cl-letf (((symbol-function 'switch-to-buffer-other-window) #'switch-to-buffer) ((symbol-function 'org-display-buffer-split) #'org-display-buffer-full-frame)) (org-capture)))

(defun my/org-capture-delete-frame (orig-fun &rest args)
  (if (equal "capture" (frame-parameter nil 'name))
      (delete-frame))
  (apply orig-fun args))

(advice-add 'user-error :around #'my/org-capture-delete-frame)
(advice-add 'org-capture-finalize :around #'my/org-capture-delete-frame)
```

Now you can call `emacsclient -nw --eval "(my/make-org-capture-frame)"` and it
will open a capture buffer in a new frame.
