(uiop:define-package #:40ants-builder/image
  (:use #:cl)
  (:export #:install-build-debugger-hook
           #:ensure-package-nickname
           #:prepare-image
           #:dump-binary))
(in-package #:40ants-builder/image)


(defun install-build-debugger-hook ()
  "Install a debugger hook which fails the build process immediately.

Any error during the build must exit the process with a non-zero
code, instead of leaving it hanging in the interactive debugger of
Roswell/CCL."
  (setf *debugger-hook*
        (lambda (condition hook)
          (declare (ignore hook))
          (format *error-output* "~&BUILD FAILED: ~A~%~%" condition)
          (uiop:print-condition-backtrace condition)
          (uiop:quit 1))))


(defun ensure-package-nickname (package-name nickname)
  "Add NICKNAME to the package named PACKAGE-NAME.

Does nothing when the package does not exist or when a package named
NICKNAME is already present, because in these cases rename-package
either has nothing to do or signals a correctable error. Returns T
when the package was renamed."
  (let ((package (find-package package-name)))
    (when (and package
               (not (find-package nickname)))
      (rename-package package
                      package-name
                      (append (package-nicknames package)
                              (list nickname)))
      t)))


(defun prepare-image ()
  "Prepare the build image for the dump.

Gives the Clack Hunchentoot handler package its slash nickname:
Clack looks handlers up by a name with slashes, does not find it in
the current dist and calls ql:quickload at run time, which fails
under ProtectHome. The nickname removes the runtime load.

Then pushes the :deploy-console feature to silence Deploy's status
output at service startup (\"Performing warm boot\", \"Loading foreign
library ...\" etc.): with this feature the warm boot sets
*status-output* to NIL, the same way deploy-console-op does for
console applications. Build identification stays available through
the project's version flag.

Finally, removes the build-only debugger hook, so it does not get
dumped into the image: otherwise any runtime error would kill the
service with a build failure message instead of the project's own
error handling."
  (ensure-package-nickname "CLACK.HANDLER.HUNCHENTOOT"
                           "CLACK/HANDLER/HUNCHENTOOT")
  (pushnew :deploy-console *features*)
  (setf *debugger-hook* nil))


(defun dump-binary (system)
  "Dump the standalone binary of SYSTEM.

On SBCL and CCL this is asdf:make, which performs the system's
:build-operation (deploy-op for Pingvito). ECL does not support
uiop:dump-image, and deploy-op relies on it, so under ECL the standard
asdf:program-op is used instead: the system is compiled to C and the
object files are linked into an executable with c:build-program,
using the :entry-point and :build-pathname from the system's
definition file."
  #+ecl
  (asdf:operate 'asdf:program-op system)
  #-ecl
  (asdf:make system))
