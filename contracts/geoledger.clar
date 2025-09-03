;; GeoLedger: A comprehensive contract for a decentralized land registry and zoning management.
;; It represents land parcels as NFTs (SIP-009) and manages their associated metadata,
;; including location, area, and zoning classification.
;; It also includes a system for proposing and approving zoning changes.
;; This contract implements SIP-009 NFT standard functions directly.

;; --- Constants and Error Codes ---
(define-constant CONTRACT-ADMIN tx-sender)
(define-constant ERR-NOT-AUTHORIZED u101)
(define-constant ERR-PARCEL-NOT-FOUND u102)
(define-constant ERR-PROPOSAL-NOT-FOUND u103)
(define-constant ERR-ALREADY-VOTED u104)
(define-constant ERR-VOTING-CLOSED u105)
(define-constant ERR-PARCEL-OWNER-ONLY u106)
(define-constant ERR-INVALID-ZONING-TYPE u107)
(define-constant CONTRACT-NAME "geoledger")

;; --- Data Storage ---

;; NFT definition for land parcels
(define-non-fungible-token geoledger-parcel uint)

;; Main data variables
(define-data-var last-parcel-id uint u0)
(define-data-var proposal-counter uint u0)

;; Data maps
(define-map parcel-metadata uint {
  gps-coordinates: (string-ascii 64),
  area-sq-meters: uint,
  zoning-class: (string-ascii 40)
})

(define-map proposals uint {
  proposer: principal,
  parcel-id: uint,
  proposed-zoning: (string-ascii 40),
  is-approved: bool,
  votes-for: uint,
  votes-against: uint
})

(define-map voter-registry {proposal-id: uint, voter: principal} bool)

;; A list of valid zoning types, managed by the admin.
(define-map valid-zoning-types (string-ascii 40) bool)

;; --- Initialization ---
(map-set valid-zoning-types "Residential" true)
(map-set valid-zoning-types "Commercial" true)
(map-set valid-zoning-types "Industrial" true)
(map-set valid-zoning-types "Agricultural" true)

;; --- SIP-009 NFT Standard Functions ---

;; Get the last token ID issued.
(define-read-only (get-last-token-id)
  (ok (var-get last-parcel-id))
)

;; Get the URI for a given parcel's metadata.
;; Returns a static URI pattern with proper SIP-009 response format.
(define-read-only (get-token-uri (token-id uint))
  (if (is-some (map-get? parcel-metadata token-id))
    (ok (some "https://geoledger.api/parcels/metadata"))
    (err ERR-PARCEL-NOT-FOUND)
  )
)

;; Get the owner of a specific parcel.
(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? geoledger-parcel token-id))
)

;; Transfer a parcel to a new owner.
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) (err ERR-NOT-AUTHORIZED))
    (nft-transfer? geoledger-parcel token-id sender recipient)
  )
)

;; --- Contract Admin Functions ---

;; Register a new parcel of land. Only the contract administrator can do this.
(define-public (register-parcel (owner principal) (gps-coords (string-ascii 64)) (area uint) (zoning (string-ascii 40)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-ADMIN) (err ERR-NOT-AUTHORIZED))
    (asserts! (default-to false (map-get? valid-zoning-types zoning)) (err ERR-INVALID-ZONING-TYPE))
    (let ((new-id (+ (var-get last-parcel-id) u1)))
      (try! (nft-mint? geoledger-parcel new-id owner))
      (map-set parcel-metadata new-id {
        gps-coordinates: gps-coords,
        area-sq-meters: area,
        zoning-class: zoning
      })
      (var-set last-parcel-id new-id)
      (ok new-id)
    )
  )
)

;; Add a new valid zoning type.
(define-public (add-zoning-type (zoning (string-ascii 40)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-ADMIN) (err ERR-NOT-AUTHORIZED))
    (ok (map-set valid-zoning-types zoning true))
  )
)

;; --- Zoning Proposal and Voting Functions ---

;; Propose a change to a parcel's zoning classification.
;; Only the current owner of the parcel can create a proposal.
(define-public (propose-zoning-change (parcel-id uint) (new-zoning (string-ascii 40)))
  (let ((owner (unwrap! (nft-get-owner? geoledger-parcel parcel-id) (err ERR-PARCEL-NOT-FOUND))))
    (asserts! (is-eq tx-sender owner) (err ERR-PARCEL-OWNER-ONLY))
    (asserts! (default-to false (map-get? valid-zoning-types new-zoning)) (err ERR-INVALID-ZONING-TYPE))
    (let ((proposal-id (+ (var-get proposal-counter) u1)))
      (map-set proposals proposal-id {
        proposer: tx-sender,
        parcel-id: parcel-id,
        proposed-zoning: new-zoning,
        is-approved: false,
        votes-for: u0,
        votes-against: u0
      })
      (var-set proposal-counter proposal-id)
      (ok proposal-id)
    )
  )
)

;; Vote on a zoning change proposal.
(define-public (vote-on-proposal (proposal-id uint) (vote bool))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) (err ERR-PROPOSAL-NOT-FOUND))))
    (asserts! (not (get is-approved proposal)) (err ERR-VOTING-CLOSED))
    (asserts! (is-none (map-get? voter-registry {proposal-id: proposal-id, voter: tx-sender})) (err ERR-ALREADY-VOTED))

    (map-set voter-registry {proposal-id: proposal-id, voter: tx-sender} true)

    (if vote
      (map-set proposals proposal-id (merge proposal {votes-for: (+ (get votes-for proposal) u1)}))
      (map-set proposals proposal-id (merge proposal {votes-against: (+ (get votes-against proposal) u1)}))
    )
    (ok true)
  )
)

;; Finalize a proposal. Can be called by anyone after voting period.
;; In a real contract, this would have a time-based condition.
;; Here, we finalize based on a simple majority.
(define-public (finalize-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) (err ERR-PROPOSAL-NOT-FOUND))))
    (asserts! (not (get is-approved proposal)) (err ERR-VOTING-CLOSED))

    (if (> (get votes-for proposal) (get votes-against proposal))
      (let (
          (parcel-id (get parcel-id proposal))
          (metadata (unwrap! (map-get? parcel-metadata parcel-id) (err ERR-PARCEL-NOT-FOUND)))
        )
        (map-set parcel-metadata parcel-id (merge metadata {zoning-class: (get proposed-zoning proposal)}))
        (map-set proposals proposal-id (merge proposal {is-approved: true}))
        (print {event: "proposal-approved", parcel-id: parcel-id, proposal-id: proposal-id})
        (ok true)
      )
      (begin
        (map-set proposals proposal-id (merge proposal {is-approved: true})) ;; Mark as closed (rejected)
        (print {event: "proposal-rejected", proposal-id: proposal-id})
        (ok false)
      )
    )
  )
)

;; --- Read-Only Functions ---

;; Get the metadata for a specific parcel.
(define-read-only (get-parcel-metadata (parcel-id uint))
  (map-get? parcel-metadata parcel-id)
)

;; Get details for a specific zoning proposal.
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Check if a zoning type is valid.
(define-read-only (is-zoning-type-valid (zoning (string-ascii 40)))
  (is-some (map-get? valid-zoning-types zoning))
)

;; Get the total number of parcels registered.
(define-read-only (get-parcel-count)
  (var-get last-parcel-id)
)

;; Get the total number of proposals made.
(define-read-only (get-proposal-count)
  (var-get proposal-counter)
)

;; Check if a user has voted on a proposal.
(define-read-only (has-voted (proposal-id uint) (voter principal))
  (is-some (map-get? voter-registry {proposal-id: proposal-id, voter: voter}))
)