;; procedure index definitions

(define proc-id 0)
(define (proc-id-inc)
  (define v proc-id)
  (set! proc-id (+ 1 proc-id))
  v)
(define dictionary?-id (proc-id-inc))
(define dict-empty?-id (proc-id-inc))
(define dict-contains?-id (proc-id-inc))
(define dict=?-id (proc-id-inc))
(define dict-pure?-id (proc-id-inc))
(define dict-ref-id (proc-id-inc))
(define dict-ref/default-id (proc-id-inc))
(define dict-set-id (proc-id-inc))
(define dict-adjoin-id (proc-id-inc))
(define dict-delete-id (proc-id-inc))
(define dict-delete-all-id (proc-id-inc))
(define dict-replace-id (proc-id-inc))
(define dict-intern-id (proc-id-inc))
(define dict-update-id (proc-id-inc))
(define dict-update/default-id (proc-id-inc))
(define dict-pop-id (proc-id-inc))
(define dict-map-id (proc-id-inc))
(define dict-filter-id (proc-id-inc))
(define dict-remove-id (proc-id-inc))
(define dict-find-update-id (proc-id-inc))
(define dict-size-id (proc-id-inc))
(define dict-count-id (proc-id-inc))
(define dict-any-id (proc-id-inc))
(define dict-every-id (proc-id-inc))
(define dict-keys-id (proc-id-inc))
(define dict-values-id (proc-id-inc))
(define dict-entries-id (proc-id-inc))
(define dict-fold-id (proc-id-inc))
(define dict-map->list-id (proc-id-inc))
(define dict->alist-id (proc-id-inc))
(define dict-comparator-id (proc-id-inc))
(define dict-for-each-id (proc-id-inc))
(define dict->generator-id (proc-id-inc))
(define dict-set-accumulator-id (proc-id-inc))
(define dict-adjoin-accumulator-id (proc-id-inc))
(define dict-procedures-count (proc-id-inc)) ;; only used for tracking backing vector size
