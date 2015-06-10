(in-package :robray)

(defvar *urdf-package-alist* nil)
(defparameter *ros-distribution* "indigo")

(defparameter *baxter-description*
  (format nil "/opt/ros/~A/share/baxter_description/" *ros-distribution*))


(defparameter *baxter-source-directory*
  (concatenate 'string
               (namestring (asdf:system-source-directory :robray))
               "/demo/baxter/"))

;; Define hosts for rendering
(setq *render-host-alist*
      '(("localhost"  ; 4 core (HT), 3.6GHz
         :jobs 8 :threads 1 :nice 0)
        ("dione"      ; 12 core, 1.4GHz
         :jobs 6 :threads 2 :nice 0)
        ("zeus"       ; 16 core, 2.4GHz
         :jobs 7 :threads 2 :nice 1 :povray "/home/ndantam/local/bin/povray")
        ))

;; Define search path for URDF
(pushnew (cons "baxter_description" *baxter-description*)
         *urdf-package-alist* :test #'equal)

;; Load robot scene graph from URDF
(defparameter *scene-graph*
  (scene-graph

   ;; robot
   (load-scene-file (format-pathname "~A/urdf/baxter.urdf" *baxter-description*)
                    :reload-meshes nil)
   ;; Text Label
   (scene-frame-fixed nil "textroot"
                      :tf (tf* (z-angle (* 0 pi)) nil))
   (scene-frame-fixed "textroot" "textbox"
                      :geometry (scene-geometry (scene-box '(.001 .85 .20))
                                                (draw-options-default :alpha .75))
                      :tf (tf* nil '(0 0 1)))
   (scene-frame-fixed "textroot" "text"
                      :geometry (scene-geometry (scene-text "Baxter"
                                                            :thickness .1)
                                                (draw-options :scale .25
                                                              :no-shadow t
                                                              :color '(0 1 0)))
                      :tf (tf* (z-angle (* .5 pi))
                               (vec3* (+ (* .1 .25) (* .5 .001)) -.35 .92)))

   ;; scene
   (load-scene-file (output-file "scene.robray" *baxter-source-directory*))

   ;; markers
   (item-frame-marker "right_endpoint" (draw-subframe "right_endpoint" "marker")
                      :length .15
                      :width .015
                      :options (draw-options :no-shadow t :alpha .5
                                             :visual t :collision nil))

   (item-frame-marker "left_endpoint" (draw-subframe "left_endpoint" "marker")
                      :length .15
                      :width .015
                      :options (draw-options :no-shadow t :alpha .5
                                             :visual t :collision nil))))



(uiop/stream:copy-file (output-file "baxter.inc" *baxter-source-directory*)
                       (output-file "baxter.inc" *robray-tmp-directory*))

(scene-graph-pov-frame  *scene-graph*
                        :configuration-map
                        (alist-tree-map `(("right_s0" . ,(* .25 pi))
                                          ("right_s1" . ,(* -0.25 pi))
                                          ("right_e0" . ,(* 0.0 pi))
                                          ("right_e1" . ,(* 0.25 pi))
                                          ("right_w0" . ,(* 0.0 pi))
                                          ("right_w1" . ,(* 0.5 pi))
                                          ("right_w2" . ,(* 0.0 pi)))
                                        #'string-compare)
                        :include "baxter.inc"
                        :render t
                        :options (render-options-default :use-collision nil
                                                         :options (render-options-medium))
                        :output "robray.pov")



;; (setq *scene-graph*
;;       (scene-graph-

;; Produce a simple animation
;; (time (scene-graph-time-animate
;;  (keyframe-configuration-function (list
;;                                    (joint-keyframe 0d0 nil)
;;                                    (joint-keyframe 2d0 `(("right_s0" ,(* .25 pi))
;;                                                          ("right_s1" ,(* -0.25 pi))
;;                                                          ("right_e0" ,(* 0.0 pi))
;;                                                          ("right_e1" ,(* 0.25 pi))
;;                                                          ("right_w0" ,(* 0.0 pi))
;;                                                          ("right_w1" ,(* 0.5 pi))
;;                                                          ("right_w2" ,(* 0.0 pi))))))
;;  :frames-per-second 15
;;  :time-end 2d0
;;  :encode-video t
;;  :include "baxter.inc" ))
