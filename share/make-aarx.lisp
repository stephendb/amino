(load (make-pathname :directory (append (pathname-directory (truename *top-srcdir*))
                                        '("share"))
                     :name "load-ql"
                     :type "lisp"))


;; Try to register lisp directory with ASDF
(when (find-package :asdf)
  (eval `(push (make-pathname :directory (append (pathname-directory (truename *top-srcdir*))
                                                 '("lisp")))
               ,(intern "*CENTRAL-REGISTRY*" :asdf))))

;; Try to load Amino
(aa-load-system :amino)
(aa-load-system :amino-rx :amino)

;; Make core file
(sb-ext:save-lisp-and-die "aarx.core" :executable t)
