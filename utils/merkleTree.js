const { keccak256, bufferToHex } = require('ethereumjs-util');

class MerkleTree {
  constructor(elements) {
    // Filter empty strings and hash elements
    this.elements = elements.filter(el => el).map(el => keccak256(el));
    
    // Deduplicate elements
    this.elements = this.bufDedup(this.elements);
    // Sort elements
    this.elements.sort(Buffer.compare);
    // Create layers
    this.layers = this.getLayers(this.elements);
  }

  getProofIds(els,proofs, log=false) {
    log && console.log("proofs", this.bufArrToHex(proofs))
    
    let ids = els.map((el) => Math.floor(this.bufIndexOf(el, this.elements) / 2)).filter((value, index, self) => self.indexOf(value) === index).sort((a,b) => a == b ? 0 : a > b ? 1 : -1);
    
    if (!ids.every((idx) => idx != -1)) {
      throw new Error("Element does not exist in Merkle tree");
    }

    const hashOffset = proofs.length;
    var hashCount = 0;
    var proofCount = 0;

    const tested = [];
    const usedIds = []
    for (let index = 1; index < this.layers.length; index++) {
      const layer = this.layers[index];
      log && console.log("layer", this.bufArrToHex(layer));
      ids = ids.reduce((ids, idx) => {
        const pairElement = this.getPairElement(idx, layer);
        const skipped = !pairElement || tested.includes(layer[idx]);
        if(!skipped) {
          const proofUsed = proofs.includes(layer[idx]) || proofs.includes(pairElement);
          if(proofUsed) {
            if (pairElement.compare(layer[idx]) < 0){
              usedIds.push(proofCount++);
              usedIds.push(hashOffset+hashCount++);
            } else {
              usedIds.push(hashOffset+hashCount++);
              usedIds.push(proofCount++);
            }
          } else {
            let id1;
            let id2;
            if (pairElement.compare(layer[idx]) < 0){
              id2 = hashOffset+hashCount++;
              id1 = hashOffset+hashCount++;
            } else {
              id1 = hashOffset+hashCount++;
              id2 = hashOffset+hashCount++;
            }
            usedIds.push(id1)
            usedIds.push(id2)
          }
          log && console.log("pair ", proofUsed, bufferToHex(layer[idx]), bufferToHex(pairElement));
          tested.push(layer[idx]);
          tested.push(pairElement);
        } else {
          log && console.log("element skipped", bufferToHex(layer[idx]));
        }
        ids.push(Math.floor(idx / 2));  
        return ids;
      }, [])
    }
    return usedIds;
  }

  getProofFlags(els,proofs, log=false) {
    log && console.log("proofs", this.bufArrToHex(proofs))
    let ids = els.map((el) => Math.floor(this.bufIndexOf(el, this.elements) / 2)).filter((value, index, self) => self.indexOf(value) === index).sort((a,b) => a == b ? 0 : a > b ? 1 : -1);
    if (!ids.every((idx) => idx != -1)) {
      throw new Error("Element does not exist in Merkle tree");
    }

    const tested = [];
    const flags = []
    for (let index = 1; index < this.layers.length; index++) {
      const layer = this.layers[index];
      ids = ids.reduce((ids, idx) => {
        const skipped = tested.includes(layer[idx]);
        if(!skipped) {
          const pairElement = this.getPairElement(idx, layer);
          const proofUsed = proofs.includes(layer[idx]) || proofs.includes(pairElement);
          flags.push(proofUsed);
          log && console.log("pair ", proofUsed, bufferToHex(layer[idx]), bufferToHex(pairElement));
          tested.push(layer[idx]);
          tested.push(pairElement);
        } else {
          log && console.log("element skipped", bufferToHex(layer[idx]));
        }
        ids.push(Math.floor(idx / 2));  
        return ids;
      }, [])
    }
    return flags;
  }

  getPairs(els) {
    let ids = els.map((el) => this.bufIndexOf(el, this.elements));
    if (!ids.every((idx) => idx != -1)) {
      throw new Error("Element does not exist in Merkle tree");
    }
    
    const pairs = [];
    for (let j = 0; j < ids.length; j++) {
      pairs.push(this.layers[0][ids[j]]);
      pairs.push(this.getPairElement(ids[j], this.layers[0]));  
    }
    return this.bufDedup(pairs).sort(Buffer.compare);
  }

