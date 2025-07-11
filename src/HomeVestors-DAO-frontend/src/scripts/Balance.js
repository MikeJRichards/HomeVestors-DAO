import { getCanister, getPrincipal} from "./Main.js";
import { Principal } from "@dfinity/principal";
import { setupModal, fromE8s, fromE6s, groupByFields, shortenPrincipal } from "./All.js";

function tabToggle(){
  const tabs = document.querySelectorAll('.mp-header-toggle-btn');
  const sections = {
    "show-nfts": document.getElementById('nft-section'),
    "show-tokens": document.getElementById('token-section'),
    "show-listings": document.getElementById('listings-section'),
    "show-bids": document.getElementById('bids-section'),
  };

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      // Remove active states
      tabs.forEach(t => t.classList.remove('active'));
      Object.values(sections).forEach(s => s.classList.add('hidden'));
      // Set active
      tab.classList.add('active');
      sections[tab.id].classList.remove('hidden');
    });
  });
}

tabToggle();

function createNFTCard(property) {
  const card = document.createElement('div');
  card.classList.add('nft_card');
  card.id = `nft${property.id}`; // Unique ID

  card.innerHTML = `
    <img class="nft_img" id="nft${property.id}_img" src="${property.image}" alt="property nft ${property.id}">
    <div class="location-container">
      <a href="IMP_PropertyPage.html?id=${property.id}" class="street-link">
        <div data-role="location" class="location">
          <span data-role="addressLine2" class="street">${property.addressLine2},</span>
          <span data-role="location" class="city">${property.city},</span>
          <span data-role="outcode" class="outcode">${property.outcode}</span>
        </div>
      </a>
    </div>
    <div class="bp-info-block">
      <p class="text-p bp-info">
        <span class="bp-bold-text bp-info">Quantity:</span> ${property.quantity}/1000
      </p>
      <p class="text-p bp-info">
        <span class="bp-bold-text bp-info">NFT Value:</span> £${property.nftValue}
      </p>
      <p class="text-p bp-info">
        <span class="bp-bold-text bp-info">Total NFT Value:</span> £${property.totalValue}
      </p>
    </div>
    <div class="nft-btns">
      <button class="bp-nft-btn" id="saleButton${property.id}">List for Sale</button>
    </div>
  `;
  return card;
}


async function getNfts(){
  const readArgs = [
    { Physical: [] },
    { Location: [] }, // Fetch Location
    { Financials: [] }, // Fetch Financials
    { Additional: [] }, // Fetch Additional Details
    { Misc: [] }, // Fetch Miscellaneous
    { CollectionIds: [] } // Fetch Miscellaneous
    //{ Tenants: { base: { Properties: [propertyId] }, conditionals: null } },
  ];
  let principal = await getPrincipal();
  let account = {owner:  Principal.fromText(principal), subaccount: []};
  let results, nfts = null;

  try {
    let backend = await getCanister("backend");
    results = await backend.readProperties(readArgs, []);
    const nftCalls = results[5].CollectionIds
      .filter(c => "Ok" in c.value)
      .map(async (c) => {
        let nftBackend = await getCanister("nft", c.value.Ok.toText());
        let tokens = await nftBackend.icrc7_tokens_of(account, [], []);
        return { id: c.id, tokens };
      });
    nfts = await Promise.all(nftCalls);
  } catch (err) {
    console.error("❌ Error calling getNFTs:", err);
  }

  let properties = [];
  for(let i = 0; i < results[0].Physical.length; i++){
    if(
      "Ok" in results[0].Physical[i].value &&
      "Ok" in results[1].Location[i].value &&
      "Ok" in results[2].Financials[i].value &&
      "Ok" in results[3].Additional[i].value &&
      "Ok" in results[4].Misc[i].value &&
      "Ok" in results[5].CollectionIds[i].value
    ){
      let nftValue = Number(results[2].Financials[i].value.Ok.currentValue) /1000;
      const nftCardData = {
        id: Number(results[0].Physical[i].id),                    // Unique property/NFT id (e.g., 1, 2, 3...)
        image: results[4].Misc[i].value.Ok.images[0][1], // URL or path to the property image
        addressLine2: results[1].Location[i].value.Ok.addressLine2, // Address line 2 (e.g., street name)
        city: results[1].Location[i].value.Ok.location,           // City name
        outcode: results[1].Location[i].value.Ok.postcode.slice(0, 4),               // Outcode (postcode prefix)
        collectionId: results[5].CollectionIds[i].value.Ok,
        tokenIds: nfts[i].tokens,
        quantity: nfts[i].tokens.length,                // Number of NFTs user owns
        nftValue: nftValue,               // Value of a single NFT (£)
        totalValue: nftValue * nfts[i].tokens.length            // Total value of all owned NFTs (£)
      };
      properties.push(nftCardData);
    };

    let container = document.getElementById("nft-section");
    container.innerHTML = "";
    properties.forEach(property => {
      let card = createNFTCard(property);
      container.append(card);
      setupModal(`saleButton${property.id}`, "SellModal", "closeSend");
      document.getElementById(`saleButton${property.id}`).addEventListener("click", ()=> { document.getElementById("buyNowCheckbox").checked = true});
      seedSaleModal(`saleButton${property.id}`, property.id, property.tokenIds, property.quantity, property.collectionId)
    });

    console.log(properties);
  };  
}

