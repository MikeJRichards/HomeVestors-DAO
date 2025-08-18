import { Principal } from "@dfinity/principal";
import {setupModal} from "./All.js";
import {getCanister, getPrincipal, wireConnect, logout} from "./Main.js"

wireConnect("connect_btn", "NavWallet");
var data = null;

function tabToggle(){
    let newPropertiesBtn = document.getElementById("newPropertiesBtn");
    let investorMarketplaceBtn = document.getElementById("investorMarketplaceBtn");
    let newProperties = document.getElementById("newProperties");
    let investorMarketplace = document.getElementById("investorMarketplace");

    newPropertiesBtn.addEventListener("click", () => {
        investorMarketplace.classList.add("hidden");
        investorMarketplaceBtn.classList.remove("active");
        
        newPropertiesBtn.classList.add("active");
        newProperties.classList.remove("hidden");
    });
    
    investorMarketplaceBtn.addEventListener("click", () => {
      newProperties.classList.add("hidden");
      investorMarketplace.classList.remove("hidden");
      newPropertiesBtn.classList.remove("active");
      investorMarketplaceBtn.classList.add("active");
    });
}

function toggleFilterVisibility(){
    let filtersBtn = document.getElementById("filters-btn");
    let ImpfiltersBtn = document.getElementById("imp-filters-btn");
    let filtersBar = document.getElementById("filtersBar");
    let impfiltersBar = document.getElementById("imp-filtersBar");

    filtersBtn.addEventListener("click", () => {
      if(filtersBar.classList.contains("hidden")){
        filtersBar.classList.remove("hidden");
      }
      else{
        filtersBar.classList.add("hidden");
      }
    });

     ImpfiltersBtn.addEventListener("click", () => {
      if(impfiltersBar.classList.contains("hidden")){
        impfiltersBar.classList.remove("hidden");
      }
      else{
        impfiltersBar.classList.add("hidden");
      }
    });
}

toggleFilterVisibility()
tabToggle()

function setupActiveToggle(idArray) {
  const elements = idArray.map(id => document.getElementById(id));

  elements.forEach((el) => {
    if (!el) {
      console.warn(`Element with ID '${el}' not found`);
      return;
    }

    el.addEventListener("click", () => {
      // Remove 'active' from all
      elements.forEach(e => e?.classList.remove("active"));
      // Add 'active' to clicked element
      el.classList.add("active");
    });
  });
}

setupActiveToggle(["allBtn", "availableBtn", "soldBtn"]);


//async function loadLaunchedProperties() {
//  const container = document.querySelector(".main-body");
//  const template = document.querySelector("#launch-template .property-card");
//
//  // Step 1: fetch launched properties
//  const launched = await backend.readProperties({ Listings: [ { PropertyLaunch: null } ] }, [[]]);
//  console.log(launched);
//  for (const propEntry of launched.LaunchedProperties ?? []) {
//    if (!propEntry.value.Ok) continue;
//    const property = propEntry.value.Ok;
//
//    const clone = template.cloneNode(true);
//
//    // === IMAGES ===
//    const images = clone.querySelectorAll(".carousel-image");
//    images.forEach((img, i) => {
//      img.src = property.details.misc.images?.[i] ?? "./assets/fallback.jpg";
//    });
//
//    // === PRICE ===
//    const formatGBP = n =>
//      new Intl.NumberFormat("en-GB", { style: "currency", currency: "GBP", minimumFractionDigits: 0 }).format(n);
//
//    clone.querySelector('[data-role="purchasePrice"]').textContent = formatGBP(property.financials.investment.purchasePrice);
//    clone.querySelector('[data-role="pricePerNFT"]').textContent = formatGBP(property.financials.investment.purchasePrice / 1000); // example for 1/1000th per NFT
//
//    // === LOCATION ===
//    clone.querySelector('[data-role="addressLine2"]').textContent = property.details.location.addressLine2;
//    clone.querySelector('[data-role="location"]').textContent = property.details.location.city;
//    clone.querySelector('[data-role="outcode"]').textContent = property.details.location.postcode.slice(0, 4);
//
//    // === DESCRIPTION ===
//    clone.querySelector(".description").textContent = property.details.misc.description;
//
//    // === Append to container ===
//    container.appendChild(clone);
//  }
//}
//
//loadLaunchedProperties()


