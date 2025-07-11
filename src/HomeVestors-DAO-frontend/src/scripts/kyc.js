import { CivicAuth } from "@civic/auth/vanillajs";
import { getCanister, getPrincipal } from "./Main";
import { Principal } from "@dfinity/principal";

let authClient = null;

const loginButton = document.getElementById("kycBtn1");
const loginButton2 = document.getElementById("kycBtn2");
const userOutput = document.getElementById("userOutput");

// ✅ Wire up the KYC buttons (runs on page load)
async function wireKyc() {
  if (!loginButton.dataset.kycWired) {
    loginButton.addEventListener("click", startKycFlow);
    loginButton.dataset.kycWired = "true";
  }

  if (!loginButton2.dataset.kycWired) {
    loginButton2.addEventListener("click", startKycFlow);
    loginButton2.dataset.kycWired = "true";
  }
}

// ✅ Starts Civic authentication flow (runs on button click)
async function startKycFlow() {
  console.log("🔵 Starting Civic KYC flow");

  // 🆔 Require Internet Identity login before starting Civic flow
  const principal = await getPrincipal();
  if (!principal || principal === "aaaaa-aa") {
    alert("Please log in with Internet Identity before starting KYC.");
    console.warn("❌ User is not logged in with Internet Identity");
    return;
  }

  try {
    authClient = await CivicAuth.create({
      clientId: "127acff0-7a04-4930-8d26-3e67b74ffa6b",
      displayMode: "redirect", // Mainnet-safe
      redirectUrl: "https://vf5in-lyaaa-aaaas-amlwa-cai.icp0.io/marketplace.html",
      scopes: ["openid", "profile", "email"]
    });

    // This triggers the redirect to Civic
    await authClient.startAuthentication();
  } catch (err) {
    console.error("❌ Failed to start Civic KYC flow:", err);
  }
}

// ✅ Handles restoring Civic session after redirect
async function restoreCivicSession() {
  try {
    authClient = await CivicAuth.create({
      clientId: "127acff0-7a04-4930-8d26-3e67b74ffa6b",
      displayMode: "redirect",
      redirectUrl: "https://vf5in-lyaaa-aaaas-amlwa-cai.icp0.io/marketplace.html",
      scopes: ["openid", "profile", "email"]
    });

    const civicUser = await authClient.getCurrentUser();

    if (civicUser) {
      console.log("✅ Civic user restored after redirect:", civicUser);
      

      // 🆔 Require Internet Identity login before backend update
      const principal = await getPrincipal();
      if (!principal || principal === "aaaaa-aa") {
        console.warn("❌ User is not logged in with Internet Identity");
        alert("Please log in to your account to complete KYC verification.");
        return;
      }

      console.log("✅ Logged in principal:", principal);

      // 📡 Update backend KYC state
      const backend = await getCanister("backend");
      await backend.verifyKYC(true);
      console.log("✅ Backend KYC updated for principal:", principal);

      // ✅ Hide KYC buttons
      loginButton.classList.add("hidden");
      loginButton2.classList.add("hidden");
    } else {
      console.log("ℹ️ No Civic session to restore");
    }
  } catch (err) {
    console.error("❌ Failed to restore Civic session:", err);
  }
}

// ✅ Checks backend KYC status and hides buttons if already verified
export async function maybeHideKycButtons() {
  console.log("🔍 Checking if user already KYC verified");
  try {
    const isVerified = await validateKYC();

    if (isVerified) {
      console.log("✅ User is already KYC verified");
      loginButton.classList.add("hidden");
      loginButton2.classList.add("hidden");
    }
  } catch (err) {
    console.error("❌ Error validating KYC:", err);
  }
}

// ✅ Checks backend for KYC state
async function validateKYC() {
  try {
    const principal = await getPrincipal();
    if (!principal || principal === "aaaaa-aa") {
      console.warn("⚠️ Anonymous principal detected. Skipping KYC check.");
      return false;
    }

    console.log("🆔 Validating KYC for principal:", principal);
    const account = { owner: Principal.fromText(principal), subaccount: [] };
    const backend = await getCanister("backend");

    return await backend.userVerified(account);
  } catch (e) {
    console.log("❌ Error verifying KYC with backend:", e);
    return false;
  }
}

// 🏁 Initialize logic on page load
document.addEventListener("DOMContentLoaded", async () => {
  await restoreCivicSession();
  await maybeHideKycButtons();
  await wireKyc();
});
