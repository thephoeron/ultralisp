(defpackage #:ultralisp/models/source
  (:use #:cl)
  (:import-from #:jonathan)
  (:import-from #:ultralisp/protocols/external-url
                #:external-url)
  (:import-from #:ultralisp/models/versioned
                #:deleted-p
                #:latest-p
                #:object-version)
  (:import-from #:ultralisp/models/dist-source)
  (:import-from #:ultralisp/models/utils
                #:systems-info-to-json
                #:release-info-to-json
                #:systems-info-from-json
                #:release-info-from-json)
  (:import-from #:alexandria
                #:make-keyword)
  (:import-from #:mito
                #:object-id)
  (:export
   #:source-systems-info
   #:source-release-info
   #:source
   #:source-project-id
   #:project-version
   #:source-type
   #:source-params
   #:deleted-p
   #:source-distributions
   #:dist-source->source))
(in-package ultralisp/models/source)


(defclass source ()
  ((project-id :col-type :bigint
               :initarg :project-id
               :reader source-project-id)
   (project-version :col-type :bigint
                    :initarg :project-version
                    :reader project-version)
   (version :col-type :bigint
            :initarg :version
            :reader object-version
            :initform 0)
   (latest :col-type :boolean
           :initarg :latest
           :initform t
           :reader latest-p)
   (deleted :col-type :boolean
            :initarg :deleted
            :initform nil
            :reader deleted-p)
   (type :col-type (:text)
         :initarg :type
         :reader source-type
         :inflate (lambda (text)
                    (make-keyword (string-upcase text)))
         :deflate #'symbol-name)
   (params :col-type (:jsonb)
           :initarg :params
           :reader source-params
           :deflate #'jonathan:to-json
           :inflate (lambda (text)
                      (jonathan:parse
                       ;; Jonathan for some reason is unable to work with
                       ;; `base-string' type, returned by database
                       (coerce text 'simple-base-string))))
   (systems-info :col-type (or :jsonb :null)
                 :documentation "Contains a list of lists describing systems same way as quickdist returns."
                 :initform nil
                 :reader source-systems-info
                 :deflate #'systems-info-to-json
                 :inflate #'systems-info-from-json)
   (release-info :col-type (or :jsonb :null)
                 :documentation ""
                 :initform nil
                 :reader source-release-info
                 :deflate #'release-info-to-json
                 :inflate #'release-info-from-json))
  
  (:primary-key project-id project-version version)
  (:metaclass mito:dao-table-class))


(defun params-to-string (source)
  (let ((type (source-type source)))
    (if (eql type :github)
        (let ((params (source-params source)))
          (format nil "~A://~A/~A@~A"
                  (string-downcase type)
                  (getf params :user-or-org)
                  (getf params :project)
                  (getf params :last-seen-commit)))
        (format nil "~A://unsupported-source-type"
                (string-downcase type)))))


(defmethod print-object ((obj source) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream
            "~A (v~A)~A~A"
            (params-to-string obj)
            (object-version obj)
            (if (deleted-p obj)
                " deleted"
                "")
            (if (source-release-info obj)
                " has-release-info"
                ""))))


(defun %project-sources (project-id project-version)
  (mito:retrieve-dao 'source
                     :project-id project-id
                     :project-version project-version
                     :latest "true"))


(defmethod external-url ((obj source))
  (let ((type (source-type obj)))
    (when (eql type :github)
        (let ((params (source-params obj)))
          (format nil "https://github.com/~A/~A"
                  (getf params :user-or-org)
                  (getf params :project))))))


(defun source-distributions (source)
  (check-type source source)
  (ultralisp/models/dist-source::%project-dist-source
   (source-project-id source)
   (project-version source)
   (object-version source)))


(defun dist-source->source (dist-source)
  (check-type dist-source
              ultralisp/models/dist-source:dist-source)
  (first
   (mito:retrieve-dao
    'source
    :project-id (ultralisp/models/dist-source:project-id dist-source)
    :project-version (ultralisp/models/dist-source:project-version dist-source)
    :version (ultralisp/models/dist-source:source-version dist-source))))