;; Insulation Contractor Licensing Contract
;; Manages permits for thermal and acoustic insulation installation

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CONTRACTOR-EXISTS (err u101))
(define-constant ERR-CONTRACTOR-NOT-FOUND (err u102))
(define-constant ERR-INVALID-LICENSE-TYPE (err u103))
(define-constant ERR-INVALID-EXPERIENCE (err u104))
(define-constant ERR-LICENSE-SUSPENDED (err u105))
(define-constant ERR-INVALID-RATING (err u106))

;; Data Variables
(define-data-var next-contractor-id uint u1)
(define-data-var total-contractors uint u0)

;; Data Maps
(define-map contractors
  { contractor-id: uint }
  {
    principal: principal,
    business-name: (string-ascii 100),
    license-type: (string-ascii 50),
    experience-years: uint,
    license-status: (string-ascii 20),
    issue-date: uint,
    expiry-date: uint,
    rating: uint,
    completed-projects: uint
  }
)

(define-map contractor-by-principal
  { principal: principal }
  { contractor-id: uint }
)

(define-map license-types
  { license-type: (string-ascii 50) }
  {
    is-valid: bool,
    min-experience: uint,
    description: (string-ascii 200)
  }
)

;; Initialize valid license types
(map-set license-types { license-type: "thermal" }
  { is-valid: true, min-experience: u2, description: "Thermal insulation installation and maintenance" })
(map-set license-types { license-type: "acoustic" }
  { is-valid: true, min-experience: u3, description: "Acoustic insulation and soundproofing" })
(map-set license-types { license-type: "thermal-acoustic" }
  { is-valid: true, min-experience: u5, description: "Combined thermal and acoustic insulation services" })

;; Private Functions
(define-private (is-valid-license-type (license-type (string-ascii 50)))
  (match (map-get? license-types { license-type: license-type })
    license-info (get is-valid license-info)
    false
  )
)

(define-private (get-min-experience (license-type (string-ascii 50)))
  (match (map-get? license-types { license-type: license-type })
    license-info (get min-experience license-info)
    u0
  )
)

;; Public Functions
(define-public (register-contractor (business-name (string-ascii 100)) (license-type (string-ascii 50)) (experience-years uint))
  (let (
    (contractor-id (var-get next-contractor-id))
    (current-block block-height)
    (expiry-block (+ current-block u52560)) ;; Approximately 1 year
  )
    ;; Validate inputs
    (asserts! (is-valid-license-type license-type) ERR-INVALID-LICENSE-TYPE)
    (asserts! (>= experience-years (get-min-experience license-type)) ERR-INVALID-EXPERIENCE)
    (asserts! (is-none (map-get? contractor-by-principal { principal: tx-sender })) ERR-CONTRACTOR-EXISTS)

    ;; Create contractor record
    (map-set contractors
      { contractor-id: contractor-id }
      {
        principal: tx-sender,
        business-name: business-name,
        license-type: license-type,
        experience-years: experience-years,
        license-status: "active",
        issue-date: current-block,
        expiry-date: expiry-block,
        rating: u5,
        completed-projects: u0
      }
    )

    ;; Create principal mapping
    (map-set contractor-by-principal
      { principal: tx-sender }
      { contractor-id: contractor-id }
    )

    ;; Update counters
    (var-set next-contractor-id (+ contractor-id u1))
    (var-set total-contractors (+ (var-get total-contractors) u1))

    ;; Emit event
    (print {
      event: "contractor-registered",
      contractor-id: contractor-id,
      principal: tx-sender,
      business-name: business-name,
      license-type: license-type
    })

    (ok contractor-id)
  )
)

(define-public (renew-license (contractor-id uint))
  (let (
    (contractor-info (unwrap! (map-get? contractors { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND))
    (current-block block-height)
    (new-expiry (+ current-block u52560))
  )
    ;; Verify caller is the contractor
    (asserts! (is-eq tx-sender (get principal contractor-info)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get license-status contractor-info) "active") ERR-LICENSE-SUSPENDED)

    ;; Update expiry date
    (map-set contractors
      { contractor-id: contractor-id }
      (merge contractor-info { expiry-date: new-expiry })
    )

    ;; Emit event
    (print {
      event: "license-renewed",
      contractor-id: contractor-id,
      new-expiry: new-expiry
    })

    (ok true)
  )
)

(define-public (update-contractor-rating (contractor-id uint) (new-rating uint))
  (let (
    (contractor-info (unwrap! (map-get? contractors { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND))
  )
    ;; Only contract owner can update ratings
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= new-rating u1) (<= new-rating u10)) ERR-INVALID-RATING)

    ;; Update rating
    (map-set contractors
      { contractor-id: contractor-id }
      (merge contractor-info { rating: new-rating })
    )

    ;; Emit event
    (print {
      event: "rating-updated",
      contractor-id: contractor-id,
      new-rating: new-rating
    })

    (ok true)
  )
)

(define-public (suspend-license (contractor-id uint))
  (let (
    (contractor-info (unwrap! (map-get? contractors { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND))
  )
    ;; Only contract owner can suspend licenses
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Update status
    (map-set contractors
      { contractor-id: contractor-id }
      (merge contractor-info { license-status: "suspended" })
    )

    ;; Emit event
    (print {
      event: "license-suspended",
      contractor-id: contractor-id
    })

    (ok true)
  )
)

(define-public (complete-project (contractor-id uint))
  (let (
    (contractor-info (unwrap! (map-get? contractors { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND))
  )
    ;; Verify caller is the contractor
    (asserts! (is-eq tx-sender (get principal contractor-info)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get license-status contractor-info) "active") ERR-LICENSE-SUSPENDED)

    ;; Increment completed projects
    (map-set contractors
      { contractor-id: contractor-id }
      (merge contractor-info { completed-projects: (+ (get completed-projects contractor-info) u1) })
    )

    ;; Emit event
    (print {
      event: "project-completed",
      contractor-id: contractor-id,
      total-projects: (+ (get completed-projects contractor-info) u1)
    })

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-contractor (contractor-id uint))
  (map-get? contractors { contractor-id: contractor-id })
)

(define-read-only (get-contractor-by-principal (principal principal))
  (match (map-get? contractor-by-principal { principal: principal })
    contractor-ref (map-get? contractors { contractor-id: (get contractor-id contractor-ref) })
    none
  )
)

(define-read-only (get-total-contractors)
  (var-get total-contractors)
)

(define-read-only (is-license-valid (contractor-id uint))
  (match (map-get? contractors { contractor-id: contractor-id })
    contractor-info
      (and
        (is-eq (get license-status contractor-info) "active")
        (> (get expiry-date contractor-info) block-height)
      )
    false
  )
)

(define-read-only (get-license-type-info (license-type (string-ascii 50)))
  (map-get? license-types { license-type: license-type })
)
