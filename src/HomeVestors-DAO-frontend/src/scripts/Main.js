import { Actor, HttpAgent } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import {maybeHideKycButtons} from "./kyc.js"

// 🔥 Import all IDLs
import { idlFactory as backendIdl } from "./backend.idl.js";
import { idlFactory as nftIdlFactory } from "./nft.did.js";
import { icrc1IdlFactory as tokenIdl } from "./icrc1Idl.did.js";

// 🛠 Canister mapping
const canisters = {
  backend: {
    id: "vq2za-kqaaa-aaaas-amlvq-cai",
    idl: backendIdl,
  },
  nft: {
    idl: nftIdlFactory, // ID will be passed at runtime
  },
  token: {
    tokens: {
      ICP: "ryjl3-tyaaa-aaaaa-aaaba-cai",
      CKUSDC: "xevnm-gaaaa-aaaar-qafnq-cai",
    },
    idl: tokenIdl, // Shared IDL for all tokens
  },
};

let agent = null;
let principal = null;
let actors = {}; // Cache of created actors

// 🟢 Create or reuse agent
async function getAgent() {
  if (agent) return agent;

  const authClient = await AuthClient.create();
  const isAuthenticated = await authClient.isAuthenticated();

  if (isAuthenticated) {
   // console.log("🔑 Authenticated user detected.");
    const identity = authClient.getIdentity();
    agent = new HttpAgent({ identity, host: "https://icp0.io" });
    principal = identity.getPrincipal().toText();
  } else {
   // console.log("🕵️ Anonymous session.");
    agent = new HttpAgent({ host: "https://icp0.io" });
    principal = null;
  }

  return agent;
}

// 🏗 Dynamic canister factory
export async function getCanister(type, canisterId = null) {
  const agent = await getAgent();

  if (type === "token") {
    // Check if token actors already cached
    if (actors.token) return actors.token;

    // Create both ICP and CKUSDC actors
    const ICP = Actor.createActor(canisters.token.idl, {
      agent,
      canisterId: canisters.token.tokens.ICP,
    });
    const CKUSDC = Actor.createActor(canisters.token.idl, {
      agent,
      canisterId: canisters.token.tokens.CKUSDC,
    });

    const tokenActors = { ICP, CKUSDC };
    actors.token = tokenActors; // Cache it
   // console.log("✅ Created actors for tokens (ICP & CKUSDC).");
    return tokenActors;
  }

  // For other types (backend / nft)
  const cacheKey = `${type}:${canisterId || canisters[type].id}`;
  if (actors[cacheKey]) return actors[cacheKey];

  const idl = canisters[type].idl;
  const id = canisterId || canisters[type].id;

  const actor = Actor.createActor(idl, { agent, canisterId: id });
  actors[cacheKey] = actor;
 // console.log(`✅ Created actor for ${type} (${id})`);
  return actor;
}

// 👤 Principal helper
export async function getPrincipal() {
  if (principal) return principal;

  const authClient = await AuthClient.create();
  const isAuthenticated = await authClient.isAuthenticated();

  if (isAuthenticated) {
    const identity = authClient.getIdentity();
    principal = identity.getPrincipal().toText();
   // console.log("✅ Principal:", principal);
  } else {
   // console.log("🕵️ Anonymous principal.");
    principal = null;
  }

  return principal;
}

// 🔑 Login & logout
export async function loginWithInternetIdentity() {
  const authClient = await AuthClient.create();

  await authClient.login({
    identityProvider: "https://identity.ic0.app/#authorize",
    onSuccess: async () => {
     // console.log("🔓 Login successful. Resetting state...");
      agent = null;
      actors = {}; // Clear cached actors
      principal = null;
    },
  });
}

export async function logout() {
  const authClient = await AuthClient.create();
  await authClient.logout();
 // console.log("🔒 Logged out.");
  agent = null;
  actors = {};
  principal = null;
}


export function wireConnect(connectBtnId, walletDisplayId) {
  const connectBtn = document.getElementById(connectBtnId);
  const walletDisplay = document.getElementById(walletDisplayId);

  if (!connectBtn || !walletDisplay) {
    console.error("❌ Could not find connect or wallet elements.");
    return;
  }

  // Helper to restore auth state
  async function restoreAuthState() {
    const authClient = await AuthClient.create();
    authClient.getIdentity(); // Force refresh
    const isAuthenticated = await authClient.isAuthenticated();

    if (isAuthenticated) {
    //  console.log("🔑 Restoring session...");
      const identity = authClient.getIdentity();
      agent = new HttpAgent({ identity, host: "https://icp0.io" });
      principal = identity.getPrincipal().toText();
    } 
    else {
      //console.log("🕵️ No active session.");
      agent = new HttpAgent({ host: "https://icp0.io" });
      principal = null;
    }
  }

  // Update UI based on auth state
  function updateUI() {
    if (principal) {
      connectBtn.classList.add("hidden");
      walletDisplay.classList.remove("hidden");
    } else {
      connectBtn.classList.remove("hidden");
      walletDisplay.classList.add("hidden");
    }
  }

  // Wire the connect button
  connectBtn.addEventListener("click", async () => {
    await loginWithInternetIdentity();
    await restoreAuthState();
    await  maybeHideKycButtons();
    updateUI();
  });

  // On page load, restore auth state & update UI
  (async () => {
  await restoreAuthState();
  updateUI();
})();
}
