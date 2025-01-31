;; NFT Lending Contract
;; Implements functionality for lending and renting NFTs with built-in payment handling

;; Define NFT trait
(define-trait nft-trait (
    (transfer (uint principal principal) (response bool uint))
    (get-owner (uint) (response principal uint))
    (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
))

(define-non-fungible-token rental-nft uint)

;; Constants for input validation
(define-constant MAX_RENTAL_PERIOD u52560) ;; Max rental period (approximately 1 year in blocks)
(define-constant MAX_RENTAL_FEE u1000000000) ;; Max rental fee (1 billion - adjust as needed)
(define-constant ERR-INVALID-NFT (err u100))
(define-constant ERR-NFT-NOT-FOUND (err u101))
(define-constant ERR-INVALID-PARAMS (err u102))
(define-constant ERR-NOT-OWNER (err u103))
(define-constant ERR-ALREADY-RENTED (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))

(define-map rental-agreements
  { nft-id: uint }
  { renter: (optional principal), 
    lessor: principal, 
    rental-end: uint, 
    rental-fee: uint, 
    rental-period: uint })

(define-map balances
  { owner: principal }
  { balance: uint })

;; Helper function to validate NFT ID
(define-private (validate-nft-id (id uint))
  (and 
    (< id u1000000) ;; Arbitrary max NFT ID
    (is-some (nft-get-owner? rental-nft id))))

;; Helper function to validate rental parameters
(define-private (validate-rental-params (fee uint) (period uint))
  (and 
    (> fee u0)
    (<= fee MAX_RENTAL_FEE)
    (> period u0)
    (<= period MAX_RENTAL_PERIOD)))

(define-read-only (get-nft-owner (nft-id uint))
  (begin
    (asserts! (validate-nft-id nft-id) ERR-INVALID-NFT)
    (ok (unwrap! (nft-get-owner? rental-nft nft-id) ERR-NFT-NOT-FOUND))))

;; The `mint-nft` function mints a new NFT with the given ID and assigns it to the transaction sender.
(define-public (mint-nft (id uint))
  (begin
    (asserts! (validate-nft-id id) ERR-INVALID-NFT)
    (try! (nft-mint? rental-nft id tx-sender))
    (ok u1)))

;; Function to list an NFT for rent by specifying the NFT ID, rental fee, and rental period
(define-public (list-nft-for-rent (nft-id uint) (fee uint) (rental-period uint))
  (begin
    (asserts! (validate-nft-id nft-id) ERR-INVALID-NFT)
    (asserts! (validate-rental-params fee rental-period) ERR-INVALID-PARAMS)
    (asserts! (is-eq tx-sender (unwrap! (get-nft-owner nft-id) ERR-NFT-NOT-FOUND)) 
              ERR-NOT-OWNER)
    (map-insert rental-agreements
      { nft-id: nft-id }
      { renter: none, 
        lessor: tx-sender, 
        rental-end: u0, 
        rental-fee: fee, 
        rental-period: rental-period })
    (ok u1)))

;; Function to rent an NFT by specifying the NFT ID and paying the rental fee
(define-public (rent-nft (nft-id uint))
  (begin
    (asserts! (validate-nft-id nft-id) ERR-INVALID-NFT)
    (let (
          (agreement (unwrap! (map-get? rental-agreements { nft-id: nft-id }) 
                             ERR-NFT-NOT-FOUND))
          (renter-balance (unwrap! (map-get? balances { owner: tx-sender }) 
                                  ERR-INSUFFICIENT-BALANCE))
        )
      (begin
        (asserts! (is-none (get renter agreement)) ERR-ALREADY-RENTED)
        (asserts! (>= (get balance renter-balance) (get rental-fee agreement)) 
                  ERR-INSUFFICIENT-BALANCE)
        (map-set rental-agreements
          { nft-id: nft-id }
          { renter: (some tx-sender), 
            lessor: (get lessor agreement), 
            rental-end: (+ stacks-block-height (get rental-period agreement)), 
            rental-fee: (get rental-fee agreement), 
            rental-period: (get rental-period agreement) })
        (map-set balances
          { owner: tx-sender }
          { balance: (- (get balance renter-balance) (get rental-fee agreement)) })
        (ok u1)))))