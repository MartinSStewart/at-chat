/*

import Elm.Kernel.Scheduler exposing (binding, succeed, fail)
import Elm.Kernel.Utils exposing (Tuple0)
import Elm.Kernel.Json exposing (wrap, unwrap)
import Elm.Kernel.List exposing (toArray)
import Crypto exposing (Sha256, Sha384, Sha512, P256, P384, P521, AesLength128, AesLength192, AesLength256, CanBeExtracted, CannotBeExtracted, SecureContext, Key, PublicKey, PrivateKey, KeyNotExportable, ImportRsaKeyError, ImportAesKeyError, ImportEcKeyError, ImportHmacKeyError, RsaOaepDecryptionError, RsaPssSigningError, AesCtrEncryptionError, AesCtrDecryptionError, AesCbcEncryptionError, AesCbcDecryptionError, AesGcmEncryptionError, AesGcmDecryptionError)
import Maybe exposing (Just, Nothing)

*/

// This is a port of Gren.Kernel.Crypto from gren-lang/core 7.4.2. See src/Crypto.elm.
//
// Unlike the Gren original this never calls require("crypto"): globalThis.crypto covers
// browsers and Node 19 and up, and a bare require would break bundling for the browser.
var _Crypto_impl =
  typeof globalThis !== "undefined" && globalThis.crypto ? globalThis.crypto : null;

// Web Crypto is missing entirely, which getSecureContext reports as a failure. Anything
// else that got called anyway should say why it cannot work rather than read a field of
// null.
function _Crypto_subtle() {
  if (!_Crypto_impl || !_Crypto_impl.subtle) {
    throw new Error(
      "Elm.Kernel.Crypto: the Web Crypto API is not available. Check Crypto.getSecureContext before calling anything else."
    );
  }
  return _Crypto_impl.subtle;
}

// An error the Elm type has no way to represent, so there is nothing to hand back to the
// caller. Log it and let the rejection surface rather than lose it.
function _Crypto_reportImpossible(operation, err) {
  console.error("Elm.Kernel.Crypto: " + operation + " failed unexpectedly.", err);
  throw err;
}

// Json

var _Crypto_wrapJson = function (value) {
  return __Json_wrap(value);
};

var _Crypto_unwrapJson = function (value) {
  return __Json_unwrap(value);
};

// Utils

var _Crypto_hashFromString = function (hash) {
  switch (hash) {
    case "SHA-256":
      return __Crypto_Sha256;
    case "SHA-384":
      return __Crypto_Sha384;
    default:
      return __Crypto_Sha512;
  }
};

var _Crypto_extractableFromBool = function (extractable) {
  if (extractable) {
    return __Crypto_CanBeExtracted;
  } else {
    return __Crypto_CannotBeExtracted;
  }
};

// Key Construction
//
// The records built here have to match the Elm types in src/Crypto.elm field for field,
// so RsaKeyParams gets no publicExponent even though the CryptoKey carries one.

var _Crypto_constructRsaKey = function (key) {
  return __Crypto_Key({
    __$key: key,
    __$data: {
      __$modulusLength: key.algorithm.modulusLength,
      __$hash: _Crypto_hashFromString(key.algorithm.hash.name),
      __$extractable: _Crypto_extractableFromBool(key.extractable),
    },
  });
};

var _Crypto_constructHmacKey = function (key) {
  return __Crypto_Key({
    __$key: key,
    __$data: {
      __$length: key.algorithm.length
        ? __Maybe_Just(key.algorithm.length)
        : __Maybe_Nothing,
      __$hash: _Crypto_hashFromString(key.algorithm.hash.name),
      __$extractable: _Crypto_extractableFromBool(key.extractable),
    },
  });
};

var _Crypto_aesLengthFromInt = function (length) {
  switch (length) {
    case 128:
      return __Crypto_AesLength128;
    case 192:
      return __Crypto_AesLength192;
    default:
      return __Crypto_AesLength256;
  }
};

var _Crypto_constructAesKey = function (key) {
  return __Crypto_Key({
    __$key: key,
    __$data: {
      __$length: _Crypto_aesLengthFromInt(key.algorithm.length),
      __$extractable: _Crypto_extractableFromBool(key.extractable),
    },
  });
};

