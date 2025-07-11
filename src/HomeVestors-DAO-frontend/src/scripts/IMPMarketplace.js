import {getCanister, getPrincipal, wireConnect, logout} from "./Main.js";
import {setupModal, groupByFields, shortenPrincipal} from "./All.js";
import { buyNFT, getTotalCostBuyNow} from "./MarketPlace.js";

async function loadProperties() {
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
              listingType: [[{LiveFixedPrice: null}, {LiveAuction: null}]], // null in Candid option
              ltype: {  Seller: null } // Variant with no payload
            }
          }}
        ];
        let results = null;
        try{
          let backend = await getCanister("backend");
          console.log(backend)
          results = await backend.readProperties(readArgs, []);
        }
        catch(err){
          console.error("Error loading properties:", err);
        };
    
        console.log("Raw Read Results:", results);
        var id = 0;
        let container =  document.getElementById("nftAdvert-grid");
        container.innerHTML = ""; // Clear existing cards
            
        for (let i = 0; i < results[0].Physical.length; i++) {
          if (
            "Ok" in results[0].Physical[i].value &&
            "Ok" in results[1].Location[i].value &&
            "Ok" in results[2].Financials[i].value &&
            "Ok" in results[3].Additional[i].value &&
            "Ok" in results[4].Misc[i].value &&
            "Ok" in results[5].Listings[i].result 
          ) {
            //create an array for each property launch - not just 1 per property
            let property = {
              id: Number(results[0].Physical[i].id), //good
              images: results[4].Misc[i].value.Ok.images.map(img => img[1]), 
              addressLine2:  results[1].Location[i].value.Ok.addressLine2,
              location: results[1].Location[i].value.Ok.location,
              outcode: results[1].Location[i].value.Ok.postcode.slice(0, 4),
            }

            let liveAuctions = results[5].Listings[i].result.Ok
            .filter(item => item.value.Ok && "LiveAuction" in item.value.Ok)
            .map(item => item.value.Ok.LiveAuction);
            console.log("auctions", liveAuctions)
            let liveFixedPrice = results[5].Listings[i].result.Ok
            .filter(item => item.value.Ok && "LiveFixedPrice" in item.value.Ok)
            .map(item => item.value.Ok.LiveFixedPrice);
            console.log("live fixed price",liveFixedPrice);
            liveFixedPrice = groupByFields(liveFixedPrice, ["price", "expiresAt", "seller", "quoteAsset"], "id");
            console.log("live fixed price after transformation", liveFixedPrice);
            liveFixedPrice.forEach((listing)  =>{
               container.insertAdjacentHTML("beforeend",  createFixedPriceAdvert(property, listing, id));
              setupModal(`buyNow${id}`, "buyNowModal", "closeBuyNowModal");
              console.log(listing);
              console.log("listing id", Number(listing.id));
              console.log(`buyModal${property.id}`,"totalCost",  Number(listing.price), Object.keys(listing.quoteAsset)[0], Number(listing.id), Number(property.id));
              getTotalCostBuyNow(`buyNow${property.id}`,"totalCost",  Number(listing.price), Object.keys(listing.quoteAsset)[0], [Number(listing.id)], Number(property.id));
              id +=1;
            })

            liveAuctions.forEach((listing) =>{
              console.log("Listing retrieved", listing);
              container.insertAdjacentHTML("beforeend", createAuctionAdvert(property, listing, id));
              setupModal(`placeBid${id}`, "placeBidModal", "closePlaceBidModal");
              passDataToModal(property.id, listing.id, "placeBidModal", `placeBid${id}`, Number(listing.highestBid[0].bidAmount), listing.highestBid[0].buyer.owner, listing.highestBid[0].buyer ? Number(listing.highestBid[0].bidAmount) + Number(listing.bidIncrement) : Number(listing.startingPrice), listing.buyNowPrice[0])
              id += 1;
            })
    } 
  }
}