function createPropertyCard(property) {
  const card = document.createElement("div");
  card.classList.add("property-card");
  card.id = `pro-card${property.id}`; 
  // Generate carousel images

  const carouselImages = property.images.map(
    (img, i) =>
      `<img class="carousel-image ${i === 0 ? "active" : ""}" src="${img}" alt="Property Image">`
  ).join("");

  // Calculate progress %
  const progressPercent = (property.sold / property.totalNFTs) * 100;
  card.innerHTML = `
  <div id="prop-img${property.id}" class="image-carousel">
      ${carouselImages}
      <button class="mp-carousel-arrow left">&#10094;</button>
      <button class="mp-carousel-arrow right">&#10095;</button>
    </div>


    <div id="prop-info${property.id}" class="propertyInfo">
      <div class="infoBar-container">
        <div class="heart-btn-container">
          <button id="heart-btn"><i id="heart" class="fa-regular fa-heart"></i></button>
        </div>
        <div class="priceInfo-container">
          <p class="priceInfo">£${property.price.toLocaleString()}</p>
          <p class="priceInfo">£${(property.nftPrice)} per NFT</p>
        </div>
      </div>

      <div class="infoblock">
        <div data-role="location" class="np-location">
          <a href="NP-PropertyPage.html?id=${property.id}" class="street-link">
            <p data-role="addressLine2" class="street">${property.addressLine2},</p>
            <p data-role="location" class="city">${property.location},</p>
            <p data-role="outcode" class="outcode">${property.outcode}</p>
          </a>
        </div>
        <p>${property.description.substring(0, 150)}...</p>

        <div id="progress-container">
          <div id="nft-progress">
            <div class="progress-bar">
              <div class="progress-fill" style="width: ${progressPercent}%;">
              </div>
            </div>
            <div class="progress-labels">
              <span><strong>Sold:</strong> <span id="nfts-sold">${property.sold}</span>/${property.totalNFTs}</span>
            </div>
          </div>
        </div>
      </div>

      <div class="buyBtn-container">
        <button class="buyBtn" id="buyModal${property.id}" data-id="${property.id}">Buy NFTs</button>
      </div>
    </div>
  `;

  //carousel(property.images, "mainImage${property.id}", "image2${property.id}", "image3${property.id}", "pp-carousel-arrow left","pp-carousel-arrow right");
 // Add carousel functionality

  return card;
}

function carousel(cardElement, images) {

  const imageElements = cardElement.querySelectorAll(".carousel-image");
  const leftArrow = cardElement.querySelector(".mp-carousel-arrow.left");
  const rightArrow = cardElement.querySelector(".mp-carousel-arrow.right");

  let currentIndex = 0;

  function updateCarousel() {
    imageElements.forEach((img, i) => {
      img.classList.toggle("active", i === currentIndex);
    });
  }

  leftArrow.addEventListener("click", () => {
    currentIndex = (currentIndex - 1 + images.length) % images.length;
    updateCarousel();
  });

  rightArrow.addEventListener("click", () => {
    currentIndex = (currentIndex + 1) % images.length;
    updateCarousel();
  });

  updateCarousel(); // initialize
}

async function loadProperties() {
  try {
     const readArgs = [
          { Physical: [] },
          { Location: [] }, // Fetch Location
          { Financials: [] }, // Fetch Financials
          { Additional: [] }, // Fetch Additional Details
          { Misc: [] }, // Fetch Miscellaneous
          {Listings: {
            base: { Properties: [] }, // or whatever BaseRead you want
            conditionals: {
              account: [], // null in Candid option
              listingType: [[{PropertyLaunch: null}]], // null in Candid option
              ltype: {  Seller: null } // Variant with no payload
            }
          }},
          {Listings: {
            base: { Properties: [] }, // or whatever BaseRead you want
            conditionals: {
              account: [], // null in Candid option
              listingType: [[{LaunchFixedPrice: null}]], // null in Candid option
              ltype: {  Seller: null } // Variant with no payload
            }
          }},
          //{ Tenants: { base: { Properties: [propertyId] }, conditionals: null } },
        ];
        
        let backend = await getCanister("backend");
        console.log(backend);
        const results = await backend.readProperties(readArgs, []);
        console.log(results);
    
        let listings = results[5].Listings[0].result.Ok;
        console.log(listings);
        //for(let i = 0; i < listings.length; i++ ){
        //  if(listings[i].value.hasOwnProperty("Ok")){
        //    console.log(listings[i].value.Ok.LaunchedProperty)
        //  }
        //};

//          console.log(i + " "+ listings[i].value.hasOwnProperty("Ok"))

        console.log(results[5].Listings[1].result.Ok)
        data = [];
            
        for (let i = 0; i < results[0].Physical.length; i++) {
          if (
            "Ok" in results[0].Physical[i].value &&
            "Ok" in results[1].Location[i].value &&
            "Ok" in results[2].Financials[i].value &&
            "Ok" in results[3].Additional[i].value &&
            "Ok" in results[4].Misc[i].value &&
            "Ok" in results[5].Listings[i].result &&
            "Ok" in results[6].Listings[i].result 
          ) {
            //create an array for each property launch - not just 1 per property
            let launches = results[5].Listings[i].result.Ok
            .filter(item => item.value.Ok && "LaunchedProperty" in item.value.Ok)
            .map(item => item.value.Ok.LaunchedProperty);
            console.log(launches);
            
            for(let n = 0; n < launches.length; n++){
              //get only listings that match these ids. 
              let activeListings = results[6].Listings[i].result.Ok
              .filter(item => item.value.Ok && launches[n].listIds.includes(item.value.Ok.LaunchFixedPrice.id))
              .map(item => item.value.Ok.LaunchFixedPrice);
              data.push({
                id: Number(results[0].Physical[i].id),
                physical: results[0].Physical[i].value.Ok,
                location: results[1].Location[i].value.Ok,
                financials: results[2].Financials[i].value.Ok,
                additional: results[3].Additional[i].value.Ok,
                misc: results[4].Misc[i].value.Ok,
                LaunchedProperties: launches[n],
                fixedPriceListings: activeListings
              });
            };
          };
        }

        //so its results[accessOrder].listings[propertyId].result.Ok.[array with element<Result> access through i2].value.Ok.LaunchedProperty.args

    //const properties = await backend.getAllProperties();
    const container = document.getElementById("property-container");
    container.innerHTML = ""; // Clear existing cards

    data.forEach((property) => {
      let images = property.misc.images.map(img => img[1]);
      const card = createPropertyCard({
        id: property.id, //good
        images: images, 
        price: Number(property.financials.investment.purchasePrice), //could be property.LaunchedProperties.price - gives nft listing price
        nftPrice: Number(property.LaunchedProperties.price),
        addressLine2: property.location.addressLine2,
        location: property.location.location,
        outcode: property.location.postcode.slice(0, 4),
        description: property.misc.description,
        sold: property.LaunchedProperties.tokenIds.length - property.fixedPriceListings.length, // Example: NFTs sold
        totalNFTs: property.LaunchedProperties.tokenIds.length // Total NFTs for this property
      });
      let tokenIds = property.fixedPriceListings.map(listing => Number(listing.id));
      container.appendChild(card);
      setupModal(`buyModal${property.id}`, "buyNowModal", "closeBuyNowModal");
      getTotalCostBuyNow(`buyModal${property.id}`,"totalCost",  Number(property.LaunchedProperties.price), Object.keys(property.LaunchedProperties.quoteAsset)[0], tokenIds, property.id);
      carousel(card, images);
    });
  } catch (err) {
    console.error("Error loading properties:", err);
  }
}

