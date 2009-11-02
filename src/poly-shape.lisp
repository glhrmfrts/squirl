;;;; -*- Mode: Lisp; indent-tabs-mode: nil -*-
(in-package :squirl)

(defstruct poly-axis
  normal distance)

(defstruct (poly (:constructor %make-poly (body vertices offset))
                       (:include shape))
  vertices axes transformed-vertices transformed-axes)

(defun make-poly (body vertices offset)
  (let ((poly (%make-poly body verticel offset)))
    poly))

(defun validate-vertices (vertices)
  "Check that a set of vertices has a correct winding, and that they form a convex polygon."
  ;; todo
  )

(defun num-vertices (poly)
  (length (poly-vertices poly)))

(defun nth-vertex (index poly)
  (elt (poly-vertices poly) index))

(defun poly-value-on-axis (poly normal distance)
  "Returns the minimum distance of the polygon to the axis."
  (- (loop for vertex in (poly-vertices poly)
        minimizing (vec. normal vertex))
     distance))

(defun poly-contains-vertex-p (poly vertex)
  "Returns true if the polygon contains the vertex."
  ;; Lisp-hilarity
  (notany (lambda (axis)
            (plusp (- (vec. (poly-axis-normal axis) vertex)
                      (poly-axis-distance axis))))
          (poly-trans-formed-axes poly)))

(defun partial-poly-contains-vertex-p (poly vertex normal)
  "Same as POLY-CONTAINS-VERTEX-P, but ignores faces pointing away from NORMAL."
  ;; More hilarity. I'm honestly not sure that this translation is correct.
  (notany (lambda (axis)
            (unless (vec. (poly-axis-normal axis) normal)
                (plusp (- (vec. (poly-axis-normal axis) vertex)
                       (poly-axis-distance axis)))))
          (poly-trans-formed-axes poly)))

(defun poly-transform-vertices (poly position rotation)
  (setf (poly-transformed-vertices poly)
        (map 'list (lambda (vert) (vec+ position (vec-rotate vert rotation)))
             (poly-vertices poly))))

(defun poly-transform-axes (poly position rotation)
  (flet ((transformed-axis (axis)
           (let ((normal (vec-rotate (poly-axis-normal axis) rotation)))
             (make-poly-axis
              :normal normal
              :distance (+ (vec. p n) (poly-axis-distance axis))))))
    (setf (poly-transformed-axes poly)
          (map 'list #'transformed-axis (poly-axes poly)))))

(defmethod shape-cache-data ((poly poly) position rotation)
  (poly-transform-vertices poly position rotation)
  (poly-transform-axes poly position rotation)
  (let ((verts (poly-transformed-vertices poly))
        (left (vec-x (elt verts 0)))
        (right (vec-x (elt verts 0)))
        (top (vec-y (elt verts 0)))
        (bottom (vec-y (elt verts 0))))
    (loop for vert in verts
       do (setf left (min left (vec-x vert))
                right (max right (vec-x vert))
                top (max top (vec-y vert))
                bottom (min bottom (vec-y vert))))
    (make-bbox left bottom right top)))

(defmethod shape-point-query ((poly poly) position)
  (and (bbox-containts-vec-p (poly-bbox poly) position)
       (poly-shape-contains-vertex-p poly position)))