var _Crypto_ecNamedCurveFromString = function (namedCurve) {
  switch (namedCurve) {
    case "P-256":
      return __Crypto_P256;
    case "P-384":
      return __Crypto_P384;
    default:
      return __Crypto_P521;
  }
};

var _Crypto_constructEcKey = function (key) {
  return __Crypto_Key({
    __$key: key,
    __$data: {
      __$namedCurve: _Crypto_ecNamedCurveFromString(key.algorithm.namedCurve),
      __$extractable: _Crypto_extractableFromBool(key.extractable),
    },
  });
};

// Random

var _Crypto_randomUUID = __Scheduler_binding(function (callback) {
  return callback(__Scheduler_succeed(_Crypto_impl.randomUUID()));
});

var _Crypto_getRandomValues = F2(function (arrayLength, valueType) {
  return __Scheduler_binding(function (callback) {
    var array;
    switch (valueType) {
      case "int8":
        array = new Int8Array(arrayLength);
        break;
      case "uint8":
        array = new Uint8Array(arrayLength);
        break;
      case "int16":
        array = new Int16Array(arrayLength);
        break;
      case "uint16":
        array = new Uint16Array(arrayLength);
        break;
      case "int32":
        array = new Int32Array(arrayLength);
        break;
      case "uint32":
        array = new Uint32Array(arrayLength);
        break;
      default:
        array = new Int8Array(0);
        break;
    }
    var randomValues = _Crypto_impl.getRandomValues(array);
    return callback(__Scheduler_succeed(new DataView(randomValues.buffer)));
  });
});

// Context

var _Crypto_getContext = __Scheduler_binding(function (callback) {
  if (_Crypto_impl && _Crypto_impl.subtle) {
    return callback(__Scheduler_succeed(__Crypto_SecureContext));
  }
  return callback(__Scheduler_fail(__Utils_Tuple0));
});

// Generate keys

var _Crypto_generateRsaKey = F6(function (
  name,
  modulusLength,
  publicExponent,
  hash,
  extractable,
  permissions
) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: name,
      modulusLength: modulusLength,
      publicExponent: new Uint8Array(__List_toArray(publicExponent)),
      hash: hash,
    };
    _Crypto_subtle()
      .generateKey(algorithm, extractable, __List_toArray(permissions))
      .then(function (key) {
        return callback(
          __Scheduler_succeed({
            __$publicKey: __Crypto_PublicKey(_Crypto_constructRsaKey(key.publicKey)),
            __$privateKey: __Crypto_PrivateKey(_Crypto_constructRsaKey(key.privateKey)),
          })
        );
      })
      .catch(function (err) {
        _Crypto_reportImpossible("generating an RSA key", err);
      });
  });
});

var _Crypto_generateAesKey = F4(function (name, length, extractable, permissions) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: name,
      length: length,
    };
    _Crypto_subtle()
      .generateKey(algorithm, extractable, __List_toArray(permissions))
      .then(function (key) {
        return callback(__Scheduler_succeed(_Crypto_constructAesKey(key)));
      })
      .catch(function (err) {
        _Crypto_reportImpossible("generating an AES key", err);
      });
  });
});

var _Crypto_generateEcKey = F4(function (name, namedCurve, extractable, permissions) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: name,
      namedCurve: namedCurve,
    };
    _Crypto_subtle()
      .generateKey(algorithm, extractable, __List_toArray(permissions))
      .then(function (key) {
        return callback(
          __Scheduler_succeed({
            __$publicKey: __Crypto_PublicKey(_Crypto_constructEcKey(key.publicKey)),
            __$privateKey: __Crypto_PrivateKey(_Crypto_constructEcKey(key.privateKey)),
          })
        );
      })
      .catch(function (err) {
        _Crypto_reportImpossible("generating an EC key", err);
      });
  });
});

var _Crypto_generateHmacKey = F5(function (
  name,
  hash,
  length,
  extractable,
  permissions
) {
  return __Scheduler_binding(function (callback) {
    var algorithm;
    if (length === "") {
      algorithm = {
        name: name,
        hash: hash,
      };
    } else {
      algorithm = {
        name: name,
        hash: hash,
        length: length,
      };
    }
    _Crypto_subtle()
      .generateKey(algorithm, extractable, __List_toArray(permissions))
      .then(function (key) {
        return callback(__Scheduler_succeed(_Crypto_constructHmacKey(key)));
      })
      .catch(function (err) {
        _Crypto_reportImpossible("generating an HMAC key", err);
      });
  });
});

