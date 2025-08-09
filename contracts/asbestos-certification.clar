;; Asbestos Abatement Certification Contract
;; Manages specialized licenses for asbestos removal contractors

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-CONTRACTOR-NOT-FOUND (err u301))
(define-constant ERR-INVALID-CERTIFICATION-LEVEL (err u302))
(define-constant ERR-CERTIFICATION-EXISTS (err u303))
(define-constant ERR-CERTIFICATION-EXPIRED (err u304))
(define-constant ERR-INVALID-TRAINING-HOURS (err u305))
(define-constant ERR-INCIDENT-NOT-FOUND (err u306))

;; Data Variables
(define-data-var next-certification-id uint u1)
(define-data-var next-incident-id uint u1)
(define-data-var total-certifications uint u0)
(define-data-var total-incidents uint u0)

;; Data Maps
(define-map certifications
  { certification-id: uint }
  {
    contractor-principal: principal,
    certification-level: (string-ascii 20),
    issue-date: uint,
    expiry-date: uint,
    training-hours: uint,
    status: (string-ascii 20),
    renewal-count: uint,
    last-inspection: (optional uint)
  }
)

(define-map contractor-certifications
  { contractor-principal: principal }
  { certification-id: uint }
)

(define-map certification-levels
  { level: (string-ascii 20) }
  {
    min-training-hours: uint,
    validity-period: uint,
    description: (string-ascii 200)
  }
)

(define-map incidents
  { incident-id: uint }
  {
    contractor-principal: principal,
    incident-date: uint,
    severity: (string-ascii 20),
    description: (string-ascii 500),
    resolved: bool,
    resolution-date: (optional uint)
  }
)

;; Initialize certification levels
(map-set certification-levels { level: "level-1" }
  { min-training-hours: u40, validity-period: u26280, description: "Basic asbestos awareness and handling" })
(map-set certification-levels { level: "level-2" }
  { min-training-hours: u80, validity-period: u26280, description: "Intermediate asbestos removal and containment" })
(map-set certification-levels { level: "level-3" }
  { min-training-hours: u120, validity-period: u17520, description: "Advanced asbestos abatement and supervision" })

;; Private Functions
(define-private (is-valid-certification-level (level (string-ascii 20)))
  (is-some (map-get? certification-levels { level: level }))
)

(define-private (get-level-requirements (level (string-ascii 20)))
  (map-get? certification-levels { level: level })
)

(define-private (calculate-expiry-date (level (string-ascii 20)) (issue-date uint))
  (match (map-get? certification-levels { level: level })
    level-info (+ issue-date (get validity-period level-info))
    (+ issue-date u26280) ;; Default 6 months
  )
)

;; Public Functions
(define-public (issue-certification (contractor-principal principal) (certification-level (string-ascii 20)) (training-hours uint))
  (let (
    (certification-id (var-get next-certification-id))
    (current-block block-height)
    (level-requirements (unwrap! (get-level-requirements certification-level) ERR-INVALID-CERTIFICATION-LEVEL))
    (expiry-date (calculate-expiry-date certification-level current-block))
  )
    ;; Only contract owner can issue certifications
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-certification-level certification-level) ERR-INVALID-CERTIFICATION-LEVEL)
    (asserts! (>= training-hours (get min-training-hours level-requirements)) ERR-INVALID-TRAINING-HOURS)
    (asserts! (is-none (map-get? contractor-certifications { contractor-principal: contractor-principal })) ERR-CERTIFICATION-EXISTS)

    ;; Create certification record
    (map-set certifications
      { certification-id: certification-id }
      {
        contractor-principal: contractor-principal,
        certification-level: certification-level,
        issue-date: current-block,
        expiry-date: expiry-date,
        training-hours: training-hours,
        status: "active",
        renewal-count: u0,
        last-inspection: none
      }
    )

    ;; Create contractor mapping
    (map-set contractor-certifications
      { contractor-principal: contractor-principal }
      { certification-id: certification-id }
    )

    ;; Update counters
    (var-set next-certification-id (+ certification-id u1))
    (var-set total-certifications (+ (var-get total-certifications) u1))

    ;; Emit event
    (print {
      event: "certification-issued",
      certification-id: certification-id,
      contractor-principal: contractor-principal,
      certification-level: certification-level,
      expiry-date: expiry-date
    })

    (ok certification-id)
  )
)

