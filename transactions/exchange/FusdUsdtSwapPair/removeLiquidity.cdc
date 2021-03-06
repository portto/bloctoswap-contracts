import FungibleToken from 0xFUNGIBLETOKENADDRESS
import FUSD from 0xFUSDADDRESS
import TeleportedTetherToken from 0xTELEPORTEDUSDTADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction(amount: UFix64, token1Amount: UFix64, token2Amount: UFix64) {
  // The Vault reference for liquidity tokens that are being transferred
  let liquidityTokenRef: &FusdUsdtSwapPair.Vault

  // The proxy holder reference for access control
  let swapProxyRef: &FusdUsdtSwapPair.SwapProxy

  // The Vault references to receive the liquidity tokens
  let fusdVaultRef: &FUSD.Vault
  let tetherVaultRef: &TeleportedTetherToken.Vault

  prepare(signer: AuthAccount) {
    assert(amount == token1Amount + token2Amount: "Incosistent liquidtiy amounts")

    self.liquidityTokenRef = signer.borrow<&FusdUsdtSwapPair.Vault>(from: FusdUsdtSwapPair.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")

    self.swapProxyRef = proxyHolder.borrow<&FusdUsdtSwapPair.SwapProxy>(from: /storage/fusdUsdtSwapProxy)
      ?? panic("Could not borrow a reference to proxy holder")

    self.fusdVaultRef = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
      ?? panic("Could not borrow a reference to Vault")

    self.tetherVaultRef = signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw liquidity provider tokens
    let liquidityTokenVault <- self.liquidityTokenRef.withdraw(amount: amount) as! @FusdUsdtSwapPair.Vault

    // Take back liquidity
    let tokenBundle <- self.swapProxyRef.removeLiquidity(from: <-liquidityTokenVault, token1Amount: token1Amount, token2Amount: token2Amount)

    // Deposit liquidity tokens
    self.fusdVaultRef.deposit(from: <- tokenBundle.withdrawToken1())
    self.tetherVaultRef.deposit(from: <- tokenBundle.withdrawToken2())

    destroy tokenBundle
  }
}