// Export key

var _Crypto_exportKey = F2(function (format, key) {
  return __Scheduler_binding(function (callback) {
    _Crypto_subtle()
      .exportKey(format, key)
      .then(function (res) {
        switch (format) {
          case "jwk":
            return callback(__Scheduler_succeed(res));

          default:
            return callback(__Scheduler_succeed(new DataView(res)));
        }
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_KeyNotExportable));
      });
  });
});

// Import keys

var _Crypto_importRsaKey = F7(function (
  wrapper,
  format,
  keyData,
  algorithm,
  hash,
  extractable,
  keyUsages
) {
  return __Scheduler_binding(function (callback) {
    _Crypto_subtle()
      .importKey(
        format,
        keyData,
        { name: algorithm, hash: hash },
        extractable,
        __List_toArray(keyUsages)
      )
      .then(function (key) {
        switch (wrapper) {
          case "public":
            return callback(
              __Scheduler_succeed(__Crypto_PublicKey(_Crypto_constructRsaKey(key)))
            );
          case "private":
            return callback(
              __Scheduler_succeed(__Crypto_PrivateKey(_Crypto_constructRsaKey(key)))
            );
          default:
            return callback(__Scheduler_fail(__Crypto_ImportRsaKeyError));
        }
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_ImportRsaKeyError));
      });
  });
});

var _Crypto_importAesKey = F5(function (
  format,
  keyData,
  algorithm,
  extractable,
  keyUsages
) {
  return __Scheduler_binding(function (callback) {
    _Crypto_subtle()
      .importKey(
        format,
        keyData,
        { name: algorithm },
        extractable,
        __List_toArray(keyUsages)
      )
      .then(function (key) {
        return callback(__Scheduler_succeed(_Crypto_constructAesKey(key)));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_ImportAesKeyError));
      });
  });
});

var _Crypto_importEcKey = F7(function (
  wrapper,
  format,
  keyData,
  algorithm,
  namedCurve,
  extractable,
  keyUsages
) {
  return __Scheduler_binding(function (callback) {
    _Crypto_subtle()
      .importKey(
        format,
        keyData,
        { name: algorithm, namedCurve: namedCurve },
        extractable,
        __List_toArray(keyUsages)
      )
      .then(function (key) {
        switch (wrapper) {
          case "public":
            return callback(
              __Scheduler_succeed(__Crypto_PublicKey(_Crypto_constructEcKey(key)))
            );
          case "private":
            return callback(
              __Scheduler_succeed(__Crypto_PrivateKey(_Crypto_constructEcKey(key)))
            );
          default:
            return callback(__Scheduler_fail(__Crypto_ImportEcKeyError));
        }
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_ImportEcKeyError));
      });
  });
});

var _Crypto_importHmacKey = F7(function (
  format,
  keyData,
  passedAlgorithm,
  hash,
  length,
  extractable,
  keyUsages
) {
  return __Scheduler_binding(function (callback) {
    var algorithm;
    if (length === "") {
      algorithm = {
        name: passedAlgorithm,
        hash: hash,
      };
    } else {
      algorithm = {
        name: passedAlgorithm,
        hash: hash,
        length: length,
      };
    }
    _Crypto_subtle()
      .importKey(format, keyData, algorithm, extractable, __List_toArray(keyUsages))
      .then(function (key) {
        return callback(__Scheduler_succeed(_Crypto_constructHmacKey(key)));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_ImportHmacKeyError));
      });
  });
});

// Reading a key back off a port
//
// A CryptoKey that has been through structured clone (IndexedDB, postMessage) is not the
// same class as the one this realm sees, so recognise it by shape instead of instanceof.

function _Crypto_isCryptoKey(key, algorithm, keyType) {
  return (
    key !== null &&
    typeof key === "object" &&
    key.type === keyType &&
    typeof key.extractable === "boolean" &&
    key.algorithm !== null &&
    typeof key.algorithm === "object" &&
    key.algorithm.name === algorithm
  );
}