getNfts();

function seedSaleModal(id, propertyId, tokenIds, quantity, collectionId){
  document.getElementById(id).addEventListener("click", () =>{
    let modal = document.getElementById("SellModal");
    modal.dataset.propertyId = propertyId;
    modal.dataset.tokenIds = tokenIds;
    modal.dataset.quantity = quantity;
    modal.dataset.collectionId = collectionId;
  });
};


async function getTokenBalances(){
  const tokens = await getCanister("token");
  console.log(tokens);
  
  let account = {owner: Principal.fromText(await getPrincipal()), subaccount: []}

  let ckusdcBalance = await tokens.CKUSDC.icrc1_balance_of(account);
  let icpBalance = await tokens.ICP.icrc1_balance_of(account);
  document.getElementById("ckUSDCBalance").innerText = fromE6s(ckusdcBalance);
  document.getElementById("icpBalance").innerText = fromE8s(icpBalance);
}

getTokenBalances();

async function recieveTrigger(){
  document.querySelectorAll('.balance_button').forEach(button => {
    if (button.textContent.trim().toUpperCase() === 'RECIEVE') {
      button.addEventListener('click', async () => {
        const tokenCard = button.closest('.token_card'); // find parent card
        console.log(await getPrincipal());
        tokenCard.querySelector(".address-text").innerHTML = await getPrincipal();
        const receiveAddress = tokenCard.querySelector('.receive-address'); // find receive block
        receiveAddress.classList.toggle('hidden'); // toggle hidden class
      });
    }
  });
}

recieveTrigger();
setupModal("sendICP" , "sendModal", "closeSend")
setupModal("sendCKUSDC" , "sendModal", "closeSend")
seedSendData();
function seedSendData(){
    document.querySelectorAll('.balance_button').forEach(button => {
    if (button.textContent.trim().toUpperCase() === 'SEND') {
      button.addEventListener('click', () => {
        const tokenCard = button.closest('.token_card'); // Get the parent card

        // Extract token data
        const tokenSymbol = tokenCard.querySelector('.token_symbol').textContent.trim();
        const tokenIconSrc = tokenCard.querySelector('.token_img').src;

        // Seed the modal
        document.getElementById('tokenName').textContent = tokenSymbol;
        document.getElementById('sendTokenIcon').src = tokenIconSrc;

        // Clear inputs
        document.getElementById('amount').value = '';
        document.getElementById('recipient').value = '';

        // Optionally attach token id for use when sending
        sendModal.dataset.token = tokenSymbol;
      });
    }
  });
};

document.querySelector('.send-submit').addEventListener("click", async ()=>{
  sendTokens();
})