loadProperties();

export function getTotalCostBuyNow(buttonId, dataRole, amount, currency, tokenIds, propertyId){
  document.getElementById(buttonId).addEventListener("click", () => {
    let el = document.querySelector(`[data-role="${dataRole}"]`);
    if (el && data != null) el.innerText = amount +" "+ currency;

    const modal = document.getElementById("buyNowModal");
    console.log("stringify tokenIds", JSON.stringify(tokenIds));
    modal.dataset.tokenIds = JSON.stringify(tokenIds);
    modal.dataset.price = amount;
    modal.dataset.propertyId = propertyId;
  });
  updateTotalCost("buyQuantity", "totalCost", amount, currency);
}

function updateTotalCost(inputId, dataRole, amount, currency){
  document.getElementById(inputId).addEventListener("input", () => {
    let quantity = document.getElementById(inputId).value;
    let el = document.querySelector(`[data-role="${dataRole}"]`);
    if (el) el.innerText = quantity * amount + " "+ currency;
  });
};


export async function buyNFT(listingsIds, propertyId, price, quantity = 1){
  if (quantity > listingsIds.length) {
    alert("Not enough NFTs available!");
    return;
  }
  //console.log(price);
  let args = [];
  for(let i = 0; i< quantity; i ++){
    args.push({
      propertyId,
      what: {
        NftMarketplace: {
          Bid:{
            listingId: Number(listingsIds[i]),
            bidAmount: Number(price),
            buyer_subaccount: []
          }
        }
      }
    });

  }
  
  console.log(args);
  
  let principal = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai");
  
  let allowanceArgs = {
    spender: { owner: principal, subaccount:[]},
    amount: BigInt(Math.round(1.1 * 1e8)),
    expected_allowance: [],
    expires_at: [],
    fee: [],
    memo: [],
    from_subaccount: [],
    created_at_time: []
  };
  
  //console.log(principal);
  console.log(args);

  try {
    let tokens = await getCanister("token");
    let allowance = await tokens.CKUSDC.icrc2_approve(allowanceArgs);
    if("Ok" in allowance){
      let backend = await getCanister("backend");
      const result = await backend.bulkPropertyUpdate(args);
      console.log("Purchase successful", result);
    }
    else {
      console.log("allowance failed ", allowance)
    }
  } catch (error) {
    console.error("Error purchasing NFTs:", error);
  }


} 

async function setUpBuyNow(){
  document.getElementById("buyNowBtn").addEventListener("click", async ()=>{
    const modal = document.getElementById("buyNowModal");
    const tokenIds = JSON.parse(modal.dataset.tokenIds); // All available tokens
    const propertyId = parseInt(modal.dataset.propertyId); 
    const price = parseInt(modal.dataset.price); 
    const quantity = document.getElementById("buyQuantity").value;
   await  buyNFT(tokenIds, propertyId, price, quantity);
  })
};

setUpBuyNow();