function _Crypto_constructKey(key) {
  switch (key.algorithm.name) {
    case "RSA-OAEP":
    case "RSA-PSS":
    case "RSASSA-PKCS1-v1_5":
      return _Crypto_constructRsaKey(key);
    case "AES-CTR":
    case "AES-CBC":
    case "AES-GCM":
      return _Crypto_constructAesKey(key);
    case "ECDSA":
    case "ECDH":
      return _Crypto_constructEcKey(key);
    case "HMAC":
      return _Crypto_constructHmacKey(key);
    default:
      return null;
  }
}

var _Crypto_decodeSecretKey = F2(function (algorithm, value) {
  var key = __Json_unwrap(value);
  if (!_Crypto_isCryptoKey(key, algorithm, "secret")) {
    return __Maybe_Nothing;
  }
  var constructed = _Crypto_constructKey(key);
  return constructed === null ? __Maybe_Nothing : __Maybe_Just(constructed);
});

var _Crypto_decodePublicKey = F2(function (algorithm, value) {
  var key = __Json_unwrap(value);
  if (!_Crypto_isCryptoKey(key, algorithm, "public")) {
    return __Maybe_Nothing;
  }
  var constructed = _Crypto_constructKey(key);
  return constructed === null
    ? __Maybe_Nothing
    : __Maybe_Just(__Crypto_PublicKey(constructed));
});

var _Crypto_decodePrivateKey = F2(function (algorithm, value) {
  var key = __Json_unwrap(value);
  if (!_Crypto_isCryptoKey(key, algorithm, "private")) {
    return __Maybe_Nothing;
  }
  var constructed = _Crypto_constructKey(key);
  return constructed === null
    ? __Maybe_Nothing
    : __Maybe_Just(__Crypto_PrivateKey(constructed));
});

// Encryption

var _Crypto_encryptWithRsaOaep = F3(function (label, key, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm;
    if (label === "") {
      algorithm = {
        name: "RSA-OAEP",
      };
    } else {
      algorithm = {
        name: "RSA-OAEP",
        label: label,
      };
    }
    _Crypto_subtle()
      .encrypt(algorithm, key, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function (err) {
        _Crypto_reportImpossible("encrypting with RSA-OAEP", err);
      });
  });
});

var _Crypto_encryptWithAesCtr = F4(function (counter, length, key, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "AES-CTR",
      counter: counter,
      length: length,
    };
    _Crypto_subtle()
      .encrypt(algorithm, key, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_AesCtrEncryptionError));
      });
  });
});

var _Crypto_encryptWithAesCbc = F3(function (iv, key, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "AES-CBC",
      iv: iv,
    };
    _Crypto_subtle()
      .encrypt(algorithm, key, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_AesCbcEncryptionError));
      });
  });
});

var _Crypto_encryptWithAesGcm = F5(function (
  iv,
  additionalData,
  tagLength,
  key,
  bytes
) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "AES-GCM",
      iv: iv,
    };
    if (additionalData !== "") {
      algorithm.additionalData = additionalData;
    }
    if (tagLength !== "") {
      algorithm.tagLength = tagLength;
    }
    _Crypto_subtle()
      .encrypt(algorithm, key, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_AesGcmEncryptionError));
      });
  });
});

// Decrypt

var _Crypto_decryptWithRsaOaep = F3(function (label, key, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm;
    if (label === "") {
      algorithm = {
        name: "RSA-OAEP",
      };
    } else {
      algorithm = {
        name: "RSA-OAEP",
        label: label,
      };
    }
    _Crypto_subtle()
      .decrypt(algorithm, key, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_RsaOaepDecryptionError));
      });
  });
});

var _Crypto_decryptWithAesCtr = F4(function (counter, length, key, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "AES-CTR",
      counter: counter,
      length: length,
    };
    _Crypto_subtle()
      .decrypt(algorithm, key, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_AesCtrDecryptionError));
      });
  });
});

var _Crypto_decryptWithAesCbc = F3(function (iv, key, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "AES-CBC",
      iv: iv,
    };
    _Crypto_subtle()
      .decrypt(algorithm, key, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_AesCbcDecryptionError));
      });
  });
});

