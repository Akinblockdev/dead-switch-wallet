;; Social Recovery Wallet with Dead Man's Switch
;; Implements social recovery with inactivity detection and emergency recovery

(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INVALID-GUARDIAN (err u2))
(define-constant ERR-ALREADY-VOTED (err u3))
(define-constant ERR-NOT-INACTIVE (err u4))
(define-constant ERR-INSUFFICIENT-VOTES (err u5))
(define-constant ERR-INVALID-PRINCIPAL (err u6))

;; Data vars
(define-data-var contract-owner principal tx-sender)
(define-data-var new-owner (optional principal) none)
(define-data-var last-active uint u0)
(define-data-var recovery-votes uint u0)
(define-data-var guardian-count uint u0)

;; Constants
(define-constant INACTIVITY-THRESHOLD u15552000) ;; 6 months in blocks (assuming 10 min/block)
(define-constant REQUIRED-VOTES u3)
(define-constant EMERGENCY-REQUIRED-VOTES u5)
(define-constant MAX-GUARDIANS u5)

;; Maps
(define-map guardians principal bool)
(define-map has-voted principal bool)

;; Private functions
(define-private (validate-principal (address principal))
    (not (is-eq address (var-get contract-owner))))

;; Public functions
(define-public (set-guardian (guardian principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (validate-principal guardian) ERR-INVALID-PRINCIPAL)
        (asserts! (< (var-get guardian-count) MAX-GUARDIANS) ERR-INVALID-GUARDIAN)
        (var-set guardian-count (+ (var-get guardian-count) u1))
        (ok (map-set guardians guardian true))))

(define-public (remove-guardian (guardian principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (validate-principal guardian) ERR-INVALID-PRINCIPAL)
        (asserts! (default-to false (map-get? guardians guardian)) ERR-INVALID-GUARDIAN)
        (var-set guardian-count (- (var-get guardian-count) u1))
        (ok (map-set guardians guardian false))))

(define-public (initiate-recovery (new-owner-principal principal))
    (let ((is-guardian (default-to false (map-get? guardians tx-sender)))
          (current-block-height block-height)
          (is-inactive (> (- current-block-height (var-get last-active)) INACTIVITY-THRESHOLD)))
        (asserts! is-guardian ERR-INVALID-GUARDIAN)
        (asserts! (validate-principal new-owner-principal) ERR-INVALID-PRINCIPAL)
        (asserts! (not (default-to false (map-get? has-voted tx-sender))) ERR-ALREADY-VOTED)
        (asserts! is-inactive ERR-NOT-INACTIVE)
        (var-set new-owner (some new-owner-principal))
        (map-set has-voted tx-sender true)
        (var-set recovery-votes (+ (var-get recovery-votes) u1))
        (ok true)))

(define-public (emergency-recovery (new-owner-principal principal))
    (let ((is-guardian (default-to false (map-get? guardians tx-sender))))
        (asserts! is-guardian ERR-INVALID-GUARDIAN)
        (asserts! (validate-principal new-owner-principal) ERR-INVALID-PRINCIPAL)
        (asserts! (not (default-to false (map-get? has-voted tx-sender))) ERR-ALREADY-VOTED)
        (var-set new-owner (some new-owner-principal))
        (map-set has-voted tx-sender true)
        (var-set recovery-votes (+ (var-get recovery-votes) u1))
        (ok true)))

(define-public (execute-recovery)
    (let ((votes (var-get recovery-votes))
          (new-owner-principal (unwrap! (var-get new-owner) ERR-NOT-AUTHORIZED)))
        (asserts! (>= votes REQUIRED-VOTES) ERR-INSUFFICIENT-VOTES)
        (var-set contract-owner new-owner-principal)
        (var-set recovery-votes u0)
        (var-set new-owner none)
        (var-set last-active block-height)
        (ok true)))

(define-public (execute-emergency-recovery)
    (let ((votes (var-get recovery-votes))
          (new-owner-principal (unwrap! (var-get new-owner) ERR-NOT-AUTHORIZED)))
        (asserts! (>= votes EMERGENCY-REQUIRED-VOTES) ERR-INSUFFICIENT-VOTES)
        (var-set contract-owner new-owner-principal)
        (var-set recovery-votes u0)
        (var-set new-owner none)
        (var-set last-active block-height)
        (ok true)))

(define-public (reset-timer)
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set last-active block-height)
        (ok true)))

;; Read-only functions
(define-read-only (get-owner)
    (ok (var-get contract-owner)))

(define-read-only (get-last-active)
    (ok (var-get last-active)))

(define-read-only (is-guardian (address principal))
    (ok (default-to false (map-get? guardians address))))

(define-read-only (get-recovery-votes)
    (ok (var-get recovery-votes)))

(define-read-only (has-guardian-voted (address principal))
    (ok (default-to false (map-get? has-voted address))))

(define-read-only (get-guardian-count)
    (ok (var-get guardian-count)))