  getMultiProof(els, log=false) {
    let ids = els.map((el) => Math.floor(this.bufIndexOf(el, this.elements) / 2)).filter((value, index, self) => self.indexOf(value) === index).sort((a,b) => a == b ? 0 : a > b ? 1 : -1);
    if (!ids.every((idx) => idx != -1)) {
      throw new Error("Element does not exist in Merkle tree");
    }
    
    const hashes = [];
    const proof = [];
    var nextIds = [];


    for (let index = 1; index < this.layers.length; index++) {
      const layer = this.layers[index];
      for (let j = 0; j < ids.length; j++) {
        const idx = ids[j];
        const pairElement = this.getPairElement(idx, layer);
        
        hashes.push(layer[idx]);
        pairElement && proof.push(pairElement)
  
        nextIds.push(Math.floor(idx / 2));  
      }
      ids = nextIds.filter((value, index, self) => self.indexOf(value) === index);
      nextIds = [];
    }

    log && console.log("proof", this.bufArrToHex(proof));
    log && console.log("hashes", this.bufArrToHex(hashes));
    return proof.filter((value,index, self) => !hashes.includes(value));
  }

  getHexMultiProof(els) {
    const multiProof = this.getMultiProof(els);

    return this.bufArrToHex(multiProof);
  }

  getLayers(elements) {
    if (elements.length == 0) {
      return [[""]];
    }

    const layers = [];
    layers.push(elements);

    // Get next layer until we reach the root
    while (layers[layers.length - 1].length > 1) {
      layers.push(this.getNextLayer(layers[layers.length - 1]));
    }

    return layers;
  }

  getNextLayer(elements) {
    return elements.reduce((layer, el, idx, arr) => {
      if (idx % 2 === 0) {
        // Hash the current element with its pair element
        layer.push(this.combinedHash(el, arr[idx + 1]));
      }

      return layer;
    }, []);
  }

  combinedHash(first, second) {
    if (!first) { return second; }
    if (!second) { return first; }

    return keccak256(this.sortAndConcat(first, second));
  }

  getRoot() {
    return this.layers[this.layers.length - 1][0];
  }

  getHexRoot() {
    return bufferToHex(this.getRoot());
  }

  getProof(el) {
    let idx = this.bufIndexOf(el, this.elements);

    if (idx === -1) {
      throw new Error("Element does not exist in Merkle tree");
    }

    return this.layers.reduce((proof, layer) => {
      const pairElement = this.getPairElement(idx, layer);

      if (pairElement) {
        proof.push(pairElement);
      }

      idx = Math.floor(idx / 2);

      return proof;
    }, []);
  }


  getHexProof(el) {
    const proof = this.getProof(el);

    return this.bufArrToHex(proof);
  }

  getPairElement(idx, layer) {
    const pairIdx = idx % 2 === 0 ? idx + 1 : idx - 1;

    if (pairIdx < layer.length) {
      return layer[pairIdx];
    } else {
      return null;
    }
  }

  bufIndexOf(el, arr) {
    let hash;

    // Convert element to 32 byte hash if it is not one already
    if (el.length !== 32 || !Buffer.isBuffer(el)) {
      hash = keccak256(el);
    } else {
      hash = el;
    }

    for (let i = 0; i < arr.length; i++) {
      if (hash.equals(arr[i])) {
        return i;
      }
    }

    return -1;
  }

  bufDedup(elements) {
    return elements.filter((el, idx) => {
      return this.bufIndexOf(el, elements) === idx;
    });
  }

  bufArrToHex(arr) {
    if (arr.some(el => !Buffer.isBuffer(el))) {
      throw new Error("Array is not an array of buffers");
    }
    
    return arr.map(el => '0x' + el.toString('hex'));
  }

  sortAndConcat(...args) {
    return Buffer.concat([...args].sort(Buffer.compare));
  }
}

exports.MerkleTree = MerkleTree;