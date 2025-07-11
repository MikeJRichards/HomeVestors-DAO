


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