var _Crypto_decryptWithAesGcm = F5(function (
  iv,
  additionalData,
  tagLength,
  key,
  bytes
) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "AES-GCM",
      iv: iv,
    };
    if (additionalData !== "") {
      algorithm.additionalData = additionalData;
    }
    if (tagLength !== "") {
      algorithm.tagLength = tagLength;
    }
    _Crypto_subtle()
      // Passing a DataView for the encrypted bytes does not work on node, so hand it a
      // Uint8Array over the same memory, which works on node and in the browser.
      .decrypt(
        algorithm,
        key,
        new Uint8Array(bytes.buffer, bytes.byteOffset, bytes.byteLength)
      )
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_AesGcmDecryptionError));
      });
  });
});

// Signing

var _Crypto_signWithRsaSsaPkcs1V1_5 = F2(function (key, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "RSASSA-PKCS1-v1_5",
    };
    _Crypto_subtle()
      .sign(algorithm, key, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function (err) {
        _Crypto_reportImpossible("signing with RSASSA-PKCS1-v1_5", err);
      });
  });
});

var _Crypto_signWithRsaPss = F3(function (saltLength, key, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "RSA-PSS",
      saltLength: saltLength,
    };
    _Crypto_subtle()
      .sign(algorithm, key, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Crypto_RsaPssSigningError));
      });
  });
});

var _Crypto_signWithEcdsa = F3(function (hash, key, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "ECDSA",
      hash: hash,
    };
    _Crypto_subtle()
      .sign(algorithm, key, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function (err) {
        _Crypto_reportImpossible("signing with ECDSA", err);
      });
  });
});

var _Crypto_signWithHmac = F2(function (key, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "HMAC",
    };
    _Crypto_subtle()
      .sign(algorithm, key, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function (err) {
        _Crypto_reportImpossible("signing with HMAC", err);
      });
  });
});

// Verify

var _Crypto_verifyWithRsaSsaPkcs1V1_5 = F3(function (key, signature, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "RSASSA-PKCS1-v1_5",
    };
    _Crypto_subtle()
      .verify(algorithm, key, signature, bytes)
      .then(function (res) {
        if (res) {
          return callback(__Scheduler_succeed(bytes));
        }
        return callback(__Scheduler_fail(__Utils_Tuple0));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Utils_Tuple0));
      });
  });
});

var _Crypto_verifyWithRsaPss = F4(function (saltLength, key, signature, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "RSA-PSS",
      saltLength: saltLength,
    };
    _Crypto_subtle()
      .verify(algorithm, key, signature, bytes)
      .then(function (res) {
        if (res) {
          return callback(__Scheduler_succeed(bytes));
        }
        return callback(__Scheduler_fail(__Utils_Tuple0));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Utils_Tuple0));
      });
  });
});

var _Crypto_verifyWithEcdsa = F4(function (hash, key, signature, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "ECDSA",
      hash: hash,
    };
    _Crypto_subtle()
      .verify(algorithm, key, signature, bytes)
      .then(function (res) {
        if (res) {
          return callback(__Scheduler_succeed(bytes));
        }
        return callback(__Scheduler_fail(__Utils_Tuple0));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Utils_Tuple0));
      });
  });
});

var _Crypto_verifyWithHmac = F3(function (key, signature, bytes) {
  return __Scheduler_binding(function (callback) {
    var algorithm = {
      name: "HMAC",
    };
    _Crypto_subtle()
      .verify(algorithm, key, signature, bytes)
      .then(function (res) {
        if (res) {
          return callback(__Scheduler_succeed(bytes));
        }
        return callback(__Scheduler_fail(__Utils_Tuple0));
      })
      .catch(function () {
        return callback(__Scheduler_fail(__Utils_Tuple0));
      });
  });
});

// Digest

var _Crypto_digest = F2(function (algorithm, bytes) {
  return __Scheduler_binding(function (callback) {
    _Crypto_subtle()
      .digest(algorithm, bytes)
      .then(function (res) {
        return callback(__Scheduler_succeed(new DataView(res)));
      })
      .catch(function (err) {
        _Crypto_reportImpossible("digesting some bytes", err);
      });
  });
});
