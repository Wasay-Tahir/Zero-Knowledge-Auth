pragma circom 2.0.0;

include "poseidon.circom";

template PasswordAuth() {
    // private inputs
    signal input password;   // numeric representation or chunked
    signal input salt;
    // public inputs
    signal input commitment; // stored on server
    signal input nonce;      // server challenge (public)
    signal output out;       // challengeHash

    // Poseidon([salt, password])
    component h = Poseidon(2);
    h.inputs[0] <== salt;
    h.inputs[1] <== password;
    signal pwHash;
    pwHash <== h.out;

    // Poseidon([pwHash, nonce])
    component h2 = Poseidon(2);
    h2.inputs[0] <== pwHash;
    h2.inputs[1] <== nonce;
    signal challengeHash;
    challengeHash <== h2.out;

    // Enforce stored commitment equals pwHash
    commitment === pwHash;

    out <== challengeHash;
}

component main = PasswordAuth();
