;;;; -*- mode: lisp -*-
;;;;
;;;; Copyright (c) 2015, Rice University
;;;; All rights reserved.
;;;;
;;;; Author(s): Neil T. Dantam <ntd@gatech.edu>
;;;;
;;;;   Redistribution and use in source and binary forms, with or
;;;;   without modification, are permitted provided that the following
;;;;   conditions are met:
;;;;
;;;;   * Redistributions of source code must retain the above
;;;;     copyright notice, this list of conditions and the following
;;;;     disclaimer.
;;;;   * Redistributions in binary form must reproduce the above
;;;;     copyright notice, this list of conditions and the following
;;;;     disclaimer in the documentation and/or other materials
;;;;     provided with the distribution.
;;;;   * Neither the name of copyright holder the names of its
;;;;     contributors may be used to endorse or promote products
;;;;     derived from this software without specific prior written
;;;;     permission.
;;;;
;;;;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
;;;;   CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
;;;;   INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
;;;;   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;;;;   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
;;;;   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;;;;   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;;;;   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
;;;;   USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
;;;;   AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;;;;   LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
;;;;   ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;;;   POSSIBILITY OF SUCH DAMAGE.

(in-package :robray)


(defun scene-genc-mesh-var (mesh)
  (rope "mesh__" (scene-mesh-name mesh)))

