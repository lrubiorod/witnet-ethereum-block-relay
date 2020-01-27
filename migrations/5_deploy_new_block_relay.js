var NewBlockRelay = artifacts.require("NewBlockRelay")
var WitnetBridgeInterface = artifacts.require("WitnetBridgeInterface")

module.exports = function (deployer, network) {
  console.log(`> Migrating NewBlockRelay into ${network} network`)
  deployer.deploy(NewBlockRelay, 1568559600, 90, 0, WitnetBridgeInterface.address)
}