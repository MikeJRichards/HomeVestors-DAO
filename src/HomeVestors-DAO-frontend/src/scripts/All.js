import { getCanister, getPrincipal, logout} from "./Main.js";
import { Principal } from "@dfinity/principal";

export function setupModal(openBtnId, modalId, closeBtnId) {
    const openBtn = document.getElementById(openBtnId);
    const modal = document.getElementById(modalId);
    const closeBtn = document.getElementById(closeBtnId);

    if (!openBtn || !modal || !closeBtn) {
      console.error("Modal setup error:", { openBtnId, modalId, closeBtnId });
      return;
    }

    // Open modal
    openBtn.addEventListener("click", () => {
      modal.classList.remove("hidden");
    });

    // Close modal
    closeBtn.addEventListener("click", () => {
      modal.classList.add("hidden");
    });

    // Optional: Close when clicking outside modal content
    window.addEventListener("click", (event) => {
      if (event.target === modal) {
        modal.classList.add("hidden");
      }
    });
  }

  export function setupToggle(openCloseButtonId, toggleElementId) {
    const Button = document.getElementById(openCloseButtonId);
    const element = document.getElementById(toggleElementId);

    if (!Button || !element) {
      console.error("toggle setup error:", { openCloseButtonId, toggleElementId});
      return;
    }

    // Open modal
    Button.addEventListener("click", () => {
      element.classList.toggle("hidden");
    });
  }

export function currency(number){
  let n =new Intl.NumberFormat("en-GB", {  
    style: "currency",  
    currency: "GBP",  
    minimumFractionDigits: 0,  
    maximumFractionDigits: 0,}).format(Number(number))
    return n
  }
  window.currency = currency;

export function toNumber(val) {
  return typeof val === "bigint" ? Number(val) : val;
}


export function carousel(images, mainImageId, image2Id, image3Id, leftId, rightId){
    const mainImage = document.getElementById(mainImageId);
    const image2 = document.getElementById(image2Id);
    const image3 = document.getElementById(image3Id);
    const rightArrow = document.getElementById(rightId);
    const leftArrow = document.getElementById(leftId);

    console.log("mainImage:", mainImage);
    console.log("image2:", image2);
    console.log("image3:", image3);

    console.log("leftArrow:", leftArrow, leftId);
    console.log("rightArrow:", rightArrow, rightId);


    // Full list of all image URLs (could be dynamic later)
    const imageList = images.map(([_, url]) => url);
    console.log(imageList);

    let startIndex = 0; // index of the main image (image1)

    // Update visible images
    function updateCarousel() {
      const image1Index = startIndex % imageList.length;
      const image2Index = (startIndex + 1) % imageList.length;
      const image3Index = (startIndex + 2) % imageList.length;

      mainImage.src = imageList[image1Index];
      image2.src = imageList[image2Index];
      image3.src = imageList[image3Index];
    }

    // On page load
    updateCarousel();

    // Arrow logic
    leftArrow.addEventListener("click", () => {
      startIndex = (startIndex - 1 + imageList.length) % imageList.length;
      updateCarousel();
    });

    rightArrow.addEventListener("click", () => {
      startIndex = (startIndex + 1) % imageList.length;
      updateCarousel();
    });
}

export function fromE8s(rawValue) {
  return (Number(rawValue) / 1e8).toFixed(4);
}

export function fromE6s(rawValue) {
  return (Number(rawValue) / 1e6).toFixed(4);
}

export function groupByFields(array, matchFields, idField = "id") {
  const result = [];

  array.forEach(item => {
    // Look for an existing entry that matches only on matchFields
    const existing = result.find(entry =>
      matchFields.every(field => entry[field] === item[field])
    );

    if (existing) {
      // If found, increment quantity and push the id
      existing.quantity += 1;
      existing.ids.push(item[idField]);
    } else {
      // Create new entry with quantity and ids array
      const newEntry = {
        ...item,                     // spread original fields
        quantity: 1,                 // initialize quantity
        ids: [item[idField]]         // start ids array with current item's id
      };
      result.push(newEntry);
    }
  });

  return result;
}

export function shortenPrincipal(principal) {
    if (!principal || typeof principal !== "string") return "";

    // Split principal into parts by dashes
    const parts = principal.split("-");

    if (parts.length === 0) return principal; // Fallback

    const first = parts[0]; // First segment
    const last = parts[parts.length - 1]; // Last segment

    return `${first}…${last}`;
}

