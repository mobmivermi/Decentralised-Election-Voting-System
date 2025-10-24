(define-constant contract-owner tx-sender)
(define-constant name (string-ascii 32) "Decentralised Election Voting")
(define-constant err-unauthorized (err u403))

(define-data-var version (string-ascii 16) u"1.0.0")

(define-read-only (get-name)
    (ok name)
)

(define-read-only (get-version) 
    (ok (var-get version))
)

(define-read-only (get-owner)
    (ok contract-owner)
)

(define-public (set-version (new-version (string-ascii 16)))
    (if (is-eq tx-sender contract-owner)
        (begin
            (var-set version new-version)
            (ok true)
        )
        err-unauthorized
    )
)