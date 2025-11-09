(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-election (err u104))
(define-constant err-voting-closed (err u105))
(define-constant err-already-voted (err u106))
(define-constant err-invalid-candidate (err u107))
(define-constant err-election-not-started (err u108))
(define-constant err-election-ended (err u109))
(define-constant err-self-delegation (err u110))
(define-constant err-delegation-exists (err u111))
(define-constant err-no-delegation (err u112))

(define-data-var next-election-id uint u1)

(define-map elections
    { election-id: uint }
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        organizer: principal,
        start-block: uint,
        end-block: uint,
        is-active: bool,
        total-votes: uint,
    }
)

(define-map candidates
    {
        election-id: uint,
        candidate-id: uint,
    }
    {
        name: (string-ascii 50),
        description: (string-ascii 200),
        vote-count: uint,
        is-active: bool,
    }
)

(define-map election-candidates-count
    { election-id: uint }
    { count: uint }
)

(define-map votes
    {
        election-id: uint,
        voter: principal,
    }
    {
        candidate-id: uint,
        block-height: uint,
        timestamp: uint,
    }
)

(define-map voter-registrations
    {
        election-id: uint,
        voter: principal,
    }
    { is-registered: bool }
)

(define-map delegations
    {
        election-id: uint,
        delegator: principal,
    }
    {
        delegate: principal,
        block-height: uint,
    }
)

(define-map delegation-vote-count
    {
        election-id: uint,
        delegate: principal,
    }
    { count: uint }
)

(define-read-only (get-contract-owner)
    contract-owner
)

(define-read-only (get-next-election-id)
    (var-get next-election-id)
)

(define-read-only (get-election (election-id uint))
    (map-get? elections { election-id: election-id })
)

(define-read-only (get-candidate
        (election-id uint)
        (candidate-id uint)
    )
    (map-get? candidates {
        election-id: election-id,
        candidate-id: candidate-id,
    })
)

(define-read-only (get-vote
        (election-id uint)
        (voter principal)
    )
    (map-get? votes {
        election-id: election-id,
        voter: voter,
    })
)

(define-read-only (get-voter-registration
        (election-id uint)
        (voter principal)
    )
    (default-to false
        (get is-registered
            (map-get? voter-registrations {
                election-id: election-id,
                voter: voter,
            })
        ))
)

(define-read-only (get-delegation
        (election-id uint)
        (delegator principal)
    )
    (map-get? delegations {
        election-id: election-id,
        delegator: delegator,
    })
)

(define-read-only (get-delegation-count
        (election-id uint)
        (delegate principal)
    )
    (default-to u0
        (get count
            (map-get? delegation-vote-count {
                election-id: election-id,
                delegate: delegate,
            })
        ))
)

(define-read-only (get-election-candidates-count (election-id uint))
    (default-to u0
        (get count
            (map-get? election-candidates-count { election-id: election-id })
        ))
)

(define-read-only (is-election-active (election-id uint))
    (match (get-election election-id)
        election-data (let (
                (current-block stacks-block-height)
                (start-block (get start-block election-data))
                (end-block (get end-block election-data))
                (is-active (get is-active election-data))
            )
            (and
                is-active
                (>= current-block start-block)
                (< current-block end-block)
            )
        )
        false
    )
)

(define-read-only (has-voted
        (election-id uint)
        (voter principal)
    )
    (is-some (get-vote election-id voter))
)

(define-read-only (get-election-results (election-id uint))
    (let (
            (election-data (get-election election-id))
            (candidates-count (get-election-candidates-count election-id))
        )
        (if (is-some election-data)
            (ok {
                election: (unwrap-panic election-data),
                candidates-count: candidates-count,
            })
            err-not-found
        )
    )
)

(define-public (create-election
        (title (string-ascii 100))
        (description (string-ascii 500))
        (start-block uint)
        (end-block uint)
    )
    (let (
            (election-id (var-get next-election-id))
            (current-block stacks-block-height)
        )
        (asserts! (> end-block start-block) err-invalid-election)
        (asserts! (> start-block current-block) err-invalid-election)

        (map-set elections { election-id: election-id } {
            title: title,
            description: description,
            organizer: tx-sender,
            start-block: start-block,
            end-block: end-block,
            is-active: true,
            total-votes: u0,
        })

        (map-set election-candidates-count { election-id: election-id } { count: u0 })

        (var-set next-election-id (+ election-id u1))
        (ok election-id)
    )
)

(define-public (add-candidate
        (election-id uint)
        (name (string-ascii 50))
        (description (string-ascii 200))
    )
    (let (
            (election-data (unwrap! (get-election election-id) err-not-found))
            (candidates-count (get-election-candidates-count election-id))
            (new-candidate-id (+ candidates-count u1))
        )
        (asserts! (is-eq (get organizer election-data) tx-sender)
            err-unauthorized
        )
        (asserts! (get is-active election-data) err-invalid-election)
        (asserts! (< stacks-block-height (get start-block election-data))
            err-election-not-started
        )

        (map-set candidates {
            election-id: election-id,
            candidate-id: new-candidate-id,
        } {
            name: name,
            description: description,
            vote-count: u0,
            is-active: true,
        })

        (map-set election-candidates-count { election-id: election-id } { count: new-candidate-id })

        (ok new-candidate-id)
    )
)

