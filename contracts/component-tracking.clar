;; Component Tracking Contract
;; Records parts used in assembly for manufacturing quality assurance

;; Data Variables
(define-map components
  { component-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    manufacturer: (string-ascii 100),
    batch-number: (string-ascii 64),
    production-date: uint,
    specifications: (string-ascii 256),
    verified: bool
  }
)

(define-map product-components
  { product-id: (string-ascii 64), component-id: (string-ascii 64) }
  { added-at: uint }
)

(define-data-var admin principal tx-sender)

;; Read-Only Functions
(define-read-only (get-component (component-id (string-ascii 64)))
  (map-get? components { component-id: component-id })
)

(define-read-only (is-component-in-product (product-id (string-ascii 64)) (component-id (string-ascii 64)))
  (is-some (map-get? product-components { product-id: product-id, component-id: component-id }))
)

(define-read-only (get-admin)
  (var-get admin)
)

;; Public Functions
(define-public (register-component
    (component-id (string-ascii 64))
    (name (string-ascii 100))
    (manufacturer (string-ascii 100))
    (batch-number (string-ascii 64))
    (production-date uint)
    (specifications (string-ascii 256))
  )
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can register
    (asserts! (is-none (get-component component-id)) (err u2)) ;; Component ID must be unique

    (ok (map-set components
      { component-id: component-id }
      {
        name: name,
        manufacturer: manufacturer,
        batch-number: batch-number,
        production-date: production-date,
        specifications: specifications,
        verified: false
      }
    ))
  )
)

(define-public (verify-component (component-id (string-ascii 64)))
  (let
    (
      (component (unwrap! (get-component component-id) (err u3))) ;; Component must exist
    )
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can verify

    (ok (map-set components
      { component-id: component-id }
      (merge component { verified: true })
    ))
  )
)

(define-public (add-component-to-product (product-id (string-ascii 64)) (component-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can add
    (asserts! (is-some (get-component component-id)) (err u3)) ;; Component must exist
    (asserts! (not (is-component-in-product product-id component-id)) (err u4)) ;; Component not already in product

    (ok (map-set product-components
      { product-id: product-id, component-id: component-id }
      { added-at: block-height }
    ))
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only current admin can transfer
    (ok (var-set admin new-admin))
  )
)
