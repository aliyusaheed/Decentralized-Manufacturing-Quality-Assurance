;; Certification Contract
;; Validates finished product quality in manufacturing

;; Data Variables
(define-map certifications
  { product-id: (string-ascii 64) }
  {
    certification-date: uint,
    expiration-date: (optional uint),
    certifier: principal,
    quality-score: uint, ;; 0-100 scale
    certification-level: (string-ascii 20), ;; "standard", "premium", "excellence"
    revoked: bool,
    revocation-reason: (optional (string-ascii 256))
  }
)

(define-data-var admin principal tx-sender)

;; Read-Only Functions
(define-read-only (get-certification (product-id (string-ascii 64)))
  (map-get? certifications { product-id: product-id })
)

(define-read-only (is-certified (product-id (string-ascii 64)))
  (match (get-certification product-id)
    cert (not (get revoked cert))
    false
  )
)

(define-read-only (get-admin)
  (var-get admin)
)

;; Public Functions
(define-public (certify-product
    (product-id (string-ascii 64))
    (quality-score uint)
    (certification-level (string-ascii 20))
    (expiration-blocks (optional uint))
  )
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can certify
    (asserts! (<= quality-score u100) (err u2)) ;; Quality score must be 0-100
    (asserts! (or (is-eq certification-level "standard")
                 (is-eq certification-level "premium")
                 (is-eq certification-level "excellence")) (err u3)) ;; Valid level

    (ok (map-set certifications
      { product-id: product-id }
      {
        certification-date: block-height,
        expiration-date: (match expiration-blocks
                           exp-blocks (some (+ block-height exp-blocks))
                           none),
        certifier: tx-sender,
        quality-score: quality-score,
        certification-level: certification-level,
        revoked: false,
        revocation-reason: none
      }
    ))
  )
)

(define-public (revoke-certification
    (product-id (string-ascii 64))
    (reason (string-ascii 256))
  )
  (let
    (
      (cert (unwrap! (get-certification product-id) (err u4))) ;; Certification must exist
    )
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can revoke
    (asserts! (not (get revoked cert)) (err u5)) ;; Cannot revoke already revoked cert

    (ok (map-set certifications
      { product-id: product-id }
      (merge cert {
        revoked: true,
        revocation-reason: (some reason)
      })
    ))
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only current admin can transfer
    (ok (var-set admin new-admin))
  )
)
