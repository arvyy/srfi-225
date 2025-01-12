(define-library
  (srfi 225 default-impl)
  (import (scheme base)
          (srfi 1)
          (srfi 128)
          (srfi 225 core)
          (srfi 225 indexes))
  (export make-dto)
  (begin

    ;; implementation of "default" dto, used as a filler for undefined
    ;; functions in other dtos

    ;; primitives
    (define (not-implemented name)
      (lambda (dto . args)
        (raise (dictionary-error (string-append name " not implemented") dto))))
    (define default-dictionary? (not-implemented "dictionary?"))
    (define default-dict-pure? (not-implemented "dict-pure?"))
    (define default-dict-size (not-implemented "dict-size"))
    (define default-dict-find-update (not-implemented "dict-find-update"))

    (define (default-dict-empty? dto dictionary)
      (= 0 (dict-size dto dictionary)))

    (define (default-dict=? dto = dict1 dict2)
      (define (check-entries* keys)
        (cond
          ((null? keys) #t)
          (else (let* ((key (car keys))
                       (d1-value (dict-ref dto dict1 key)))
                  (dict-ref dto dict2 key
                            (lambda () #f)
                            (lambda (d2-value)
                              (if (= d1-value d2-value)
                                (check-entries* (cdr keys))
                                #f)))))))
      (and (= (dict-size dto dict1)
              (dict-size dto dict2))
           (check-entries* (dict-keys dto dict1))))

    (define (default-dict-contains? dto dictionary key)
      (dict-ref dto dictionary key
                (lambda () #f)
                (lambda (x) #t)))

    (define (default-dict-ref dto dictionary key failure success)
      (dict-find-update dto dictionary key
                        (lambda (insert ignore)
                          (failure))
                        (lambda (key value update remove)
                          (success value))))

    (define (default-dict-ref/default dto dictionary key default)
      (dict-ref dto dictionary key
                (lambda () default)
                (lambda (x) x)))

    ;; private
    (define (default-dict-set* dto dictionary use-old? objs)
      (let loop ((objs objs)
                 (dictionary dictionary))
        (cond
          ((null? objs)
           dictionary)
          ((null? (cdr objs))
           (error "mismatch of key / values argument list" objs))
          (else (let* ((key (car objs))
                       (value (cadr objs))
                       (new-d (dict-find-update dto dictionary key
                                                (lambda (insert ignore)
                                                  (insert value))
                                                (lambda (key old-value update delete)
                                                  (update key (if use-old? old-value value))))))
                  (loop (cddr objs)
                        new-d))))))

    (define (default-dict-set dto dictionary . objs)
      (default-dict-set* dto dictionary #f objs))

    (define (default-dict-adjoin dto dictionary . objs)
      (default-dict-set* dto dictionary #t objs))

    (define (default-dict-delete dto dictionary . keys)
      (dict-delete-all dto dictionary keys))

    (define (default-dict-delete-all dto dictionary keylist)
      (let loop ((keylist keylist)
                 (d dictionary))
        (cond
          ((null? keylist) d)
          (else (let* ((key (car keylist))
                       (new-d (dict-find-update dto d key
                                                (lambda (_ ignore)
                                                  (ignore))
                                                (lambda (key old-value _ delete)
                                                  (delete)))))
                  (loop (cdr keylist)
                        new-d))))))

    (define (default-dict-replace dto dictionary key value)
      (dict-find-update dto dictionary key
                        (lambda (_ ignore)
                          (ignore))
                        (lambda (key old-value update _)
                          (update key value))))

    (define (default-dict-intern dto dictionary key failure)
      (dict-find-update dto dictionary key
                        (lambda (insert _)
                          (let ((value (failure)))
                            (values (insert value) value)))
                        (lambda (key value update _)
                          (values dictionary value))))

    (define (default-dict-update dto dictionary key updater failure success)
      (dict-find-update dto dictionary key
                        (lambda (insert ignore)
                          (insert (updater (failure))))
                        (lambda (key value update _)
                          (update key (updater (success value))))))

    (define (default-dict-update/default dto dictionary key updater default)
      (dict-update dto dictionary key updater
                   (lambda () default)
                   (lambda (x) x)))

    (define (default-dict-pop dto dictionary)
      (define (do-pop)
        (call/cc
          (lambda (cont)
            (dict-for-each dto
                           (lambda (key value)
                             (define new-dict
                               (dict-delete-all dto dictionary (list key)))
                             (cont new-dict key value))
                           dictionary))))
      (define empty? (dict-empty? dto dictionary))
      (if empty?
        (error "popped empty dictionary")
        (do-pop)))

    (define default-dict-map (not-implemented "dict-map"))

    (define (default-dict-filter dto pred dictionary)
      (define keys (dict-keys dto dictionary))
      (define keys-to-delete
        (filter
          (lambda (key)
            (not (pred key (dict-ref dto dictionary key))))
          keys))
      (dict-delete-all dto dictionary keys-to-delete))

    (define (default-dict-remove dto pred dictionary)
      (dict-filter dto (lambda (key value)
                         (not (pred key value)))
                   dictionary))

    (define (default-dict-count dto pred dictionary)
      (dict-fold dto
                 (lambda (key value acc)
                   (if (pred key value)
                     (+ 1 acc)
                     acc))
                 0
                 dictionary))

    (define (default-dict-any dto pred dictionary)
      (call/cc
        (lambda (cont)
          (dict-for-each dto
                         (lambda (key value)
                           (define ret (pred key value))
                           (when ret
                             (cont ret)))
                         dictionary)
          #f)))

    (define (default-dict-every dto pred dictionary)
      (define last #t)
      (call/cc
        (lambda (cont)
          (dict-for-each dto
                         (lambda (key value)
                           (define ret (pred key value))
                           (when (not ret)
                             (cont #f))
                           (set! last ret))
                         dictionary)
          last)))

    (define (default-dict-keys dto dictionary)
      (reverse
        (dict-fold dto
                   (lambda (key value acc)
                     (cons key acc))
                   '()
                   dictionary)))

    (define (default-dict-values dto dictionary)
      (reverse
        (dict-fold dto
                   (lambda (key value acc)
                     (cons value acc))
                   '()
                   dictionary)))

    (define (default-dict-entries dto dictionary)
      (define pair
        (dict-fold dto
                   (lambda (key value acc)
                     (cons (cons key (car acc))
                           (cons value (cdr acc))))
                   (cons '() '())
                   dictionary))
      (values (reverse (car pair))
              (reverse (cdr pair))))

    (define (default-dict-fold dto proc knil dictionary)
      (define acc knil)
      (dict-for-each dto
                     (lambda (key value)
                       (set! acc (proc key value acc)))
                     dictionary)
      acc)

    (define (default-dict-map->list dto proc dictionary)
      (define reverse-lst
        (dict-fold dto
                   (lambda (key value lst)
                     (cons (proc key value) lst))
                   '()
                   dictionary))
      (reverse reverse-lst))

    (define (default-dict->alist dto dictionary)
      (dict-map->list dto
                      cons
                      dictionary))

    (define default-dict-comparator (not-implemented "dict-comparator"))

    (define (default-dict-for-each dto proc dict start end)
      (define (any . _) #t)
      (define cmp (dict-comparator dto dict))
      (define lower
        (if start
          (lambda (el) (>=? cmp el start))
          any))
      (define upper
        (if end
          (lambda (el) (<=? cmp el end))
          any))
      (define (accept el)
        (and (upper el) (lower el)))

      (dict-map 
        dto
        (lambda (key value)
          (when (accept key)
            (proc key value))
          value)
        dict))

    (define (default-dict->generator dto dict start end)

      (define (any . _) #t)
      (define cmp (dict-comparator dto dict))
      (define lower
        (if start
          (lambda (el) (>=? cmp el start))
          any))
      (define upper
        (if end
          (lambda (el) (<=? cmp el end))
          any))
      (define (accept el)
        (and (upper el) (lower el)))

      ;; proc that takes yield value and yield continuation when yield is called
      ;; shouldn't return
      (define yield-handler #f)

      (define (yield value)
        (when (or (eof-object? value)
                  (accept (car value)))
          (call/cc (lambda (yield-cont)
                     (yield-handler value yield-cont))) ))

      (define (generate)
        (dict-for-each dto
                       (lambda (key value)
                         (yield (cons key value)))
                       dict)
        (yield (eof-object)))

      ;; continuation at the point of last yield
      (define yield-cont #f)

      ;; check if eof return was seen; if yes, keep returning eof
      ;; for further invocations
      (define eof #f)

      (define (get-next-value exit)
        (set! yield-handler
          (lambda (value new-yield-cont)
            (set! yield-cont new-yield-cont)
            (when (eof-object? value)
              (set! eof #t)
              ;; unset continuation reference to allow
              ;; gc clean everything up
              (set! yield-cont #f))
            (exit value)))

        (cond
          ;; eof seen -- keep returning eof
          (eof (eof-object))
          ;; no yield called yet -- start the generator
          ((not yield-cont) (generate))
          ;; continue from last yield position
          (else (yield-cont #t))))

      (lambda ()
        (call/cc get-next-value)))

    (define (default-dict-accumulator dto dict acc-proc)
      (lambda (arg)
        (if (eof-object? arg)
          dict
          (set! dict (acc-proc dto dict (car arg) (cdr arg))))))

    (define (default-dict-set-accumulator dto dict)
      (default-dict-accumulator dto dict dict-set))

    (define (default-dict-adjoin-accumulator dto dict)
      (default-dict-accumulator dto dict dict-adjoin))

    (define null-dto (make-dto-private (make-vector dict-procedures-count #f)))

    (define default-dto
      (make-modified-dto
        null-dto
        (list
            dictionary?-id default-dictionary?
            dict-empty?-id default-dict-empty?
            dict-contains?-id default-dict-contains?
            dict=?-id default-dict=?
            dict-pure?-id default-dict-pure?
            dict-ref-id default-dict-ref
            dict-ref/default-id default-dict-ref/default
            dict-set-id default-dict-set
            dict-adjoin-id default-dict-adjoin
            dict-delete-id default-dict-delete
            dict-delete-all-id default-dict-delete-all
            dict-replace-id default-dict-replace
            dict-intern-id default-dict-intern
            dict-update-id default-dict-update
            dict-update/default-id default-dict-update/default
            dict-pop-id default-dict-pop
            dict-map-id default-dict-map
            dict-filter-id default-dict-filter
            dict-remove-id default-dict-remove
            dict-find-update-id default-dict-find-update
            dict-size-id default-dict-size
            dict-count-id default-dict-count
            dict-any-id default-dict-any
            dict-every-id default-dict-every
            dict-keys-id default-dict-keys
            dict-values-id default-dict-values
            dict-entries-id default-dict-entries
            dict-fold-id default-dict-fold
            dict-map->list-id default-dict-map->list
            dict->alist-id default-dict->alist
            dict-comparator-id default-dict-comparator

            dict-for-each-id default-dict-for-each

            ;; generator procedures
            dict->generator-id default-dict->generator
            dict-set-accumulator-id default-dict-set-accumulator
            dict-adjoin-accumulator-id default-dict-adjoin-accumulator)))

    (define (make-dto . lst)
      (make-modified-dto default-dto lst))

    ;; sanity check
    (vector-for-each
      (lambda (proc index)
        (unless (and proc (procedure? proc))
          (error "Missing or wrong default procedure definition" proc index)))
      (procvec default-dto)
      (list->vector (iota dict-procedures-count)))))
