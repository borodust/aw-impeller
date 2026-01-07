(cl:defpackage :impeller.example
  (:use :cl)
  (:export #:run))
(cl:in-package :impeller.example)

;;;
;; Inspired by Impeller's VK example:
;;   https://github.com/flutter/flutter/blob/41a1df2a1b026185a05dbc7bc287387cc060cee4/engine/src/flutter/impeller/toolkit/interop/example_vk.c
;;;

(cffi:define-foreign-library
    (impeller
     :search-path (asdf:system-relative-pathname :aw-impeller "src/lib/"))
  (:unix "libimpeller.so"))


(cffi:define-foreign-library
    (sdl3-clawed
     :search-path (asdf:system-relative-pathname :aw-impeller "src/lib/"))
  (:unix "libsdl3.clawed.so"))


(defun impeller-swap (swap-chain display-list)
  (let ((surface
          (%impeller:vulkan-swapchain-acquire-next-surface-new swap-chain)))
    (when (cffi:null-pointer-p surface)
      (error "Failed to create Impeller surface"))
    (unwind-protect
         (progn
           (%impeller:surface-draw-display-list surface display-list)
           (%impeller:surface-present surface))
      (%impeller:surface-release surface))))


(defun impeller-draw (swap-chain)
  (cffi-c-ref:c-with ((clear-color (:struct %impeller:color))
                      (box-color (:struct %impeller:color))
                      (box-rect (:struct %impeller:rect)))
    (setf (clear-color :red) 1f0
          (clear-color :green) 1f0
          (clear-color :blue) 1f0
          (clear-color :alpha) 1f0

          (box-color :red) 1f0
          (box-color :green) 0f0
          (box-color :blue) 0f0
          (box-color :alpha) 1f0

          (box-rect :x) 10f0
          (box-rect :y) 10f0
          (box-rect :width) 100f0
          (box-rect :height) 100f0)
    (let* ((dl-builder (%impeller:display-list-builder-new (cffi:null-pointer)))
           (paint (%impeller:paint-new)))
      (unwind-protect
           (progn
             (%impeller:paint-set-color paint (clear-color &))
             (%impeller:display-list-builder-draw-paint dl-builder paint)

             (%impeller:paint-set-color paint (box-color &))
             (%impeller:display-list-builder-draw-rect dl-builder (box-rect &) paint)

             (let ((dl (%impeller:display-list-builder-create-display-list-new dl-builder)))
               (when (cffi:null-pointer-p dl)
                 (error "Failed to create Impeller display list"))
               (unwind-protect
                    (impeller-swap swap-chain dl)
                 (%impeller:display-list-release dl))))
        (%impeller:paint-release paint)
        (%impeller:display-list-builder-release dl-builder)))))


(defun impeller-run (window)
  (cffi-c-ref:c-with ((fb-size (:struct %impeller:i-size))
                      (vk-opts (:struct %impeller:context-vulkan-settings))
                      (vk-info (:struct %impeller:context-vulkan-info))
                      (vk-surface %sdl3:vk-surface-khr))
    (setf (fb-size :width) 640
          (fb-size :height) 480

          (vk-opts :proc-address-callback) (%sdl3:vulkan-get-vk-get-instance-proc-addr)
          (vk-opts :enable-vulkan-validation) t)

    (let ((ctx (%impeller:context-create-vulkan-new %impeller:+version+
                                                    (vk-opts &))))
      (when (cffi:null-pointer-p ctx)
        (error "Failed to create impeller context"))
      (unwind-protect
           (progn
             (unless (%impeller:context-get-vulkan-info ctx (vk-info &))
               (error "Failed to get Vulkan info"))
             (unless (%sdl3:vulkan-create-surface window
                                                  (vk-info :vk-instance)
                                                  (cffi:null-pointer)
                                                  (vk-surface &))
               (error "Failed to create Vulkan surface"))
             (unwind-protect
                  (let ((swap-chain
                          (%impeller:vulkan-swapchain-create-new ctx
                                                                 vk-surface)))
                    (when (cffi:null-pointer-p swap-chain)
                      (error "Failed to init Vulkan swap chain"))
                    (unwind-protect
                         (impeller-draw swap-chain)
                      (%impeller:vulkan-swapchain-release swap-chain)))
               (%sdl3:vulkan-destroy-surface (vk-info :vk-instance)
                                             vk-surface
                                             (cffi:null-pointer))))
        (%impeller:context-release ctx)))))


(defun main-run ()
  (%sdl3:init %sdl3:+init-video+)
  (let ((window (cffi:with-foreign-string (name "AW-IMPELLER/AW-SDL3 Example")
                  (%sdl3:create-window name
                                      640 480
                                      %sdl3:+window-vulkan+))))
    (when (cffi:null-pointer-p window)
      (error "Failed to create a window"))
    (unwind-protect
         (progn
           (%sdl3:vulkan-load-library (cffi:null-pointer))
           (impeller-run window)
           (sleep 5)
           (%sdl3:destroy-window window))
      (%sdl3:vulkan-unload-library)
      (%sdl3:quit))))


(defun run ()
  (unwind-protect
       (let ((errout *error-output*))
         (cffi:load-foreign-library 'impeller)
         (cffi:load-foreign-library 'sdl3-clawed)
         (flet ((%runner ()
                  (handler-case
                      (main-run)
                    (serious-condition (c) (format errout "~A" c)))))
           (trivial-main-thread:call-in-main-thread #'%runner :blocking t)))
    (cffi:close-foreign-library 'impeller)
    (cffi:close-foreign-library 'sdl3-clawed)))