(defun scene-genc-frame (scene-graph argument-name frame)
  (let* ((tf (scene-frame-tf frame))
         (name (scene-frame-name frame))
         (name-string (cgen-string (scene-frame-name frame)))
         (parent-string (cgen-string (scene-frame-parent frame)))
         (q (tf-quaternion tf))
         (v (tf-translation tf)))
    (list
     (cgen-line-comment (rope "FRAME: " name)))
    (cgen-block
     (cgen-declare-array "static const double" "q" (amino::vec-list q))
     (cgen-declare-array   "static const double""v" (amino::vec-list v))
     (when (scene-frame-joint-p frame)
       (cgen-declare-array "static const double" "axis" (amino::vec-list (scene-frame-joint-axis frame))))
      (etypecase frame
        (scene-frame-fixed
         (cgen-call-stmt "aa_rx_sg_add_frame_fixed"
                         argument-name
                         parent-string name-string
                         "q" "v"))
        (scene-frame-joint
         (list
          (cgen-call-stmt (etypecase frame
                            (scene-frame-prismatic "aa_rx_sg_add_frame_prismatic")
                            (scene-frame-revolute "aa_rx_sg_add_frame_revolute"))
                          argument-name
                          parent-string name-string
                          "q" "v"
                          (cgen-string (scene-frame-joint-configuration-name frame))
                          "axis"
                          (scene-frame-joint-configuration-offset frame))
          ;; TODO: Map over limits separately from frames
          (when-let* ((config-name (scene-frame-joint-configuration-name frame))
                      (limits (scene-graph-config-limits scene-graph config-name)))
            (labels ((emit-limit (fun limit-fun)
                       (when-let* ((limit (funcall limit-fun limits))
                                   (min (joint-limit-min limit))
                                   (max (joint-limit-max limit)))
                         (cgen-call-stmt fun argument-name
                                         (cgen-string config-name)
                                         min max))))
              (list (emit-limit "aa_rx_sg_set_limit_pos" #'joint-limits-position)
                    (emit-limit "aa_rx_sg_set_limit_vel" #'joint-limits-velocity)
                    (emit-limit "aa_rx_sg_set_limit_acc" #'joint-limits-acceleration)
                    (emit-limit "aa_rx_sg_set_limit_eff" #'joint-limits-effort))))
          (when-let ((inertial (scene-frame-inertial frame)))
            (list
             (cgen-declare-array "static const double" "inertia" (amino::vec-list (frame-inertial-inertia inertial)))
             (cgen-call-stmt "aa_rx_sg_frame_set_inertial" argument-name name-string
                             (frame-inertial-mass inertial)
                             "inertia")))))))))

(defun scene-genc-geom (argument-name frame geom)
  (let ((cgeom "geom")
        (copt "opt")
        (options (scene-geometry-options geom))
        (shape (scene-geometry-shape geom)))
    (cgen-block
     (cgen-declare "struct aa_rx_geom *" cgeom)
     (cgen-declare "struct aa_rx_geom_opt *" copt (cgen-call "aa_rx_geom_opt_create"))
     (apply #'cgen-call-stmt "aa_rx_geom_opt_set_color3" copt
            (amino::vec-list (draw-option options :color)))
     (cgen-call-stmt "aa_rx_geom_opt_set_alpha" copt  (draw-option options :alpha))
     (apply #'cgen-call-stmt "aa_rx_geom_opt_set_specular3" copt
            (amino::vec-list (draw-option options :specular)))
     (cgen-call-stmt "aa_rx_geom_opt_set_visual" copt
                     (if (draw-option options :visual) 1 0))
     (cgen-call-stmt "aa_rx_geom_opt_set_collision" copt
                     (if (draw-option options :collision) 1 0))
     (cgen-call-stmt "aa_rx_geom_opt_set_no_shadow" copt
                     (if (draw-option options :no-shadow) 1 0))
     (etypecase shape
       (scene-mesh
        (cgen-assign-stmt cgeom (cgen-call "aa_rx_geom_mesh" copt (scene-genc-mesh-var shape))))
       (scene-box
        (list (cgen-declare-array "static const double" "dimension" (amino::vec-list (scene-box-dimension shape)))

              (cgen-assign-stmt cgeom (cgen-call "aa_rx_geom_box" copt "dimension"))))
       (scene-sphere
        (cgen-assign-stmt cgeom (cgen-call "aa_rx_geom_sphere" copt (scene-sphere-radius shape))))
       (scene-cylinder
        (cgen-assign-stmt cgeom (cgen-call "aa_rx_geom_cylinder" copt
                                          (scene-cylinder-height shape)
                                          (scene-cylinder-radius shape))))
       (scene-cone
        (cgen-assign-stmt cgeom (cgen-call "aa_rx_geom_cone" copt
                                          (scene-cone-height shape)
                                          (scene-cone-start-radius shape)
                                          (scene-cone-end-radius shape))))
       (scene-grid

        (list (cgen-declare-array "static const double" "dimension"
                                  (amino::vec-list (scene-grid-dimension shape)))
              (cgen-declare-array "static const double" "delta"
                                  (amino::vec-list (scene-grid-delta shape)))
              (cgen-assign-stmt cgeom (cgen-call "aa_rx_geom_grid" copt
                                                 "dimension"
                                                 "delta"
                                                 (scene-grid-thickness shape)))))

        )
     (cgen-call-stmt "aa_rx_geom_attach" argument-name
                     (cgen-string (scene-frame-name frame)) cgeom)
     (cgen-call-stmt "aa_rx_geom_opt_destroy" copt)
     )))

(defun ratio->octet (f)
  (assert (and (<= f 1d0)
               (>= f 0)))
  (clamp (round (* 255 f)) 0 255))

(defun scene-genc-mesh-texture (var mesh-data)
  (when-let ((textures (mesh-data-texture-properties mesh-data))
             (texture-indices (mesh-data-texture-indices mesh-data)))
    (assert (= (* 3 (length texture-indices))
               (length (mesh-data-vertex-vectors mesh-data))))
    (let* ((n (length textures))
           (nd (coerce n 'double-float))
           (m (length texture-indices))
           (rgba (make-fnvec (* 4 n)))
           (uv (make-vec (* 2 m)))
           (t-delta (coerce (/ 1 (* 2 n)) 'double-float))
           (i -1))
      ;; Fill RGBA
      (map nil (lambda (opt)
                 ;(print opt)
                 (let ((rgb (alist-get-default opt :diffuse '(.5d0 .5d0 .5d0)))
                       (alpha (alist-get-default opt :alpha 1d0)))
                   ;(print rgb)
                   (setf (aref rgba (incf i)) (ratio->octet (vec-x rgb)))
                   (setf (aref rgba (incf i)) (ratio->octet (vec-y rgb)))
                   (setf (aref rgba (incf i)) (ratio->octet (vec-z rgb)))
                   (setf (aref rgba (incf i)) (ratio->octet alpha))))
           textures)
      ;; Fill UV
      (setq i -1)
      (dotimes (j (length texture-indices))
        (setf (aref uv (incf i)) (+ (/ (coerce (aref texture-indices j) 'double-float)
                                       nd)
                                    t-delta))
        (setf (aref uv (incf i)) 0d0))
      ;; output
      (list
       (cgen-declare-array "static const unsigned char" "rgba" rgba)
       (cgen-declare-array "static const float" "uv" uv)

       (cgen-call-stmt "aa_rx_mesh_set_rgba" var n 1
                       "rgba" 0)
       (cgen-call-stmt "aa_rx_mesh_set_uv" var m "uv" 0)))))


(defun scene-genc-mesh-function-name (mesh)
  (rope "aa_rx_dl_mesh__" (scene-mesh-name mesh)))

(defun scene-genc-mesh-functions (scene-graph static)
  ;; declare
  (loop for mesh in (scene-graph-meshes scene-graph)
     for var = (scene-genc-mesh-var mesh)
     for mesh-data = (load-mesh (scene-mesh-source-file mesh))
     for normed-data = (mesh-deindex-normals mesh-data)
     collect
       (cgen-defun (rope (when static "static ") "struct aa_rx_mesh *")
                   (scene-genc-mesh-function-name mesh)
                   nil
                   (list (cgen-declare "struct aa_rx_mesh *" var (cgen-call "aa_rx_mesh_create"))
                         ;; vertices
                         (cgen-declare-array "static const float" "vertices"
                                             (mesh-data-vertex-vectors normed-data))
                         ;; normals
                         (cgen-declare-array "static const float" "normals"
                                             (mesh-data-normal-vectors normed-data))
                         ;; indices
                         (cgen-declare-array "static const unsigned" "indices"
                                             (mesh-data-vertex-indices normed-data))
                         ;; fill
                         (cgen-call-stmt "aa_rx_mesh_set_vertices" var (mesh-data-vertex-vectors-count normed-data)
                                         "vertices" 0)
                         (cgen-call-stmt "aa_rx_mesh_set_indices" var (mesh-data-vertex-indices-count normed-data)
                                         "indices" 0)
                         (cgen-call-stmt "aa_rx_mesh_set_normals" var (mesh-data-normal-vectors-count normed-data)
                                         "normals" 0)
                         ;; textures,
                         (scene-genc-mesh-texture var normed-data)
                         ;; result
                         (cgen-return var)))))

(defun scene-genc-mesh-vars (scene-graph)
  ;; declare
  (loop for mesh in (scene-graph-meshes scene-graph)
     for var = (scene-genc-mesh-var mesh)
     collect
       (cgen-declare "struct aa_rx_mesh *" var
                     (cgen-call (scene-genc-mesh-function-name mesh)))))


(defun scene-genc-mesh-cleanup (scene-graph)
  (loop for mesh in (scene-graph-meshes scene-graph)
     collect
       (cgen-call-stmt "aa_rx_mesh_destroy" (scene-genc-mesh-var mesh))))


(defun scene-graph-genc (scene-graph &key
                                       (static-mesh t)
                                       (name "scenegraph"))
  (let ((argument-name "sg")
        (function-name (rope-string (rope "aa_rx_dl_sg__" name)))
        (stmts))
    (labels ((item (x) (push x stmts)))
      ;; Lazily create object
      (item (cgen-if (cgen-equal "NULL" argument-name)
                     (cgen-stmt (cgen-assign argument-name
                                             (cgen-call "aa_rx_sg_create")))))
      ;; Map Frames
      (item (map-scene-graph-frames 'list (lambda (frame)
                                            (scene-genc-frame scene-graph argument-name frame))
                                    scene-graph))
      ;; Initialize meshes
      (item (scene-genc-mesh-vars scene-graph))
      ;; Map geometry
      (item (map-scene-graph-geometry 'list (lambda (frame geometry)
                                              (scene-genc-geom argument-name frame geometry))
                                      scene-graph))

      (item (scene-genc-mesh-cleanup scene-graph))
      ;; Return create object
      (item (cgen-return argument-name))
      ;; Ropify
      (flatten (list
                (scene-genc-mesh-functions scene-graph static-mesh)
                (cgen-defun "struct aa_rx_sg *" function-name (rope "struct aa_rx_sg *" argument-name)
                            (flatten (reverse stmts))))))))

(defun scene-graph-so (source-file shared-object)
  (uiop/run-program:run-program
   (list "gcc" "--std=gnu99" "-fPIC" "-shared" source-file "-o" shared-object)))


(defun genc-mesh-link (mesh)
  (format-pathname "~A/cache/~A.so"
                   *robray-tmp-directory*
                   (scene-mesh-source-file mesh)))

(defun scene-graph-link-meshes (scene-graph shared-object)

  (loop for mesh in (scene-graph-meshes scene-graph)
     for name = (genc-mesh-link mesh)
     for dirname = (file-dirname name)
     unless (probe-file name)
     do
       (progn
         (create-parent-directories name)
         (uiop/run-program:run-program
          (list "ln" "-vsf" shared-object name)))))

(defun scene-graph-compile (scene-graph source-file
                            &key
                              (name "scenegraph")
                              shared-object
                              (reload t)
                              (static-mesh t)
                              (link-meshes nil))
  ;; source file
  (when (or reload
            (not (probe-file source-file)))
    (create-parent-directories source-file)
    (with-open-file (stream source-file
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :direction :output)
      (let ((source-rope (scene-graph-genc scene-graph
                                           :name name
                                           :static-mesh static-mesh)))
        (output (rope (cgen-include-system "amino.h")
                      (cgen-include-system "amino/rx.h")
                      source-rope)
                stream))))
  ;; shared object
  (when (and shared-object
             (or reload
                 (not (probe-file shared-object))
                 (< (file-write-date shared-object)
                    (file-write-date source-file))))
    (scene-graph-so source-file shared-object))
  ;; links
  (when (and link-meshes shared-object)
    (scene-graph-link-meshes scene-graph shared-object)))


;;;;;;;;;;;;;;;;;;;;
;; Plugin loading ;;
;;;;;;;;;;;;;;;;;;;;

(cffi:defcfun aa-rx-dl-mesh rx-mesh-t
  (filename :string)
  (mesh-name :string))

(defun load-rx-mesh (mesh)
  (let ((rx-mesh
         (aa-rx-dl-mesh (genc-mesh-link mesh)
                        (scene-mesh-name mesh))))
    (assert (= 1 (aa-rx-mesh-refcount (rx-mesh-pointer rx-mesh))))
    rx-mesh))