(define-public (register-voter (election-id uint))
    (let ((election-data (unwrap! (get-election election-id) err-not-found)))
        (asserts! (get is-active election-data) err-invalid-election)
        (asserts! (< stacks-block-height (get start-block election-data))
            err-election-not-started
        )

        (map-set voter-registrations {
            election-id: election-id,
            voter: tx-sender,
        } { is-registered: true }
        )

        (ok true)
    )
)

(define-public (cast-vote
        (election-id uint)
        (candidate-id uint)
    )
    (let (
            (election-data (unwrap! (get-election election-id) err-not-found))
            (candidate-data (unwrap! (get-candidate election-id candidate-id)
                err-invalid-candidate
            ))
            (current-block stacks-block-height)
        )
        (asserts! (is-election-active election-id) err-voting-closed)
        (asserts! (get-voter-registration election-id tx-sender) err-unauthorized)
        (asserts! (not (has-voted election-id tx-sender)) err-already-voted)
        (asserts! (get is-active candidate-data) err-invalid-candidate)

        (map-set votes {
            election-id: election-id,
            voter: tx-sender,
        } {
            candidate-id: candidate-id,
            block-height: current-block,
            timestamp: current-block,
        })

        (map-set candidates {
            election-id: election-id,
            candidate-id: candidate-id,
        }
            (merge candidate-data { vote-count: (+ (get vote-count candidate-data) u1) })
        )

        (map-set elections { election-id: election-id }
            (merge election-data { total-votes: (+ (get total-votes election-data) u1) })
        )

        (ok true)
    )
)

(define-public (end-election (election-id uint))
    (let ((election-data (unwrap! (get-election election-id) err-not-found)))
        (asserts! (is-eq (get organizer election-data) tx-sender)
            err-unauthorized
        )
        (asserts! (get is-active election-data) err-invalid-election)

        (map-set elections { election-id: election-id }
            (merge election-data { is-active: false })
        )

        (ok true)
    )
)

(define-public (deactivate-candidate
        (election-id uint)
        (candidate-id uint)
    )
    (let (
            (election-data (unwrap! (get-election election-id) err-not-found))
            (candidate-data (unwrap! (get-candidate election-id candidate-id)
                err-invalid-candidate
            ))
        )
        (asserts! (is-eq (get organizer election-data) tx-sender)
            err-unauthorized
        )
        (asserts! (< stacks-block-height (get start-block election-data))
            err-election-not-started
        )

        (map-set candidates {
            election-id: election-id,
            candidate-id: candidate-id,
        }
            (merge candidate-data { is-active: false })
        )

        (ok true)
    )
)

(define-public (delegate-vote
        (election-id uint)
        (delegate principal)
    )
    (let (
            (election-data (unwrap! (get-election election-id) err-not-found))
            (current-block stacks-block-height)
        )
        (asserts! (is-election-active election-id) err-voting-closed)
        (asserts! (get-voter-registration election-id tx-sender) err-unauthorized)
        (asserts! (not (has-voted election-id tx-sender)) err-already-voted)
        (asserts! (not (is-eq tx-sender delegate)) err-self-delegation)
        (asserts! (is-none (get-delegation election-id tx-sender))
            err-delegation-exists
        )
        (asserts! (get-voter-registration election-id delegate) err-unauthorized)

        (map-set delegations {
            election-id: election-id,
            delegator: tx-sender,
        } {
            delegate: delegate,
            block-height: current-block,
        })

        (let ((current-count (get-delegation-count election-id delegate)))
            (map-set delegation-vote-count {
                election-id: election-id,
                delegate: delegate,
            } { count: (+ current-count u1) }
            )
        )

        (ok true)
    )
)

(define-public (revoke-delegation (election-id uint))
    (let (
            (election-data (unwrap! (get-election election-id) err-not-found))
            (delegation-data (unwrap! (get-delegation election-id tx-sender) err-no-delegation))
            (delegate (get delegate delegation-data))
        )
        (asserts! (is-election-active election-id) err-voting-closed)
        (asserts! (not (has-voted election-id tx-sender)) err-already-voted)

        (map-delete delegations {
            election-id: election-id,
            delegator: tx-sender,
        })

        (let ((current-count (get-delegation-count election-id delegate)))
            (map-set delegation-vote-count {
                election-id: election-id,
                delegate: delegate,
            } { count: (- current-count u1) }
            )
        )

        (ok true)
    )
)

(define-public (cast-delegated-vote
        (election-id uint)
        (candidate-id uint)
        (delegator principal)
    )
    (let (
            (election-data (unwrap! (get-election election-id) err-not-found))
            (candidate-data (unwrap! (get-candidate election-id candidate-id)
                err-invalid-candidate
            ))
            (delegation-data (unwrap! (get-delegation election-id delegator) err-no-delegation))
            (current-block stacks-block-height)
        )
        (asserts! (is-election-active election-id) err-voting-closed)
        (asserts! (is-eq (get delegate delegation-data) tx-sender)
            err-unauthorized
        )
        (asserts! (not (has-voted election-id delegator)) err-already-voted)
        (asserts! (get is-active candidate-data) err-invalid-candidate)

        (map-set votes {
            election-id: election-id,
            voter: delegator,
        } {
            candidate-id: candidate-id,
            block-height: current-block,
            timestamp: current-block,
        })

        (map-set candidates {
            election-id: election-id,
            candidate-id: candidate-id,
        }
            (merge candidate-data { vote-count: (+ (get vote-count candidate-data) u1) })
        )

        (map-set elections { election-id: election-id }
            (merge election-data { total-votes: (+ (get total-votes election-data) u1) })
        )

        (ok true)
    )
)
