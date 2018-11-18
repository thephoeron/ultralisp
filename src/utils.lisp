(defpackage #:ultralisp/utils
  (:use #:cl)
  (:import-from #:cl-fad)
  (:import-from #:uiop
                #:ensure-absolute-pathname
                #:ensure-directory-pathname
                #:ensure-pathname)
  (:export
   #:getenv
   #:directory-mtime
   #:ensure-absolute-dirname
   #:ensure-existing-file))
(in-package ultralisp/utils)


(defun getenv (name &optional (default nil))
  "Возвращает значение из переменной окружения или дефолт, если переменная не задана"
  (let ((value (uiop:getenv name)))
    (if value
        (cond 
          ((or (integerp default)
               (floatp default))
           (read-from-string value))
          ((stringp default)
           value)
          (t value))
        default)))


(defun ensure-existing-file (path)
  (ensure-pathname path
                   :want-file t
                   :want-existing t))


(defun ensure-absolute-dirname (path)
  (ensure-directory-pathname
   (ensure-absolute-pathname
    path
    (probe-file "."))))


(defun directory-mtime (path)
  (if (not (fad:directory-pathname-p path))
      (file-write-date path)
      (apply #'max 0 (mapcar #'directory-mtime (fad:list-directory path)))))