async function sendTokens() {
  const token = sendModal.dataset.token; // e.g., "ckUSDC"
  const recipient = Principal.fromText(document.getElementById('recipient').value.trim());
  const amount = document.getElementById('amount').value.trim();

  // Validate inputs
  if (!recipient || !amount || isNaN(amount) || parseFloat(amount) <= 0) {
    displaySendResult('❌ Please enter a valid recipient and amount.', true);
    return;
  }

  try {
    // Convert amount to e8s (multiply by 10^8)
    const amountE8s = BigInt(Math.floor(parseFloat(amount) * 1e8));

    let arg1 = {
        to: { owner: recipient, subaccount: [] },
        amount: amountE8s,
        fee: [], memo: [], created_at_time: [], from_subaccount: []
      }

    let arg = {
      to: recipient,
      amount: [amountE8s],
      fee: [],
      memo:[],
      created_at_time: [],
      from_subaccount: []
    };
    // Call backend method (replace with your actual call)
    let tokens = await getCanister("token");
    console.log("token")
    let canister = token == "ICP" ? tokens.ICP : tokens.CKUSDC;
    console.log(canister);
    const result = await canister.icrc1_transfer(arg1);

    if (result.Ok) {
      displaySendResult(`✅ Successfully sent ${amount} ${token} to ${recipient}`, false);
      getTokenBalances();
    } else {
      displaySendResult(`❌ Transfer failed: ${result.Err}`, true);
    }
  } catch (error) {
    console.error(error);
    displaySendResult('❌ An error occurred while sending tokens.', true);
  }
}

// Helper to show result in modal
function displaySendResult(message, isError = false) {
  const resultElement = document.getElementById('sendResult');
  resultElement.textContent = message;
  resultElement.style.color = isError ? 'red' : 'green';
}



////////////////////////////////////////////
function selectListingType(selectedId, otherId){
  document.getElementById("buyNowCheckbox").addEventListener("change", () => {
    document.getElementById("buynowData").classList.remove("hidden");
    document.getElementById("auctionData").classList.add("hidden");
    document.getElementById("buyNowCheckbox").checked = true;
    document.getElementById("auctionCheckBox").checked = false;
   });

  document.getElementById("auctionCheckBox").addEventListener("change", () => {
    document.getElementById("buynowData").classList.add("hidden");
    document.getElementById("auctionData").classList.remove("hidden");
    document.getElementById("buyNowCheckbox").checked = false;
    document.getElementById("auctionCheckBox").checked = true;
  })
}

selectListingType();

function sanitizePrice(id){
  let priceInput = document.getElementById(id);
  let priceValue = parseInt(priceInput.value);
if (isNaN(priceValue)) {
    console.error("Price must be a valid integer");
    return; // prevent the call
}
return priceValue;
}

async function listForSale(){
  let btn = document.getElementById("listForSale");
  btn.addEventListener('click', async ()=> {
    let quantity = document.getElementById("sellQuantitySellModal").value;
    console.log("Action triggered")
    const modal = document.getElementById("SellModal");
    const propertyId = modal.dataset.propertyId; // "123"
    const tokenIds = modal.dataset.tokenIds;       //[1,2,3]
    const collectionId = modal.dataset.collectionId;
    console.log(collectionId);
    //if(quantity > modal.dataset.quantity){
    //  console.log("quantity error trigggered");
    //  document.getElementById("listingResult").innerHtml = "You don't own this many NFTs";
    //  return;
    //}
    let args = [];
    console.log("quantity"+quantity);
    console.log("tokens", tokenIds);
    console.log(document.getElementById("BuyNowPrice").value);
    console.log("price", sanitizePrice("BuyNowPrice"));
    for(let i = 0; i < quantity; i++){
      if(document.getElementById("buyNowCheckbox").checked){
        let fixedPriceArg = listFixedPrice(propertyId, tokenIds[i], sanitizePrice("BuyNowPrice"), calculateEndTime())
        console.log(fixedPriceArg)
        args.push(fixedPriceArg);
      }
      else {
        args.push(listAuction(propertyId, tokenIds[i], sanitizePrice("startingPrice"), sanitizePrice("AuctionBuyNowPrice"), sanitizePrice("reservePrice"), calculateEndTime()));
      }
    };
    console.log(args);

    try{
      let approvalResult = await createNFTTransferFromApproval(tokenIds, collectionId, quantity);
      let backend = await getCanister("backend");
      let result = await backend.bulkPropertyUpdate(args);
      console.log(result);
      if("Ok" in result[0]){
        document.getElementById("listingResult").value = "Tokens listed for sale";
      }
      else console.log("error in results ",  JSON.stringify(result[0].Err, null, 2))  
    }
    catch(e){
      console.log("Operation failed", e);
    }
    
  })

};