function passDataToModal(propertyIds, listingIds, modalId, buttonId, highestBid, bidder, minBid, buyNow){
  let modal = document.getElementById(modalId);
  let btn = document.getElementById(buttonId);
  btn.addEventListener("click", ()=>{
    const listingIdsStr = Array.isArray(listingIds)
      ? listingIds.map(id => id.toString())
      : listingIds.toString();

    console.log("ListingIdsSTR", listingIdsStr);
    console.log("HighestBid", highestBid);
    document.getElementById("highestBid").innerHTML = highestBid ? highestBid : 0;
    document.getElementById("MinBid").innerHTML = minBid? minBid: 0;
    console.log("BuyNow", buyNow)
    if(buyNow){
      document.getElementById("BuyNow").innerHTML = Number(buyNow);
      modal.dataset.buyNow = buyNow;
    }
    else{
       document.getElementById("buyNowDiv").classList.add("hidden");
    };

    let principal = getPrincipal();

    let highestBidderText = document.getElementById("highestBidder");
    if(bidder == principal){
      highestBidderText.innerHTML = "You're the Highest Bidder!";
      highestBidderText.classList.add("win");
    }
    else if(bidder){
      console.log("Bidder", bidder)
      highestBidderText.innerHTML = shortenPrincipal(bidder.toText());
      highestBidderText.classList.remove("win");
    }
    else{
      highestBidderText.innerHTML = "";
    }
   modal.dataset.propertyId = propertyIds.toString();
   console.log(listingIdsStr);
    modal.dataset.tokenIds = [listingIdsStr];
  })
}

async function setUpPlaceBid(){
  document.getElementById("placeBid").addEventListener("click", async ()=>{
    const modal = document.getElementById("placeBidModal");
    const tokenIds = JSON.parse(modal.dataset.tokenIds); // All available tokens
    console.log("TokenIDs", typeof tokenIds);
    const propertyId = Number(modal.dataset.propertyId); 
    const price = document.getElementById("bidAmount").value;
    console.log("property id", modal.dataset.propertyId); 
   await  buyNFT([tokenIds], propertyId, price);
  })
};

setUpPlaceBid();


async function setUpBuyNow(){
  document.getElementById("BuyNowBtn").addEventListener("click", async ()=>{
    const modal = document.getElementById("placeBidModal");
    const tokenIds = JSON.parse(modal.dataset.tokenIds); // All available tokens
    console.log("TokenIDs", typeof tokenIds);
    const propertyId = Number(modal.dataset.propertyId); 
    const price = Number(modal.dataset.buyNow);
    console.log("property id", modal.dataset.propertyId); 
   await  buyNFT([tokenIds], propertyId, price);
  })
};

setUpBuyNow();

function createFixedPriceAdvert(propertyCard, fixedPrice, id) {
  let seller = shortenPrincipal(fixedPrice.seller.owner.toText());
  console.log("seller", seller)
  return `
    <div class="nftAdvert-card" id="fixed-${fixedPrice.id}">
      <img class="thumbnailAdvert" src="${propertyCard.images[0]}" alt="Property image">

      <div data-role="location" class="location">
        <a href="IMP-PropertyPage.html?id=${propertyCard.id}" class="street-link">
          <span data-role="addressLine2" class="street">${propertyCard.addressLine2}</span>
          <span data-role="location" class="city">${propertyCard.location}</span>
          <span data-role="outcode">${propertyCard.outcode}</span>
        </a>
      </div>

      <p class="text-p principal">Seller: ${seller}</p>

      <div id="nft-info">
        <div class="container-advert-buyBtns">
          <p class="text-p ButtonDetails">Number Available: 1</p>
          <p id="imp-nftprice">£${fixedPrice.price}</p>
          <button class="advert-buyBtns" id="buyNow${id}">Buy Now</button>

          <!-- Fixed-price listings don't have auction details -->
          <p class="text-p ButtonDetails hidden" id="auctionDetails">Auction Not Available</p>
          <p id="imp-nftprice">-</p>
        </div>
      </div>
    </div>
  `;
}


function createAuctionAdvert(propertyCard, auction, id) {
  let seller = shortenPrincipal(auction.seller.owner.toText());
  return `
    <div class="nftAdvert-card" id="auction-${auction.id}">
      <img class="thumbnailAdvert" src="${propertyCard.images[0]}" alt="Property image">

      <div data-role="location" class="location">
        <a href="IMP-PropertyPage.html?id=${propertyCard.id}" class="street-link">
          <span data-role="addressLine2" class="street">${propertyCard.addressLine2}</span>
          <span data-role="location" class="city">${propertyCard.location}</span>
          <span data-role="outcode">${propertyCard.outcode}</span>
        </a>
      </div>

      <p class="text-p principal">Seller: ${seller}</p>
      <p class="text-p" id="auctionTiming">Auction closes: ${new Date(Number(auction.endsAt)).toLocaleDateString()}</p>


      <div id="nft-info">
        <div class="container-advert-buyBtns">
          <p class="text-p ButtonDetails" id="auctionDetails">Current Auction Price</p>
          <p id="imp-nftprice">£${auction.highestBid?.bidAmount ?? auction.startingPrice}</p>
          <button class="advert-buyBtns" id="placeBid${id}">Place Bid</button>

        </div>
      </div>
    </div>
  `;
}





loadProperties();