export async function selectProperty(dropdownId, includeAll = false) {
  const readArgs = [
    { Location: [] },
    { CollectionIds: [] }
  ];

  try {
    let backend = await getCanister("backend");
    const results = await backend.readProperties(readArgs, []);
    console.log("SelectProperty:Results", results);

    const principal = await getPrincipal();
    if (!principal) {
      console.error("No principal found. User not authenticated?");
      return [];
    }
    const account = { owner: Principal.fromText(principal), subaccount: [] };

    // check ownership
    const nftCalls = results[1].CollectionIds
      .filter(c => "Ok" in c.value)
      .map(async (c) => {
        let nftBackend = await getCanister("nft", c.value.Ok.toText());
        let tokens = await nftBackend.icrc7_tokens_of(account, [], []);
        return { id: Number(c.id), tokens };
      });

    const nfts = await Promise.all(nftCalls);
    console.log("NFTs", nfts);

    // 🔑 Extract owned property IDs
    const ownedIds = nfts.filter(n => n.tokens.length > 0).map(n => n.id);

    // Populate dropdown
    const dropdown = document.getElementById(dropdownId);
    dropdown.innerHTML = "";

    if (includeAll) {
        const allOption = document.createElement("option");
        allOption.value = ownedIds.join(",");   // 👈 store all ids directly
        allOption.textContent = "All Properties";
        allOption.selected = true;
        dropdown.appendChild(allOption);
    } else {
      const placeholder = document.createElement("option");
      placeholder.value = "";
      placeholder.disabled = true;
      placeholder.selected = true;
      placeholder.textContent = "-- Select a property --";
      dropdown.appendChild(placeholder);
    }

    results[0].Location.forEach((prop) => {
      if (!("Ok" in prop.value)) return;
      const id = Number(prop.id);
      if (!ownedIds.includes(id)) return;

      const loc = prop.value.Ok;
      const label = [
        loc.addressLine1,
        loc.addressLine2,
        loc.city,
        loc.postcode
      ].filter(Boolean).join(", ");

      const option = document.createElement("option");
      option.value = id;
      option.textContent = label || `Property ${id}`;
      dropdown.appendChild(option);
    });

    if (dropdown.options.length === 1) {
      const option = document.createElement("option");
      option.disabled = true;
      option.textContent = "No owned properties available";
      dropdown.appendChild(option);
    }

    // ✅ return owned IDs for external use
    return ownedIds;

  } catch (err) {
    console.error("❌ Error calling select property:", err);
    return [];
  }
}

export function getSelectedPropertyIds(dropdownId) {
  const dropdown = document.getElementById(dropdownId);
  if (!dropdown) return [];

  const selectedValue = dropdown.value;

  if (selectedValue === "") {
    // Collect all *numeric* options
    const ids = Array.from(dropdown.options)
      .map(opt => opt.value.trim())
      .filter(v => v !== "" && !isNaN(Number(v)))
      .map(v => Number(v));

    return ids; // always pure int[]
  }

  const num = Number(selectedValue);
  return Number.isInteger(num) ? [num] : [];
}

export function resultMessage(id, message, success){
  let element = document.getElementById(id);
  element.innerHTML = message;
  if(success){
    element.classList.add("okResult")
    element.classList.remove("errResult")
  }
  else{
    element.classList.add("errResult")
    element.classList.remove("okResult")
  }
}

function initNotifications(notifications) {
    const bell = document.getElementById("bell");
    const count = document.getElementById("count");
    const dropdown = document.getElementById("dropdown");

    // Show count if there are notifications
    if (notifications.length > 0) {
      count.innerText = notifications.length;
      count.classList.remove("hidden");
    }

    // Render dropdown items
    function renderNotifications() {
      dropdown.innerHTML = notifications.map(n => `
        <div class="notification-item" data-id="${n.id}">
          <div class="notification-title">${n.type}</div>
          <div>${n.text}</div>
          <div class="notification-meta">Property ID: ${n.propertyId}</div>
        </div>
      `).join("");
    }

    renderNotifications();

    // Toggle dropdown
    bell.addEventListener("click", () => {
      dropdown.classList.toggle("hidden");
    });

    // Close dropdown when clicking outside
    document.addEventListener("click", (e) => {
      if (!bell.contains(e.target) && !dropdown.contains(e.target)) {
        dropdown.classList.add("hidden");
      }
    });
  }

  // Example dummy data
  const dummyNotifications = [
    { id: 1, type: "NftMarketplace", text: "New bid placed on Listing #1", propertyId: 0 },
    { id: 2, type: "Governance", text: "New Proposal created", propertyId: 0 },
    { id: 3, type: "Maintenance", text: "Leaky kitchen tap reported", propertyId: 0 },
    { id: 4, type: "Tenant", text: "Tenant1 moved in", propertyId: 0 },
    { id: 5, type: "Document", text: "EPC uploaded", propertyId: 0 }
  ];

  // Initialise with dummy data
  initNotifications(dummyNotifications);