async function createNFTTransferFromApproval(tokenIds, canisterId, quantity){
  let account = {owner: Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"), subaccount: []};
  let args = [];
  let backend = await getCanister("backend");
  let time = await backend.getTime();
  for(let i = 0; i < quantity; i++){
    let arg = {
      token_id: parseInt(tokenIds[i]),
      approval_info: {
        memo : [],
        from_subaccount: [],
        created_at_time: time,
        expires_at : [],
        spender: account,
      }
    };
    args.push(arg)
    console.log(arg);
  };
  try{
    let nftCanister = await getCanister("nft", canisterId);
    console.log(nftCanister);
    let result = await nftCanister.icrc37_approve_tokens(args);
    if("Ok" in result[0]){
      console.log("Approval worked")
    }
    else{
      console.log("Approval Error", result);
    }
  }
  catch(e){
    console.log(e);
  }
}

listForSale();

function listAuction(propertyId, tokenId, startPrice, buyNowPrice, reservePrice, endTime) {
  return {
    propertyId: parseInt(propertyId),
    what: {
      NFTMarketplace: {
        CreateAuctionListing: {
          tokenId: parseInt(tokenId),
          seller_subaccount: [], // maybe null here instead?
          startingPrice: startPrice,
          buyNowPrice: [buyNowPrice], // optional
          reservePrice: [reservePrice], // optional
          endsAt: endTime.length > 0 ? endTime[0] : [],
          quoteAsset: [{ CKUSDC: null }],
          startTime: BigInt(Date.now()) * 1_000_000n,
        }
      }
    }
  };
}



function listFixedPrice(propertyId, tokenId, price, endTime) {
  return {
    propertyId: parseInt(propertyId), 
    what: {
      NFTMarketplace: {
        CreateFixedListing: {
          tokenId: parseInt(tokenId),
          seller_subaccount: [], // assuming this means no subaccount
          price: price, 
          expiresAt: endTime, // assuming Motoko expects an optional value
          quoteAsset: [{ CKUSDC: null }],
        }
      }
    }
  };
}
  
  function calculateEndTime() {
  const select = document.getElementById("auctionLength");
  const value = select.value; // e.g., "24h", "48h", "1w", "2w"

  let futureDate = new Date();

  switch (value) {
    case "24h":
      futureDate.setHours(futureDate.getHours() + 24);
      break;
    case "48h":
      futureDate.setHours(futureDate.getHours() + 48);
      break;
    case "1w":
      futureDate.setDate(futureDate.getDate() + 7);
      break;
    case "2w":
      futureDate.setDate(futureDate.getDate() + 14);
      break;
    default:
      return []; // Handle gracefully
  }

  // Convert milliseconds to nanoseconds for Motoko
  const nanoTimestamp = BigInt(futureDate.getTime()) * 1_000_000n;

  console.log("Auction ends at (nanoseconds):", nanoTimestamp.toString());
  return [nanoTimestamp];
}

///////////////////////////////////////////////////
function createAuctionListing(property, auction) {
  return `
    <div class="nft_card" id="auction-${auction.id}">
        <img class="nft_img" id="auction-${auction.id}_img" src="${property.image}" alt="auction-${auction.id}">

        <div class="location-container">
           <a href="IMP_PropertyPage.html?id=${property.id}" class="street-link">
              <div data-role="location" class="location">
                  <p data-role="addressLine2" class="street">${property.addressLine2}</p>
                  <p data-role="location" class="city">${property.city}</p>
                  <p data-role="outcode" class="outcode">${property.outcode}</p>
              </div>
            </a>
        </div>

        <div class="bp-info-block">
            <p class="text-p bp-info">
                <span class="bp-bold-text bp-info">Auction ID:</span> ${auction.id}
            </p>
            <p class="text-p bp-info">
                <span class="bp-bold-text bp-info">Starting Price:</span> £${auction.startingPrice}
            </p>
            <p class="text-p bp-info">
                <span class="bp-bold-text bp-info">Current Price:</span> £${auction.highestBid?.bidAmount ?? "No bids yet"}
            </p>
            <p class="text-p bp-info">
                <span class="bp-bold-text bp-info">Current Highest Bidder:</span> ${auction.highestBid?.buyer?.owner ?? "None"}
            </p>
            <p class="text-p bp-info">
                <span class="bp-bold-text bp-info">Number of Bids:</span> ${(auction.previousBids?.length || 0) + (auction.highestBid ? 1 : 0)}
            </p>
            <p class="text-p bp-info">
                <span class="bp-bold-text bp-info">Reserve Price:</span> £${auction.reservePrice ?? "Not Set"}
            </p>
            <p class="text-p bp-info">
                <span class="bp-bold-text bp-info">Auction Ends:</span> ${new Date(Number(auction.endsAt)).toLocaleString()}
            </p>
        </div>

     
    </div>
  `;
  //<div class="nft-btns">
  //       <button class="btn view-btn" onclick="viewAuctionDetails(${auction.id})">View Details</button>
  //   </div>
}
function createFixedPriceListing(property, fixedPrice) {
  let seller = shortenPrincipal(fixedPrice.seller.owner.toText());
  return `
    <div class="nft_card" id="fixed-${fixedPrice.id}">
        <img class="nft_img" id="fixed-${fixedPrice.id}_img" src="${property.image}" alt="fixed-${fixedPrice.id}">

        <div class="location-container">
           <a href="IMP_PropertyPage.html?id=${property.id}" class="street-link">
            <div data-role="location" class="location">
                <p data-role="addressLine2" class="street">${property.addressLine2}</p>
                <p data-role="location" class="city">${property.city}</p>
                <p data-role="outcode" class="outcode">${property.outcode}</p>
            </div>
            </a>
        </div>

        <div class="bp-info-block">
            <p class="text-p bp-info">
                <span class="bp-bold-text bp-info">Listing ID:</span> ${fixedPrice.id}
            </p>
            <p class="text-p bp-info">
                <span class="bp-bold-text bp-info">Price:</span> £${fixedPrice.price}
            </p>
            <p class="text-p bp-info">
                <span class="bp-bold-text bp-info">Expires At:</span> ${fixedPrice.expiresAt ? new Date(fixedPrice.expiresAt).toLocaleString() : "No Expiry"}
            </p>
            <p class="text-p bp-info">
                <span class="bp-bold-text bp-info">Seller:</span> ${seller}
            </p>
        </div>

    </div>
  `;
  //<div class="nft-btns">
  //    <button class="btn view-btn" onclick="viewListingDetails(${fixedPrice.id})">View Details</button>
  //</div>
}

function createBidCardHTML(bidSummary, propertyData) {
  console.log("BidSummary", bidSummary);
  return `
    <div class="nft_card" id="nft${propertyData.id}">
      <img class="nft_img" id="nft${propertyData.id}_img" src="${propertyData.image}" alt="nft${propertyData.id}">

      <div class="location-container">
        <a href="IMP-PropertyPage.html?id=${propertyData.id}" class="street-link">  
          <div data-role="location" class="location">
            <p data-role="addressLine2" class="street">${propertyData.addressLine2}</p>
            <p data-role="location" class="city">${propertyData.city}</p>
            <p data-role="outcode" class="outcode">${propertyData.outcode}</p>
          </div>
        </a>
      </div>

      <div class="bp-info-block">
        <p class="text-p bp-info"><span class="bp-bold-text bp-info">Auction ID:</span> ${bidSummary.auctionId}</p>
        <p class="text-p bp-info"><span class="bp-bold-text bp-info">Current Price:</span> £${bidSummary.currentPrice}</p>
        <p class="text-p bp-info"><span class="bp-bold-text bp-info">Current Winner:</span> ${bidSummary.currentWinner}</p>
        <p class="text-p bp-info"><span class="bp-bold-text bp-info">Next Min Bid Amount:</span> £${bidSummary.nextMinBidAmount}</p>
        <p class="text-p bp-info"><span class="bp-bold-text bp-info">Reserve Met:</span> ${bidSummary.reserveMet ? "Yes" : "No"}</p>
        <p class="text-p bp-info"><span class="bp-bold-text bp-info">Listing Live:</span> ${Date.now() < bidSummary.endsAt ? "Yes" : "No"}</p>
        <p class="text-p bp-info"><span class="bp-bold-text bp-info">Bid Amount:</span> £${bidSummary.userMostRecentBid?.bidAmount ?? "N/A"}</p>
        <p class="text-p bp-info"><span class="bp-bold-text bp-info">Bid Time:</span> ${new Date(Number(bidSummary.userMostRecentBid?.bidTime)).toLocaleString() ?? "N/A"}</p>
        <p class="text-p bp-info"><span class="bp-bold-text bp-info">Times You've Bid:</span> ${bidSummary.userPreviousBids.length + 1}</p>
        <p class="text-p bp-info"><span class="bp-bold-text bp-info">Total Bids:</span> ${bidSummary.totalBids}</p>
      </div>

      </div>
      `;
      //<div class="nft-btns">
      //  <button class="btn place-bid-btn" onclick="placeBid(${bidSummary.auctionId})">Place Bid</button>
      //  <button class="btn view-details-btn" onclick="viewAuctionDetails(${bidSummary.auctionId})">View Details</button>
      //</div>
}


getListings();

async function getListings() {
  let principal = await getPrincipal();
  let account = { owner: Principal.fromText(principal), subaccount: [] };

  const readArgs = [
    { Location: [] }, // Fetch Location
    { Financials: [] }, // Fetch Financials
    { Misc: [] }, // Fetch Miscellaneous
    { CollectionIds: [] }, // Fetch CollectionIds
    {
      Listings: {
        base: { Properties: [] },
        conditionals: {
          account: [account],
          listingType: [[
            { LiveFixedPrice: null },
            { SoldFixedPrice: null },
            { LiveAuction: null },
            { SoldAuction: null }
          ]],
          ltype: { Seller: null }
        }
      }
    },
    {
      Listings: {
        base: { Properties: [] },
        conditionals: {
          account: [account],
          listingType: [[
            { LiveAuction: null },
            { SoldAuction: null }
          ]],
          ltype: { PreviousBids: null }
        }
      }
    }
  ];

  let results = null;

  try {
    let backend = await getCanister("backend");
    results = await backend.readProperties(readArgs, []);
  } catch (err) {
    console.error("❌ Error calling getNFTs:", err);
    return;
  }

  console.log("📦 list Results:", results);

  for (let i = 0; i < results[0].Location.length; i++) {
    // ✅ Safely unwrap backend data
    const location = results[0].Location[i].value?.Ok;
    const financials = results[1].Financials[i].value?.Ok;
    const misc = results[2].Misc[i].value?.Ok;
    const collectionId = results[3].CollectionIds[i].value?.Ok;

    // ✅ Unwrap listings
    const listingsSeller = results[4].Listings[i].result;
    const listingsPreviousBids = results[5].Listings[i].result;

    // ✅ Skip if any required field is missing
    if (!location || !financials || !misc || !collectionId) {
      console.warn(`⏭ Skipping property ${i}: missing core data`);
      continue;
    }

    // ✅ Process listings (safe guards against Err)
    const liveAuctions = ("Ok" in listingsSeller && Array.isArray(listingsSeller.Ok))
      ? listingsSeller.Ok
          .filter(item => item.value.Ok && "LiveAuction" in item.value.Ok)
          .map(item => item.value.Ok.LiveAuction)
      : [];


    const liveFixedPriceRaw = ("Ok" in listingsSeller && Array.isArray(listingsSeller.Ok))
      ? listingsSeller.Ok
          .filter(item => item.value.Ok && "LiveFixedPrice" in item.value.Ok)
          .map(item => item.value.Ok.LiveFixedPrice)
      : [];


    const soldFixedPriceRaw = ("Ok" in listingsSeller && Array.isArray(listingsSeller.Ok))
      ? listingsSeller.Ok
          .filter(item => item.value.Ok && "SoldFixedPrice" in item.value.Ok)
          .map(item => item.value.Ok.SoldFixedPrice)
      : [];

    const liveFixedPrice = groupByFields(
      liveFixedPriceRaw,
      ["price", "expiresAt", "seller", "quoteAsset"],
      "id"
    );


    const soldFixedPrice = groupByFields(
      soldFixedPriceRaw,
      ["price", "expiresAt", "seller", "quoteAsset"],
      "id"
    );


    const previousBids = ("Ok" in listingsPreviousBids && Array.isArray(listingsPreviousBids.Ok))
      ? listingsPreviousBids.Ok
          .filter(item => item.value.Ok && "LiveAuction" in item.value.Ok)
          .map(item => item.value.Ok.LiveAuction)
          .flatMap(auction => {
            const userBids = auction.previousBids
              .filter(bid => bid.buyer.owner.toText() === account.owner.toText())
              .sort((a, b) => b.bidTime - a.bidTime);

            if (userBids.length === 0) return []; // No bids

            const latestBid = userBids[0];
            const olderBids = userBids.slice(1);

            return [{
              auctionId: Number(auction.id),
              currentPrice: Number(auction.highestBid[0].bidAmount ?? 0),
              currentWinner: shortenPrincipal(auction.highestBid[0].buyer.owner.toText()) ?? "No Winner",
              nextMinBidAmount: Number((auction.highestBid[0].bidAmount ?? 0n) + auction.bidIncrement),
              lastBid: latestBid.bidTime ?? null,
              reserveMet: (auction.highestBid[0].bidAmount ?? 0n) > (auction.reserve ?? 0),
              totalBids: auction.previousBids.length,
              endsAt: Number(auction.endsAt),
              isUserWinning: latestBid.buyer === auction.highestBid[0].buyer?.owner,
              userMostRecentBid: latestBid,
              userPreviousBids: olderBids
            }];
          })
      : [];

    console.log("bids", previousBids);

    // ✅ Skip properties with no active data
    if (liveAuctions.length === 0 && liveFixedPrice.length === 0 && previousBids.length === 0) {
      console.warn(`⏭ Skipping property ${i}: no active listings`);
      continue;
    }

    console.log(`✅ Processing property ${i}`);

    const propertyData = {
      id: Number(results[0].Location[i].id),
      image: misc.images?.[0]?.[1] ?? "placeholder.jpg",
      addressLine2: location.addressLine2,
      city: location.location,
      outcode: location.postcode?.slice(0, 4),
      collectionId: collectionId
    };

    appendAllListings(propertyData, liveAuctions, liveFixedPrice, previousBids);
  }
}


function appendAllListings(property, liveAuctionsArr, liveFixedPrice, previousBidsArr){
  console.log("append listings is called")
  console.log(liveFixedPrice);
  let liveAuctions = document.getElementById("auctionListingsLive");
  liveAuctions.innerHTML = "";
  liveAuctionsArr.forEach(auction => {
    liveAuctions.insertAdjacentHTML( "beforeend", createAuctionListing(property, auction))
  });

  let liveFixedPriceListings = document.getElementById("buyNowListingsLive");
  liveFixedPriceListings.innerHTML = "";
  liveFixedPrice.forEach(fixedPrice =>{
    liveFixedPriceListings.insertAdjacentHTML( "beforeend", createFixedPriceListing(property, fixedPrice));
  });

  let previousBids = document.getElementById("bids-section");
  previousBids.innerHTML = "";
  console.log();
  previousBidsArr.forEach(bid => {
    console.log("Previous bid, build card, being called", bid)
    previousBids.insertAdjacentHTML( "beforeend", createBidCardHTML(bid, property));
  });

}