(define-public (renew-certification (certification-id uint) (additional-training-hours uint))
  (let (
    (cert-info (unwrap! (map-get? certifications { certification-id: certification-id }) ERR-CONTRACTOR-NOT-FOUND))
    (current-block block-height)
    (level-requirements (unwrap! (get-level-requirements (get certification-level cert-info)) ERR-INVALID-CERTIFICATION-LEVEL))
    (new-expiry (calculate-expiry-date (get certification-level cert-info) current-block))
  )
    ;; Verify caller is the contractor or owner
    (asserts! (or
      (is-eq tx-sender CONTRACT-OWNER)
      (is-eq tx-sender (get contractor-principal cert-info))
    ) ERR-NOT-AUTHORIZED)
    (asserts! (>= additional-training-hours (get min-training-hours level-requirements)) ERR-INVALID-TRAINING-HOURS)

    ;; Update certification
    (map-set certifications
      { certification-id: certification-id }
      (merge cert-info {
        expiry-date: new-expiry,
        training-hours: (+ (get training-hours cert-info) additional-training-hours),
        renewal-count: (+ (get renewal-count cert-info) u1),
        status: "active"
      })
    )

    ;; Emit event
    (print {
      event: "certification-renewed",
      certification-id: certification-id,
      new-expiry: new-expiry,
      total-training-hours: (+ (get training-hours cert-info) additional-training-hours)
    })

    (ok true)
  )
)

(define-public (suspend-certification (certification-id uint))
  (let (
    (cert-info (unwrap! (map-get? certifications { certification-id: certification-id }) ERR-CONTRACTOR-NOT-FOUND))
  )
    ;; Only contract owner can suspend certifications
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Update status
    (map-set certifications
      { certification-id: certification-id }
      (merge cert-info { status: "suspended" })
    )

    ;; Emit event
    (print {
      event: "certification-suspended",
      certification-id: certification-id,
      contractor-principal: (get contractor-principal cert-info)
    })

    (ok true)
  )
)

(define-public (report-incident (contractor-principal principal) (severity (string-ascii 20)) (description (string-ascii 500)))
  (let (
    (incident-id (var-get next-incident-id))
    (current-block block-height)
  )
    ;; Only contract owner can report incidents
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Create incident record
    (map-set incidents
      { incident-id: incident-id }
      {
        contractor-principal: contractor-principal,
        incident-date: current-block,
        severity: severity,
        description: description,
        resolved: false,
        resolution-date: none
      }
    )

    ;; Update counters
    (var-set next-incident-id (+ incident-id u1))
    (var-set total-incidents (+ (var-get total-incidents) u1))

    ;; Emit event
    (print {
      event: "incident-reported",
      incident-id: incident-id,
      contractor-principal: contractor-principal,
      severity: severity
    })

    (ok incident-id)
  )
)

(define-public (resolve-incident (incident-id uint))
  (let (
    (incident-info (unwrap! (map-get? incidents { incident-id: incident-id }) ERR-INCIDENT-NOT-FOUND))
    (current-block block-height)
  )
    ;; Only contract owner can resolve incidents
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Update incident
    (map-set incidents
      { incident-id: incident-id }
      (merge incident-info {
        resolved: true,
        resolution-date: (some current-block)
      })
    )

    ;; Emit event
    (print {
      event: "incident-resolved",
      incident-id: incident-id,
      resolution-date: current-block
    })

    (ok true)
  )
)

(define-public (record-inspection (certification-id uint))
  (let (
    (cert-info (unwrap! (map-get? certifications { certification-id: certification-id }) ERR-CONTRACTOR-NOT-FOUND))
    (current-block block-height)
  )
    ;; Only contract owner can record inspections
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Update last inspection date
    (map-set certifications
      { certification-id: certification-id }
      (merge cert-info { last-inspection: (some current-block) })
    )

    ;; Emit event
    (print {
      event: "inspection-recorded",
      certification-id: certification-id,
      inspection-date: current-block
    })

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-certification (certification-id uint))
  (map-get? certifications { certification-id: certification-id })
)

(define-read-only (get-contractor-certification (contractor-principal principal))
  (match (map-get? contractor-certifications { contractor-principal: contractor-principal })
    cert-ref (map-get? certifications { certification-id: (get certification-id cert-ref) })
    none
  )
)

(define-read-only (is-certification-valid (certification-id uint))
  (match (map-get? certifications { certification-id: certification-id })
    cert-info
      (and
        (is-eq (get status cert-info) "active")
        (> (get expiry-date cert-info) block-height)
      )
    false
  )
)

(define-read-only (get-incident (incident-id uint))
  (map-get? incidents { incident-id: incident-id })
)

(define-read-only (get-certification-level-info (level (string-ascii 20)))
  (map-get? certification-levels { level: level })
)

(define-read-only (get-system-stats)
  {
    total-certifications: (var-get total-certifications),
    total-incidents: (var-get total-incidents)
  }
)
