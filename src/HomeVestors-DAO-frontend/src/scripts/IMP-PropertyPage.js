import {getCanister, wireConnect} from "./Main.js";
import {setupModal, currency, carousel } from "./All.js";
var data = null;

wireConnect("connect_btn", "NavWallet");

async function fetchProperty() {
  try {
   const raw = new URLSearchParams(window.location.search).get("id");
   const propertyId = BigInt(raw);
  
    const readArgs = [
      { Physical: [[propertyId]] },
      { Location: [[propertyId]] }, // Fetch Location
      { Financials: [[propertyId]] }, // Fetch Financials
      { Additional: [[propertyId]] }, // Fetch Additional Details
      { Misc: [[propertyId]] }, // Fetch Miscellaneous
      { Images: {Properties: [[propertyId]] }}, // Fetch Miscellaneous
      //{ Tenants: { base: { Properties: [propertyId] }, conditionals: null } },
    ];
    let backend = await getCanister("backend");
    const results = await backend.readProperties(readArgs, []);

    console.log("Raw Read Results:", results);

    
    if("Ok" in results[0].Physical[0].value && 
      "Ok" in results[1].Location[0].value && 
      "Ok" in results[2].Financials[0].value && 
      "Ok" in results[3].Additional[0].value &&
      "Ok" in results[4].Misc[0].value &&
      "Ok" in results[5].Image[0].result.Ok[0].value){
        data = {
          physical: results[0].Physical[0].value.Ok,
          location: results[1].Location[0].value.Ok,
          financials: results[2].Financials[0].value.Ok,
          additional: results[3].Additional[0].value.Ok,
          misc:  results[4].Misc[0].value.Ok,
          Image:  results[5].Image[0].result.Ok[0],
        };
      };

      carousel(data.misc.images, "mainImage", "image2", "image3", "clickLeft","clickRight");
      console.log(data);
window.data = data

    const keyMap = [
    { dataRole: "currentValue", data: currency(data.financials.investment.purchasePrice)},
    { dataRole: "lastValued", data: "no data"},
    { dataRole: "propertyType", data: "no data"},
    { dataRole: "addedOn", data: "no data"},
    { dataRole: "addedOn", data: "no data"},
    { dataRole: "addressLine2", data: data.location.addressLine2 },
    { dataRole: "location", data: data.location.location },
    { dataRole: "outcode", data: data.location.postcode.slice(0, 4) },
    { dataRole: "beds", data: Number(data.physical.beds) },
    { dataRole: "baths", data: Number(data.physical.baths) },
    { dataRole: "property_subheading", data: "Charming "+Number(data.physical.beds)+"-Bedroom Family Home in a Prime Location" },
    { dataRole: "description", data: data.misc.description },
    { dataRole: "yearBuilt", data: Number(data.physical.yearBuilt) },
    { dataRole: "lastRenovation", data: Number(data.physical.lastRenovation) },
    { dataRole: "sqFt", data: Number(data.physical.squareFootage) },
    { dataRole: "tenure", data: "no data" },
    { dataRole: "parking", data: "no data" },
    { dataRole: "garden", data: "no data" },
    { dataRole: "buyNowPrice", data: "no data" },
    { dataRole: "auctionPrice", data: "no data" },
    { dataRole: "highestbidder", data: "no data" },
    { dataRole: "auctionEndsAt", data: "no data" },
    { dataRole: "Available", data: "no data" },
    { dataRole: "highestBid", data: "no data" },
    { dataRole: "highestBidderModal", data: "no data" },
    { dataRole: "taxBand", data: "no data" },
    { dataRole: "EPC", data: "no data" },
    { dataRole: "pricePerSqFoot", data: currency(data.financials.pricePerSqFoot) },
    { dataRole: "monthlyRent", data: currency(data.financials.monthlyRent) },
    { dataRole: "yield", data: Number(data.financials.yield * 100).toFixed(2)+"%" },
    { dataRole: "whyLocation", data: "no data" },
    { dataRole: "specificLocation", data: "no data" },
    { dataRole: "nftPropertyValue", data: currency(Number(data.financials.investment.purchasePrice)/1000) },
    { dataRole: "nftTreasury", data: currency(Number(data.financials.investment.initialMaintenanceReserve)/1000) },
    { dataRole: "nftTotalValue", data: currency(Number(data.financials.investment.totalInvestmentValue)/1000)  },
    { dataRole: "crimeScore", data: data.additional.crimeScore },
    { dataRole: "schoolScore", data: data.additional.schoolScore},
    { dataRole: "propertyValue", data: currency(data.financials.investment.purchasePrice)},
    { dataRole: "treasury", data: currency(data.financials.investment.initialMaintenanceReserve)},
    { dataRole: "totalValue", data: currency(data.financials.investment.totalInvestmentValue)},
];

    keyMap.forEach(({ dataRole, data }) => {
      const el = document.querySelector(`[data-role="${dataRole}"]`);
      if (el && data != null) el.innerText = data
      else if (el == null) console.warn("KEY ERROR: " + dataRole)
      else console.warn("DATA ERROR: " + dataRole + " = " + data);
    });
  } catch (err) {
    console.error("Error fetching property data:", err);
  }
}

fetchProperty()
toggleSections();

setupModal("buyBtn", "buyNowModal",  "closeBuyNowModal");
setupModal("auctionBtn", "placeBidModal",  "closeAuctionModal");


export function toggleSections() {
  document.querySelectorAll("#Pp-toggle .toggle-btn").forEach(button => {
    button.addEventListener("click", () => {
      // Remove 'active' from all buttons
      document.querySelectorAll("#Pp-toggle .toggle-btn").forEach(btn => {
        btn.classList.remove("active");
      });

      // Add 'active' to the clicked button
      button.classList.add("active");

      // Get the button text (normalized) to match section IDs
     const sectionName = button.textContent.trim().toLowerCase().replace(/\s+/g, "");

      // Hide all sections
      document.querySelectorAll("#pp-fullinfo-section > div[id^='mainpage-']").forEach(section => {
        section.style.display = "none";
      });

      // Show the selected section
      const targetSection = document.querySelector(`#mainpage-${sectionName}-section`);
      if (targetSection) {
        targetSection.style.display = "block";
      }
    });
  });
}
