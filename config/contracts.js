module.exports = {
  default: {
    dappConnection: [
      "$EMBARK",
      "$WEB3",  
      "ws://localhost:8546",
      "http://localhost:8545"
    ],
    gas: "auto",
    deploy: {

    }
  },
  development: {},
  privatenet: {},
};
