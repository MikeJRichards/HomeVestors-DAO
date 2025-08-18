import {getCanister, getPrincipal, wireConnect} from "./Main.js";
import {setupModal, currency, carousel} from "./All.js";
import { Principal } from "@dfinity/principal";
import { render } from "lit-html";

var data = null;
wireConnect("connect_btn", "NavWallet");
setupModal("view-tennantlog", "tenantLogModal", "closeTenantLogModal");
setupModal("view-rentalprofit", "rentalProfitModal", "closeRentalProfitModal");
setupModal("view-prpertyvalue", "PropertyValueModal", "closePropertyValueModal");
setupModal("view-inspections", "InspectionsModal", "closeInspectionsModal");
setupModal("view-maintenance", "MaintenanceModal", "closeMaintenanceModal");
setupModal("view-nftvalue", "NFTvalueModal", "closeNFTvalueModal");
setupModal("view-paymentlog", "PaymentLogModal", "closePaymentLogModal");
setupModal("view-occupency", "OccupencyModal", "closeOccupencyModal");
setupModal("view-activityModal", "ActivityModal", "closeActivityModal");

async function renderData(){
    await fetchProperty();
    setImage();
    summaryCard();
    renderDocuments();
    renderValuations();
    renderInspections();
    renderMaintenanceTable();
    renderProposals();
    renderActivity();
    renderPropertyValueModal();
    renderInspectionsModal();
    renderMaintenanceModal();
    renderActivityModal();
}

function nsToDate(ns) {
  if (!ns) return null;
  const nsBig = BigInt(ns);
  const msBig = nsBig / 1_000_000n;
  return new Date(Number(msBig));
}

export async function selectProperty(dropdownId) {
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

    const nftCalls = results[1].CollectionIds
      .filter(c => "Ok" in c.value)
      .map(async (c) => {
        let nftBackend = await getCanister("nft", c.value.Ok.toText());
        let tokens = await nftBackend.icrc7_tokens_of(account, [], []);
        return { id: Number(c.id), tokens };
      });

    const nfts = await Promise.all(nftCalls);
    console.log("NFTs", nfts);

    const ownedIds = nfts.filter(n => n.tokens.length > 0).map(n => n.id);

    const dropdown = document.getElementById(dropdownId);
    dropdown.innerHTML = "";

    if (ownedIds.length === 0) {
      const option = document.createElement("option");
      option.disabled = true;
      option.selected = true;
      option.textContent = "No owned properties available";
      dropdown.appendChild(option);
      return ownedIds;
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

    if (dropdown.options.length > 0) {
      dropdown.options[0].selected = true;
      const url = new URL(window.location);
      url.searchParams.set('id', dropdown.value);
      window.history.replaceState({}, '', url);
      document.getElementById("proposalView").href = `./MyProposals.html?id=${dropdown.value}`;
    }

    dropdown.addEventListener('change', () => {
      const url = new URL(window.location);
      url.searchParams.set('id', dropdown.value);
      window.history.replaceState({}, '', url);
      document.getElementById("proposalView").href = `./MyProposals.html?id=${dropdown.value}`;
      renderData();
    });

    return ownedIds;

  } catch (err) {
    console.error("❌ Error calling select property:", err);
    return [];
  }
}
selectProperty("propertyDropdown");

async function fetchProperty() {
  try {
    const raw = new URLSearchParams(window.location.search).get("id");
    const propertyId = BigInt(raw);

    const readArgs = [
      { Physical: [[propertyId]] },
      { Location: [[propertyId]] },
      { Financials: [[propertyId]] },
      { Additional: [[propertyId]] },
      { Misc: [[propertyId]] },
      { Images: { Properties: [[propertyId]] } },
      { Tenants: { Properties: [[propertyId]] } },
      { Document: { Properties: [[propertyId]] } },
      { Inspection: { Properties: [[propertyId]] } },
      { Proposals: {
          base: { Properties: [[propertyId]] },
          conditionals: {
            category: [], implementationCategory: [],
            actions: [], status: [], creator: [],
            eligibleCount: [], totalVoterCount: [],
            yesVotes: [], noVotes: [], startAt: [],
            outcome: [], voted: []
          }
        }
      },
      { UpdateResults: { selected: [[propertyId]], conditional: { Ok: null } } },
      { Maintenance: { Properties: [[propertyId]] } },
      { Invoices: {
          base: { Properties: [[propertyId]] },
          conditionals: {
            status: [], direction: [], amount: [], due: [],
            paymentStatus: [], paymentMethod: [], recurrenceType: [],
            notRecurrenceType: [], recurrenceEndAt: []
          }
        }
      }
    ];

    let backend = await getCanister("backend");
    const results = await backend.readProperties(readArgs, []);
    console.log("fetchProperty:results", results);

    const safeGet = (path, fallback = null) => {
      try {
        let val = path();
        if (val && typeof val === "object") {
          if ("Ok" in val) return val.Ok;
          if ("Err" in val) return fallback;
        }
        return Array.isArray(val) ? val : fallback;
      } catch (e) {
        console.error("safeGet error:", e, "Path:", path.toString());
        return fallback;
      }
    };

    data = {
      physical:      safeGet(() => results[0].Physical[0].value, {}),
      location:      safeGet(() => results[1].Location[0].value, {}),
      financials:    safeGet(() => results[2].Financials[0].value, {}),
      additional:    safeGet(() => results[3].Additional[0].value, {}),
      misc:          safeGet(() => results[4].Misc[0].value, {}),
      Image:         safeGet(() => results[5].Image[0].result.Ok[0], {}),
      tenants:       safeGet(() => results[6].Tenants[0].result, []),
      documents:     safeGet(() => results[7].Document[0].result, []),
      inspections:   safeGet(() => results[8].Inspection[0].result, []),
      proposal:      safeGet(() => results[9].Proposals[0].result, []),
      UpdateResults: safeGet(() => results[10].UpdateResults[0].value, []),
      Maintenance:   safeGet(() => results[11].Maintenance[0].result, []),
      invoices:      safeGet(() => results[12].Invoices[0].result, [])
    };

    console.log("fetchProperty: Processed Data", data);
    window.data = data;

  } catch (e) {
    console.error("fetchProperty:error", e);
  }
}

renderData();

function setImage(){
    if (data?.misc?.images?.length > 0) {
        console.log("setImages:to", data.misc.images[0][1]);
        document.getElementById("Thumbnail_Img").src = data.misc.images[0][1];
    } else {
        console.log("No images available");
    }
}

function summaryCard(){
    document.querySelector('[data-role="CurrentValue"]').textContent = currency(data.financials?.currentValue ?? 0);
    document.querySelector('[data-role="CurrentRent"]').textContent = currency(data.financials?.monthlyRent ?? 0);
}

function renderDocuments() {
  const container = document.getElementById("Documents");
  if (!container) {
    console.error("Documents container not found in DOM");
    return;
  }

  container.innerHTML = `<p class="h3 bold-text-p mhSummary">Documents</p>`;

  const documents = Array.isArray(data?.documents) ? data.documents : [];
  if (documents.length === 0) {
    const noData = container.querySelector("#no-data-documents") || document.createElement("p");
    noData.id = "no-data-documents";
    noData.className = "text-p no-data";
    noData.textContent = "There's no data to display";
    if (!container.contains(noData)) container.appendChild(noData);
    return;
  } else {
    const noData = container.querySelector("#no-data-documents");
    if (noData) noData.classList.add("hidden");
  }

  documents.forEach(item => {
    if (!item?.value?.Ok) return;

    const doc = item.value.Ok;
    const docType = Object.keys(doc.documentType)[0];

    const link = document.createElement("a");
    link.className = "text-p aDoc";
    link.dataset.role = docType;
    link.href = doc.url;
    link.target = "_blank";
    link.textContent = `${doc.title} (${docType})`;

    container.appendChild(link);
    container.appendChild(document.createElement("br"));
  });
}

function renderValuations() {
  const card = document.getElementById("PropertyValue");
  if (!card) {
    console.error("PropertyValue card not found in DOM");
    return;
  }
  const tableContainer = card.querySelector(".mh-tables-container");
  const viewContainer = card.querySelector(".view-container");
  const table = document.getElementById("PropertyValueTable");
  if (!tableContainer || !table) {
    console.error("PropertyValue table or container not found in DOM");
    return;
  }
  const tableBody = table.querySelector("tbody");
  tableBody.innerHTML = "";

  const valuations = Array.isArray(data?.financials?.valuations) ? data.financials.valuations : [];
  console.log("renderValuations: valuations", valuations);

  const noData = tableContainer.querySelector("#no-data-valuations") || document.createElement("p");
  noData.id = "no-data-valuations";
  noData.className = "text-p no-data";
  noData.textContent = "There's no data to display";

  if (valuations.length === 0) {
    console.log("renderValuations: No valuation records, hiding table");
    table.classList.add("hidden");
    if (!tableContainer.contains(noData)) tableContainer.appendChild(noData);
    noData.classList.remove("hidden");
    if (viewContainer) viewContainer.style.display = "none";
    return;
  } else {
    table.classList.remove("hidden");
    if (tableContainer.contains(noData)) noData.classList.add("hidden");
    if (viewContainer) viewContainer.style.display = "";
  }

  valuations.forEach(entry => {
    const [id, val] = entry;
    if (!val.date) {
      console.warn("Skipping valuation without date:", val);
      return;
    }

    const date = nsToDate(val.date);
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const year = date.getFullYear();
    const formattedDate = `${month}/${year}`;

    const formattedValue = `£${Number(val.value).toLocaleString()}`;

    const tr = document.createElement("tr");

    const tdDate = document.createElement("td");
    tdDate.className = "Month-date";
    tdDate.textContent = formattedDate;

    const tdVal = document.createElement("td");
    tdVal.className = "propVal";
    tdVal.textContent = formattedValue;

    tr.appendChild(tdDate);
    tr.appendChild(tdVal);
    tableBody.appendChild(tr);
  });
}

function renderInspections() {
  console.log("renderInspections: data.inspections", data?.inspections);

  const card = document.getElementById("Inspections");
  if (!card) {
    console.error("Inspections card not found in DOM");
    return;
  }
  const tableContainer = card.querySelector(".mh-tables-container");
  const viewContainer = card.querySelector(".view-container");
  const table = document.getElementById("InspectionsTable");
  if (!tableContainer || !table) {
    console.error("Inspections table or container not found in DOM");
    return;
  }
  const tableBody = table.querySelector("tbody");
  tableBody.innerHTML = "";

  const inspections = Array.isArray(data?.inspections) ? data.inspections : [];
  console.log("renderInspections: inspections", inspections);

  const noData = tableContainer.querySelector("#no-data-inspections") || document.createElement("p");
  noData.id = "no-data-inspections";
  noData.className = "text-p no-data";
  noData.textContent = "There's no data to display";

  if (inspections.length === 0) {
    console.log("renderInspections: No inspection records, hiding table");
    table.classList.add("hidden");
    if (!tableContainer.contains(noData)) tableContainer.appendChild(noData);
    noData.classList.remove("hidden");
    if (viewContainer) viewContainer.style.display = "none";
    return;
  } else {
    table.classList.remove("hidden");
    if (tableContainer.contains(noData)) noData.classList.add("hidden");
    if (viewContainer) viewContainer.style.display = "";
  }

  inspections.forEach(item => {
    if (!item?.value?.Ok) return;

    const inspection = item.value.Ok;
    let formattedDate = "Unknown";
    if (inspection.date && inspection.date.length > 0) {
      const nsBig = BigInt(inspection.date[0]);
      const ms = Number(nsBig / 1_000_000n);
      const date = new Date(ms);
      const day = String(date.getDate()).padStart(2, "0");
      const month = String(date.getMonth() + 1).padStart(2, "0");
      const year = date.getFullYear();
      formattedDate = `${day}/${month}/${year}`;
    }

    const feedback = inspection.findings || "No feedback";

    const tr = document.createElement("tr");

    const tdDate = document.createElement("td");
    tdDate.className = "date";
    tdDate.textContent = formattedDate;

    const tdFeedback = document.createElement("td");
    tdFeedback.className = "inspectionResult";
    tdFeedback.textContent = feedback;

    const tdReport = document.createElement("td");
    const link = document.createElement("a");
    link.className = "text-p aDocMainBody";
    link.dataset.role = "inspectionDoc";
    link.href = "#";
    link.textContent = "Document";
    tdReport.appendChild(link);

    tr.appendChild(tdDate);
    tr.appendChild(tdFeedback);
    tr.appendChild(tdReport);

    tableBody.appendChild(tr);
  });
}

function renderProposals() {
  const card = document.getElementById("Proposals");
  if (!card) {
    console.error("Proposals card not found in DOM");
    return;
  }
  const tableContainer = card.querySelector(".mh-tables-container");
  const viewContainer = card.querySelector(".view-container");
  const table = document.getElementById("ProposalsTable");
  if (!tableContainer || !table) {
    console.error("Proposals table or container not found in DOM");
    return;
  }
  const tableBody = table.querySelector("tbody");
  tableBody.innerHTML = "";

  const proposals = Array.isArray(data?.proposal) ? data.proposal : [];
  console.log("renderProposals: proposals", proposals);

  const noData = tableContainer.querySelector("#no-data-proposals") || document.createElement("p");
  noData.id = "no-data-proposals";
  noData.className = "text-p no-data";
  noData.textContent = "There's no data to display";

  if (proposals.length === 0) {
    console.log("renderProposals: No proposal records, hiding table");
    table.classList.add("hidden");
    if (!tableContainer.contains(noData)) tableContainer.appendChild(noData);
    noData.classList.remove("hidden");
    if (viewContainer) viewContainer.style.display = "none";
    return;
  } else {
    table.classList.remove("hidden");
    if (tableContainer.contains(noData)) noData.classList.add("hidden");
    if (viewContainer) viewContainer.style.display = "";
  }

  proposals.forEach(item => {
    const id = item.id;
    const wrapped = item.value;

    if (!wrapped?.Ok) return;
    const prop = wrapped.Ok;

    const ms = Number(BigInt(prop.createdAt) / 1_000_000n);
    const dateObj = new Date(ms);
    const day = String(dateObj.getDate()).padStart(2, "0");
    const month = String(dateObj.getMonth() + 1).padStart(2, "0");
    const year = dateObj.getFullYear();
    const formattedDate = `${day}/${month}/${year}`;

    const title = prop.title || "Untitled";
    const category = Object.keys(prop.category)[0] || "Uncategorised";
    const status = Object.keys(prop.status)[0] || "Unknown";

    const tr = document.createElement("tr");

    const tdDate = document.createElement("td");
    tdDate.className = "date";
    tdDate.textContent = formattedDate;

    const tdProposal = document.createElement("td");
    tdProposal.className = "proposal";
    tdProposal.textContent = title;

    const tdCategory = document.createElement("td");
    tdCategory.className = "catagory";
    tdCategory.textContent = category;

    const tdStatus = document.createElement("td");
    tdStatus.className = "status";
    tdStatus.textContent = status.replace("Proposal", "");

    tr.appendChild(tdDate);
    tr.appendChild(tdProposal);
    tr.appendChild(tdCategory);
    tr.appendChild(tdStatus);

    tableBody.appendChild(tr);
  });
}

function describeActivity(what) {
  if (what.Tenant) {
    const action = what.Tenant;
    if (action.Create) return "New tenant added";
    if (action.Update) return "Tenant details updated";
    if (action.Delete) return "Tenant removed";
  }

  if (what.Inspection) {
    const action = what.Inspection;
    if (action.Create) return "New inspection recorded";
    if (action.Update) return "Inspection updated";
    if (action.Delete) return "Inspection deleted";
  }

  if (what.Invoice) {
    const action = what.Invoice;
    if (action.Create) return "Invoice created";
    if (action.Update) return "Invoice updated";
    if (action.Delete) return "Invoice deleted";
  }

  if (what.Insurance) {
    const action = what.Insurance;
    if (action.Create) return "Insurance policy created";
    if (action.Update) return "Insurance updated";
    if (action.Delete) return "Insurance deleted";
  }

  if (what.Images) {
    const action = what.Images;
    if (action.Create) return `Added ${action.Create.length} image(s)`;
    if (action.Update) return "Images updated";
    if (action.Delete) return "Image(s) deleted";
  }

  if (what.Note) {
    const action = what.Note;
    if (action.Create) return "Note added";
    if (action.Update) return "Note updated";
    if (action.Delete) return "Note deleted";
  }

  if (what.Description) {
    return "Description updated";
  }

  if (what.Document) {
    const action = what.Document;
    if (action.Create) return "Document uploaded";
    if (action.Update) return "Document updated";
    if (action.Delete) return "Document deleted";
  }

  if (what.Valuations) {
    const action = what.Valuations;
    if (action.Create) return "Valuation created";
    if (action.Update) return "Valuation updated";
    if (action.Delete) return "Valuation deleted";
  }

  if (what.Maintenance) {
    const action = what.Maintenance;
    if (action.Create) return "Maintenance request created";
    if (action.Update) return "Maintenance updated";
    if (action.Delete) return "Maintenance deleted";
  }

  if (what.MonthlyRent !== undefined) {
    return `Monthly rent updated`;
  }

  if (what.Financials) {
    return `Financials updated`;
  }

  if (what.AdditionalDetails) {
    return "Additional property details updated";
  }

  if (what.Governance) {
    if (what.Governance.Vote) return "Vote cast on proposal";
    if (what.Governance.Proposal) {
      const action = what.Governance.Proposal;
      if (action.Create) return "Proposal created";
      if (action.Update) return "Proposal updated";
      if (action.Delete) return "Proposal deleted";
    }
  }

  if (what.PhysicalDetails) {
    return "Physical property details updated";
  }

  if (what.NftMarketplace) {
    if (what.NftMarketplace.Bid) return "NFT bid placed";
    if (what.NftMarketplace.Launch) return "NFT launch created";
    if (what.NftMarketplace.Auction) return "NFT auction created";
    if (what.NftMarketplace.FixedPrice) return "NFT fixed-price listing created";
  }

  return "Unknown activity";
}

function renderActivity() {
  const card = document.getElementById("Activity");
  if (!card) {
    console.error("Activity card not found in DOM");
    return;
  }
  const tableContainer = card.querySelector(".mh-tables-container");
  const viewContainer = card.querySelector(".view-container");
  const table = document.getElementById("ActivityTable");
  if (!tableContainer || !table) {
    console.error("Activity table or container not found in DOM");
    return;
  }
  const tableBody = table.querySelector("tbody");
  tableBody.innerHTML = "";

  const updates = Array.isArray(data?.UpdateResults) ? data.UpdateResults.slice(-10) : [];
  console.log("renderActivity: updates", updates);

  const noData = tableContainer.querySelector("#no-data-activity") || document.createElement("p");
  noData.id = "no-data-activity";
  noData.className = "text-p no-data";
  noData.textContent = "There's no data to display";

  if (updates.length === 0) {
    console.log("renderActivity: No activity records, hiding table");
    table.classList.add("hidden");
    if (!tableContainer.contains(noData)) tableContainer.appendChild(noData);
    noData.classList.remove("hidden");
    if (viewContainer) viewContainer.style.display = "none";
    return;
  } else {
    table.classList.remove("hidden");
    if (tableContainer.contains(noData)) noData.classList.add("hidden");
    if (viewContainer) viewContainer.style.display = "";
  }

  updates.forEach(update => {
    if (!update?.Ok) return;

    const what = update.Ok.what;
    const activityText = describeActivity(what);

    let formattedDate = "N/A";
    if (update.Ok.createdAt) {
      const ms = Number(BigInt(update.Ok.createdAt) / 1_000_000n);
      formattedDate = new Date(ms).toLocaleDateString("en-GB");
    }

    const tr = document.createElement("tr");

    const tdDate = document.createElement("td");
    tdDate.className = "date";
    tdDate.textContent = formattedDate;

    const tdActivity = document.createElement("td");
    tdActivity.className = "activity";
    tdActivity.textContent = activityText;

    tr.appendChild(tdDate);
    tr.appendChild(tdActivity);

    tableBody.appendChild(tr);
  });
}

function describeActivityDetails(what) {
  const formatDate = (ns) => {
    if (!ns) return "N/A";
    const date = nsToDate(ns);
    return date ? date.toLocaleDateString("en-GB") : "N/A";
  };

  const formatPrincipal = (principal) => {
    return principal?.toText?.() || "N/A";
  };

  const formatVariant = (variant) => {
    if (!variant) return "N/A";
    const key = Object.keys(variant)[0];
    if (key === "Other") return variant[key] || "N/A";
    return key || "N/A";
  };

  const formatOpt = (opt, formatter = (x) => x) => {
    return opt && opt.length > 0 ? formatter(opt[0]) : "N/A";
  };

  const formatArray = (arr, formatter = (x) => x) => {
    return arr && arr.length > 0 ? arr.map(formatter).join(", ") : "N/A";
  };

  const formatBigInt = (big) => {
    return big ? Number(big).toLocaleString() : "N/A";
  };

  const formatFloat = (fl) => {
    return fl ? fl.toFixed(2) : "N/A";
  };

  const getDetails = (labelValuePairs) => labelValuePairs.filter(pair => pair.value !== "N/A");

  if (what.Tenant) {
    const action = what.Tenant;
    if (action.Create && action.Create.length > 0) {
      return action.Create.map(tenant => ({
        action: "New tenant added",
        details: getDetails([
          { label: "Lead Tenant", value: tenant.leadTenant || "N/A" },
          { label: "Monthly Rent", value: tenant.monthlyRent ? `£${formatBigInt(tenant.monthlyRent)}` : "N/A" },
          { label: "Lease Start", value: formatDate(tenant.leaseStartDate) },
          { label: "Contract Length", value: formatVariant(tenant.contractLength) },
          { label: "Other Tenants", value: formatArray(tenant.otherTenants) },
          { label: "Deposit", value: tenant.deposit ? `£${formatBigInt(tenant.deposit)}` : "N/A" }
        ])
      }));
    }
    if (action.Update) {
      const [updateArg, ids] = action.Update;
      return [{
        action: "Tenant details updated",
        details: getDetails([
          { label: "Updated IDs", value: formatArray(ids, id => formatBigInt(id)) },
          { label: "Updated Monthly Rent", value: formatOpt(updateArg.monthlyRent, rent => `£${formatBigInt(rent)}`) },
          { label: "Updated Lease Start", value: formatOpt(updateArg.leaseStartDate, formatDate) },
          { label: "Updated Contract Length", value: formatOpt(updateArg.contractLength, formatVariant) }
        ])
      }];
    }
    if (action.Delete) {
      return [{
        action: "Tenant removed",
        details: getDetails([
          { label: "Deleted IDs", value: formatArray(action.Delete, id => formatBigInt(id)) }
        ])
      }];
    }
  }

  if (what.Inspection) {
    const action = what.Inspection;
    if (action.Create && action.Create.length > 0) {
      return action.Create.map(inspection => ({
        action: "New inspection recorded",
        details: getDetails([
          { label: "Date", value: formatOpt(inspection.date, formatDate) },
          { label: "Inspector Name", value: inspection.inspectorName || "N/A" },
          { label: "Findings", value: inspection.findings || "N/A" },
          { label: "Action Required", value: formatOpt(inspection.actionRequired) },
          { label: "Follow Up Date", value: formatOpt(inspection.followUpDate, formatDate) }
        ])
      }));
    }
    if (action.Update) {
      const [updateArg, ids] = action.Update;
      return [{
        action: "Inspection updated",
        details: getDetails([
          { label: "Updated IDs", value: formatArray(ids, id => formatBigInt(id)) },
          { label: "Updated Date", value: formatOpt(updateArg.date, formatDate) },
          { label: "Updated Inspector Name", value: formatOpt(updateArg.inspectorName) },
          { label: "Updated Findings", value: formatOpt(updateArg.findings) }
        ])
      }];
    }
    if (action.Delete) {
      return [{
        action: "Inspection deleted",
        details: getDetails([
          { label: "Deleted IDs", value: formatArray(action.Delete, id => formatBigInt(id)) }
        ])
      }];
    }
  }

  if (what.Invoice) {
    const action = what.Invoice;
    if (action.Create && action.Create.length > 0) {
      return action.Create.map(invoice => ({
        action: "Invoice created",
        details: getDetails([
          { label: "Title", value: invoice.title || "N/A" },
          { label: "Amount", value: invoice.amount ? `£${formatBigInt(invoice.amount)}` : "N/A" },
          { label: "Due Date", value: formatDate(invoice.dueDate) },
          { label: "Description", value: invoice.description || "N/A" },
          { label: "Payment Method", value: formatOpt(invoice.paymentMethod, formatVariant) }
        ])
      }));
    }
    if (action.Update) {
      const [updateArg, ids] = action.Update;
      return [{
        action: "Invoice updated",
        details: getDetails([
          { label: "Updated IDs", value: formatArray(ids, id => formatBigInt(id)) },
          { label: "Updated Title", value: formatOpt(updateArg.title) },
          { label: "Updated Amount", value: formatOpt(updateArg.amount, amt => `£${formatBigInt(amt)}`) },
          { label: "Updated Due Date", value: formatOpt(updateArg.dueDate, formatDate) }
        ])
      }];
    }
    if (action.Delete) {
      return [{
        action: "Invoice deleted",
        details: getDetails([
          { label: "Deleted IDs", value: formatArray(action.Delete, id => formatBigInt(id)) }
        ])
      }];
    }
  }

  if (what.Insurance) {
    const action = what.Insurance;
    if (action.Create && action.Create.length > 0) {
      return action.Create.map(insurance => ({
        action: "Insurance policy created",
        details: getDetails([
          { label: "Provider", value: insurance.provider || "N/A" },
          { label: "Policy Number", value: insurance.policyNumber || "N/A" },
          { label: "Premium", value: insurance.premium ? `£${formatBigInt(insurance.premium)}` : "N/A" },
          { label: "Start Date", value: formatDate(insurance.startDate) },
          { label: "End Date", value: formatOpt(insurance.endDate, formatDate) },
          { label: "Payment Frequency", value: formatVariant(insurance.paymentFrequency) },
          { label: "Next Payment Date", value: formatDate(insurance.nextPaymentDate) },
          { label: "Contact Info", value: insurance.contactInfo || "N/A" }
        ])
      }));
    }
    if (action.Update) {
      const [updateArg, ids] = action.Update;
      return [{
        action: "Insurance updated",
        details: getDetails([
          { label: "Updated IDs", value: formatArray(ids, id => formatBigInt(id)) },
          { label: "Updated Provider", value: formatOpt(updateArg.provider) },
          { label: "Updated Premium", value: formatOpt(updateArg.premium, prem => `£${formatBigInt(prem)}`) },
          { label: "Updated Start Date", value: formatOpt(updateArg.startDate, formatDate) }
        ])
      }];
    }
    if (action.Delete) {
      return [{
        action: "Insurance deleted",
        details: getDetails([
          { label: "Deleted IDs", value: formatArray(action.Delete, id => formatBigInt(id)) }
        ])
      }];
    }
  }

  if (what.Images) {
    const action = what.Images;
    if (action.Create && action.Create.length > 0) {
      return action.Create.map(url => ({
        action: "Image added",
        details: getDetails([
          { label: "Image URL", value: url || "N/A" }
        ])
      }));
    }
    if (action.Update) {
      const [updated, ids] = action.Update;
      return [{
        action: "Images updated",
        details: getDetails([
          { label: "Updated IDs", value: formatArray(ids, id => formatBigInt(id)) },
          { label: "Updated URL", value: updated || "N/A" }
        ])
      }];
    }
    if (action.Delete) {
      return [{
        action: "Image(s) deleted",
        details: getDetails([
          { label: "Deleted IDs", value: formatArray(action.Delete, id => formatBigInt(id)) }
        ])
      }];
    }
  }

  if (what.Note) {
    const action = what.Note;
    if (action.Create && action.Create.length > 0) {
      return action.Create.map(note => ({
        action: "Note added",
        details: getDetails([
          { label: "Title", value: note.title || "N/A" },
          { label: "Content", value: note.content || "N/A" },
          { label: "Date", value: formatOpt(note.date, formatDate) }
        ])
      }));
    }
    if (action.Update) {
      const [updateArg, ids] = action.Update;
      return [{
        action: "Note updated",
        details: getDetails([
          { label: "Updated IDs", value: formatArray(ids, id => formatBigInt(id)) },
          { label: "Updated Title", value: formatOpt(updateArg.title) },
          { label: "Updated Content", value: formatOpt(updateArg.content) },
          { label: "Updated Date", value: formatOpt(updateArg.date, formatDate) }
        ])
      }];
    }
    if (action.Delete) {
      return [{
        action: "Note deleted",
        details: getDetails([
          { label: "Deleted IDs", value: formatArray(action.Delete, id => formatBigInt(id)) }
        ])
      }];
    }
  }

  if (what.Description) {
    return [{
      action: "Description updated",
      details: getDetails([
        { label: "New Description", value: what.Description || "N/A" }
      ])
    }];
  }

  if (what.Document) {
    const action = what.Document;
    if (action.Create && action.Create.length > 0) {
      return action.Create.map(doc => ({
        action: "Document uploaded",
        details: getDetails([
          { label: "Title", value: doc.title || "N/A" },
          { label: "URL", value: doc.url || "N/A" },
          { label: "Document Type", value: formatVariant(doc.documentType) },
          { label: "Description", value: doc.description || "N/A" }
        ])
      }));
    }
    if (action.Update) {
      const [updateArg, ids] = action.Update;
      return [{
        action: "Document updated",
        details: getDetails([
          { label: "Updated IDs", value: formatArray(ids, id => formatBigInt(id)) },
          { label: "Updated Title", value: formatOpt(updateArg.title) },
          { label: "Updated URL", value: formatOpt(updateArg.url) },
          { label: "Updated Description", value: formatOpt(updateArg.description) }
        ])
      }];
    }
    if (action.Delete) {
      return [{
        action: "Document deleted",
        details: getDetails([
          { label: "Deleted IDs", value: formatArray(action.Delete, id => formatBigInt(id)) }
        ])
      }];
    }
  }

  if (what.Valuations) {
    const action = what.Valuations;
    if (action.Create && action.Create.length > 0) {
      return action.Create.map(valuation => ({
        action: "Valuation created",
        details: getDetails([
          { label: "Value", value: valuation.value ? `£${formatBigInt(valuation.value)}` : "N/A" },
          { label: "Method", value: formatVariant(valuation.method) },
          { label: "Appraiser", value: formatPrincipal(valuation.appraiser) }
        ])
      }));
    }
    if (action.Update) {
      const [updateArg, ids] = action.Update;
      return [{
        action: "Valuation updated",
        details: getDetails([
          { label: "Updated IDs", value: formatArray(ids, id => formatBigInt(id)) },
          { label: "Updated Value", value: formatOpt(updateArg.value, val => `£${formatBigInt(val)}`) },
          { label: "Updated Method", value: formatOpt(updateArg.method, formatVariant) }
        ])
      }];
    }
    if (action.Delete) {
      return [{
        action: "Valuation deleted",
        details: getDetails([
          { label: "Deleted IDs", value: formatArray(action.Delete, id => formatBigInt(id)) }
        ])
      }];
    }
  }

  if (what.Maintenance) {
    const action = what.Maintenance;
    if (action.Create && action.Create.length > 0) {
      return action.Create.map(maint => ({
        action: "Maintenance request created",
        details: getDetails([
          { label: "Description", value: maint.description || "N/A" },
          { label: "Cost", value: formatOpt(maint.cost, c => `£${formatFloat(c)}`) },
          { label: "Date Reported", value: formatOpt(maint.dateReported, formatDate) },
          { label: "Date Completed", value: formatOpt(maint.dateCompleted, formatDate) },
          { label: "Contractor", value: formatOpt(maint.contractor) },
          { label: "Status", value: formatVariant(maint.status) },
          { label: "Payment Method", value: formatOpt(maint.paymentMethod, formatVariant) }
        ])
      }));
    }
    if (action.Update) {
      const [updateArg, ids] = action.Update;
      return [{
        action: "Maintenance updated",
        details: getDetails([
          { label: "Updated IDs", value: formatArray(ids, id => formatBigInt(id)) },
          { label: "Updated Description", value: formatOpt(updateArg.description) },
          { label: "Updated Cost", value: formatOpt(updateArg.cost, c => `£${formatFloat(c)}`) },
          { label: "Updated Status", value: formatOpt(updateArg.status, formatVariant) }
        ])
      }];
    }
    if (action.Delete) {
      return [{
        action: "Maintenance deleted",
        details: getDetails([
          { label: "Deleted IDs", value: formatArray(action.Delete, id => formatBigInt(id)) }
        ])
      }];
    }
  }

  if (what.MonthlyRent !== undefined) {
    return [{
      action: "Monthly rent updated",
      details: getDetails([
        { label: "New Rent", value: `£${formatBigInt(what.MonthlyRent)}` }
      ])
    }];
  }

  if (what.Financials) {
    return [{
      action: "Financials updated",
      details: getDetails([
        { label: "Current Value", value: `£${formatBigInt(what.Financials.currentValue)}` }
      ])
    }];
  }

  if (what.AdditionalDetails) {
    return [{
      action: "Additional property details updated",
      details: getDetails([
        { label: "School Score", value: what.AdditionalDetails.schoolScore ? Number(what.AdditionalDetails.schoolScore) : "N/A" },
        { label: "Affordability", value: what.AdditionalDetails.affordability ? Number(what.AdditionalDetails.affordability) : "N/A" },
        { label: "Flood Zone", value: what.AdditionalDetails.floodZone ? "Yes" : "No" },
        { label: "Crime Score", value: what.AdditionalDetails.crimeScore ? Number(what.AdditionalDetails.crimeScore) : "N/A" }
      ])
    }];
  }

  if (what.Governance) {
    if (what.Governance.Vote) {
      return [{
        action: "Vote cast on proposal",
        details: getDetails([
          { label: "Proposal ID", value: formatBigInt(what.Governance.Vote.proposalId) },
          { label: "Vote", value: what.Governance.Vote.vote ? "Yes" : "No" }
        ])
      }];
    }
    if (what.Governance.Proposal) {
      const action = what.Governance.Proposal;
      if (action.Create && action.Create.length > 0) {
        return action.Create.map(prop => ({
          action: "Proposal created",
          details: getDetails([
            { label: "Title", value: prop.title || "N/A" },
            { label: "Description", value: prop.description || "N/A" },
            { label: "Category", value: formatVariant(prop.category) },
            { label: "Implementation", value: formatVariant(prop.implementation) },
            { label: "Start At", value: formatDate(prop.startAt) }
          ])
        }));
      }
      if (action.Update) {
        const [updateArg, ids] = action.Update;
        return [{
          action: "Proposal updated",
          details: getDetails([
            { label: "Updated IDs", value: formatArray(ids, id => formatBigInt(id)) },
            { label: "Updated Title", value: formatOpt(updateArg.title) },
            { label: "Updated Description", value: formatOpt(updateArg.description) },
            { label: "Updated Category", value: formatOpt(updateArg.category, formatVariant) }
          ])
        }];
      }
      if (action.Delete) {
        return [{
          action: "Proposal deleted",
          details: getDetails([
            { label: "Deleted IDs", value: formatArray(action.Delete, id => formatBigInt(id)) }
          ])
        }];
      }
    }
  }

  if (what.PhysicalDetails) {
    return [{
      action: "Physical property details updated",
      details: getDetails([
        { label: "Beds", value: formatOpt(what.PhysicalDetails.beds, Number) },
        { label: "Baths", value: formatOpt(what.PhysicalDetails.baths, Number) },
        { label: "Square Footage", value: formatOpt(what.PhysicalDetails.squareFootage, Number) },
        { label: "Year Built", value: formatOpt(what.PhysicalDetails.yearBuilt, Number) },
        { label: "Last Renovation", value: formatOpt(what.PhysicalDetails.lastRenovation, Number) }
      ])
    }];
  }

  if (what.NftMarketplace) {
    if (what.NftMarketplace.Bid) {
      return [{
        action: "NFT bid placed",
        details: getDetails([
          { label: "Listing ID", value: formatBigInt(what.NftMarketplace.Bid.listingId) },
          { label: "Bid Amount", value: `£${formatBigInt(what.NftMarketplace.Bid.bidAmount)}` }
        ])
      }];
    }
    if (what.NftMarketplace.Launch) {
      const action = what.NftMarketplace.Launch;
      if (action.Create && action.Create.length > 0) {
        return action.Create.map(launch => ({
          action: "NFT launch created",
          details: getDetails([
            { label: "Price", value: `£${formatBigInt(launch.price)}` },
            { label: "Quote Asset", value: formatOpt(launch.quoteAsset, formatVariant) },
            { label: "Max Listed", value: formatOpt(launch.maxListed, Number) },
            { label: "Ends At", value: formatOpt(launch.endsAt, formatDate) }
          ])
        }));
      }
      if (action.Update) return { action: "NFT launch updated", details: [] };
      if (action.Delete) return { action: "NFT launch deleted", details: [] };
    }
    if (what.NftMarketplace.Auction) {
      const action = what.NftMarketplace.Auction;
      if (action.Create && action.Create.length > 0) {
        return action.Create.map(auction => ({
          action: "NFT auction created",
          details: getDetails([
            { label: "Token ID", value: formatBigInt(auction.tokenId) },
            { label: "Starting Price", value: `£${formatBigInt(auction.startingPrice)}` },
            { label: "Start Time", value: formatDate(auction.startTime) },
            { label: "Ends At", value: formatDate(auction.endsAt) }
          ])
        }));
      }
      if (action.Update) return { action: "NFT auction updated", details: [] };
      if (action.Delete) return { action: "NFT auction deleted", details: [] };
    }
    if (what.NftMarketplace.FixedPrice) {
      const action = what.NftMarketplace.FixedPrice;
      if (action.Create && action.Create.length > 0) {
        return action.Create.map(fixed => ({
          action: "NFT fixed-price listing created",
          details: getDetails([
            { label: "Token ID", value: formatBigInt(fixed.tokenId) },
            { label: "Price", value: `£${formatBigInt(fixed.price)}` },
            { label: "Expires At", value: formatOpt(fixed.expiresAt, formatDate) }
          ])
        }));
      }
      if (action.Update) return { action: "NFT fixed-price listing updated", details: [] };
      if (action.Delete) return { action: "NFT fixed-price listing deleted", details: [] };
    }
  }

  return [{ action: "Unknown activity", details: [] }];
}

function renderActivityModal() {
  console.log("renderActivityModal: data.UpdateResults", data?.UpdateResults);

  const modal = document.getElementById("ActivityModal");
  if (!modal) {
    console.error("ActivityModal not found in DOM");
    return;
  }
  const modalContent = modal.querySelector(".modal-content");
  const table = document.getElementById("MT-ActivityTable");
  if (!modalContent || !table) {
    console.error("MT-ActivityTable or modal-content not found in DOM");
    return;
  }
  const thead = table.querySelector("thead");
  const tableBody = table.querySelector("tbody");
  thead.innerHTML = "";
  tableBody.innerHTML = "";

  const updates = Array.isArray(data?.UpdateResults) ? data.UpdateResults : [];
  console.log("renderActivityModal: updates", updates);

  const noData = modalContent.querySelector("#no-data-activity-modal") || document.createElement("p");
  noData.id = "no-data-activity-modal";
  noData.className = "text-p no-data";
  noData.textContent = "There's no data to display";

  if (updates.length === 0) {
    console.log("renderActivityModal: No activity records, hiding table");
    table.classList.add("hidden");
    if (!modalContent.contains(noData)) modalContent.appendChild(noData);
    noData.classList.remove("hidden");
    return;
  } else {
    table.classList.remove("hidden");
    if (modalContent.contains(noData)) noData.classList.add("hidden");
  }

  // Define base headers
  const baseHeaders = ["Date", "Action", "Details"];
  const headerRow = document.createElement("tr");
  baseHeaders.forEach(h => {
    const th = document.createElement("th");
    th.textContent = h;
    headerRow.appendChild(th);
  });
  thead.appendChild(headerRow);

  updates.forEach(update => {
    if (!update?.Ok) return;

    const what = update.Ok.what;
    const activityDetailsList = describeActivityDetails(what);

    let formattedDate = "N/A";
    if (update.Ok.createdAt) {
      const ms = Number(BigInt(update.Ok.createdAt) / 1_000_000n);
      formattedDate = new Date(ms).toLocaleDateString("en-GB");
    }

    activityDetailsList.forEach(activityDetails => {
      const tr = document.createElement("tr");

      const tdDate = document.createElement("td");
      tdDate.className = "date";
      tdDate.textContent = formattedDate;

      const tdAction = document.createElement("td");
      tdAction.className = "activity";
      tdAction.textContent = activityDetails.action;

      const tdDetails = document.createElement("td");
      if (activityDetails.details.length > 0) {
        const ul = document.createElement("ul");
        ul.style.margin = "0";
        ul.style.paddingLeft = "20px";
        activityDetails.details.forEach(detail => {
          const li = document.createElement("li");
          li.textContent = `${detail.label}: ${detail.value}`;
          ul.appendChild(li);
        });
        tdDetails.appendChild(ul);
      } else {
        tdDetails.textContent = "No additional details";
      }

      tr.appendChild(tdDate);
      tr.appendChild(tdAction);
      tr.appendChild(tdDetails);

      tableBody.appendChild(tr);
    });
  });
}

function nsToMonthYear(nsBigInt) {
  if (!nsBigInt) return "";
  const ms = Number(nsBigInt / 1000000n);
  const date = new Date(ms);
  return `${date.getMonth() + 1}/${date.getFullYear()}`;
}

function renderPropertyValueModal() {
  const modal = document.getElementById("PropertyValueModal");
  if (!modal) {
    console.error("PropertyValueModal not found in DOM");
    return;
  }
  const modalContent = modal.querySelector(".modal-content");
  const table = document.getElementById("MT-PropertyValueTable");
  if (!modalContent || !table) {
    console.error("MT-PropertyValueTable or modal-content not found in DOM");
    return;
  }
  const tableBody = table.querySelector("tbody");
  tableBody.innerHTML = "";

  const valuations = Array.isArray(data?.financials?.valuations) ? data.financials.valuations : [];
  console.log("renderPropertyValueModal: valuations", valuations);

  const noData = modalContent.querySelector("#no-data-property-value") || document.createElement("p");
  noData.id = "no-data-property-value";
  noData.className = "text-p no-data";
  noData.textContent = "There's no data to display";

  if (valuations.length === 0) {
    console.log("renderPropertyValueModal: No valuation records, hiding table");
    table.classList.add("hidden");
    if (!modalContent.contains(noData)) modalContent.appendChild(noData);
    noData.classList.remove("hidden");
    return;
  } else {
    table.classList.remove("hidden");
    if (modalContent.contains(noData)) noData.classList.add("hidden");
  }

  valuations.forEach(([key, val]) => {
    if (!val) return;

    const row = document.createElement("tr");

    const idCell = document.createElement("td");
    idCell.textContent = val.id ? val.id.toString() : key.toString();
    row.appendChild(idCell);

    const dateCell = document.createElement("td");
    dateCell.textContent = nsToMonthYear(val.date);
    row.appendChild(dateCell);

    const valueCell = document.createElement("td");
    valueCell.textContent = `£${Number(val.value).toLocaleString()}`;
    row.appendChild(valueCell);

    const methodCell = document.createElement("td");
    methodCell.textContent = Object.keys(val.method || {})[0] || "";
    row.appendChild(methodCell);

    const appraiserCell = document.createElement("td");
    try {
      appraiserCell.textContent = val.appraiser?.toText?.() || "";
    } catch {
      appraiserCell.textContent = "[principal]";
    }
    row.appendChild(appraiserCell);

    tableBody.appendChild(row);
  });
}

function renderInspectionsModal() {
  const modal = document.getElementById("InspectionsModal");
  if (!modal) {
    console.error("InspectionsModal not found in DOM");
    return;
  }
  const modalContent = modal.querySelector(".modal-content");
  const table = document.getElementById("MT-InspectionsTable");
  if (!modalContent || !table) {
    console.error("MT-InspectionsTable or modal-content not found in DOM");
    return;
  }
  const tableBody = table.querySelector("tbody");
  tableBody.innerHTML = "";

  const inspections = Array.isArray(data?.inspections) ? data.inspections : [];
  console.log("renderInspectionsModal: inspections", inspections);

  const noData = modalContent.querySelector("#no-data-inspections-modal") || document.createElement("p");
  noData.id = "no-data-inspections-modal";
  noData.className = "text-p no-data";
  noData.textContent = "There's no data to display";

  if (inspections.length === 0) {
    console.log("renderInspectionsModal: No inspection records, hiding table");
    table.classList.add("hidden");
    if (!modalContent.contains(noData)) modalContent.appendChild(noData);
    noData.classList.remove("hidden");
    return;
  } else {
    table.classList.remove("hidden");
    if (modalContent.contains(noData)) noData.classList.add("hidden");
  }

  const nsToDate = (ns) => {
    if (!ns || ns.length === 0) return "No date provided";
    try {
      const ms = Number(ns[0] / 1000000n);
      return new Date(ms).toLocaleDateString("en-GB");
    } catch {
      return "Invalid date";
    }
  };

  inspections.forEach((ins) => {
    const val = ins.value?.Ok || {};
    const date = nsToDate(val.date);
    const followUp = nsToDate(val.followUpDate);
    const findings = val.findings || "No findings";
    const inspector = val.inspectorName || "Unknown";
    const appraiser = val.appraiser ? val.appraiser.toText() : "N/A";

    const actionRequired = (val.actionRequired && val.actionRequired.length > 0)
      ? `<ul>${val.actionRequired.map(a => `<li>${a}</li>`).join("")}</ul>`
      : "None";

    const reportUrl = val.reportUrl || "#";

    const row = document.createElement("tr");
    row.innerHTML = `
      <td class="date">${date}</td>
      <td class="inspectionResult">${findings}</td>
      <td class="inspector">${inspector}</td>
      <td class="appraiser">${appraiser}</td>
      <td class="actions">${actionRequired}</td>
      <td class="followup">${followUp}</td>
      <td><a class="text-p aDocMainBody" data-role="inspectionDoc" href="${reportUrl}" target="_blank">Document</a></td>
    `;
    tableBody.appendChild(row);
  });
}

function renderMaintenanceTable() {
  console.log("renderMaintenanceTable: data.Maintenance", data?.Maintenance);

  const card = document.getElementById("Maintenance");
  if (!card) {
    console.error("Maintenance card not found in DOM");
    return;
  }
  const tableContainer = card.querySelector(".mh-tables-container");
  const viewContainer = card.querySelector(".view-container");
  const table = document.getElementById("MaintenanceTable");
  if (!tableContainer || !table) {
    console.error("Maintenance table or container not found in DOM");
    return;
  }
  const tableBody = table.querySelector("tbody");
  tableBody.innerHTML = "";

  const maintenanceRecords = Array.isArray(data?.Maintenance) ? data.Maintenance : [];
  console.log("renderMaintenanceTable: maintenanceRecords", maintenanceRecords);

  const noData = tableContainer.querySelector("#no-data-maintenance") || document.createElement("p");
  noData.id = "no-data-maintenance";
  noData.className = "text-p no-data";
  noData.textContent = "There's no data to display";

  if (maintenanceRecords.length === 0) {
    console.log("renderMaintenanceTable: No maintenance records, hiding table");
    table.classList.add("hidden");
    if (!tableContainer.contains(noData)) tableContainer.appendChild(noData);
    noData.classList.remove("hidden");
    if (viewContainer) viewContainer.style.display = "none";
    return;
  } else {
    table.classList.remove("hidden");
    if (tableContainer.contains(noData)) noData.classList.add("hidden");
    if (viewContainer) viewContainer.style.display = "";
  }

  const nsToDate = (ns) => {
    if (!ns || ns.length === 0) return "Not provided";
    try {
      const ms = Number(ns[0] / 1000000n);
      return new Date(ms).toLocaleDateString("en-GB");
    } catch {
      return "Invalid date";
    }
  };

  maintenanceRecords.forEach(item => {
    if (!item?.value?.Ok) return;

    const maint = item.value.Ok;
    const date = nsToDate(maint.dateReported) || nsToDate(maint.dateCompleted);
    const description = maint.description || "N/A";
    const cost = maint.cost && maint.cost.length > 0 ? `£${Number(maint.cost[0]).toFixed(2)}` : "N/A";

    const row = document.createElement("tr");
    row.innerHTML = `
      <td class="date">${date}</td>
      <td class="maintenance">${description}</td>
      <td class="maintenanceCost">${cost}</td>
    `;
    tableBody.appendChild(row);
  });
}

function renderMaintenanceModal() {
  console.log("renderMaintenanceModal: data.Maintenance", data?.Maintenance);

  const modal = document.getElementById("MaintenanceModal");
  if (!modal) {
    console.error("MaintenanceModal not found in DOM");
    return;
  }
  const modalContent = modal.querySelector(".modal-content");
  const table = document.getElementById("MT-MaintenanceTable");
  if (!modalContent || !table) {
    console.error("MT-MaintenanceTable or modal-content not found in DOM");
    return;
  }
  const thead = table.querySelector("thead");
  const tableBody = table.querySelector("tbody");
  thead.innerHTML = "";
  tableBody.innerHTML = "";

  const maintenanceRecords = Array.isArray(data?.Maintenance) ? data.Maintenance : [];
  console.log("renderMaintenanceModal: maintenanceRecords", maintenanceRecords);

  const noData = modalContent.querySelector("#no-data-maintenance-modal") || document.createElement("p");
  noData.id = "no-data-maintenance-modal";
  noData.className = "text-p no-data";
  noData.textContent = "There's no data to display";

  if (maintenanceRecords.length === 0) {
    console.log("renderMaintenanceModal: No maintenance records, hiding table");
    table.classList.add("hidden");
    if (!modalContent.contains(noData)) modalContent.appendChild(noData);
    noData.classList.remove("hidden");
    return;
  } else {
    table.classList.remove("hidden");
    if (modalContent.contains(noData)) noData.classList.add("hidden");
  }

  const headers = [
    "Date Reported",
    "Date Completed",
    "Description",
    "Cost",
    "Contractor(s)",
    "Payment Method(s)",
    "Status"
  ];

  const headerRow = document.createElement("tr");
  headers.forEach(h => {
    const th = document.createElement("th");
    th.textContent = h;
    headerRow.appendChild(th);
  });
  thead.appendChild(headerRow);

  const nsToDate = (ns) => {
    if (!ns || ns.length === 0) return "Not provided";
    try {
      const ms = Number(ns[0] / 1000000n);
      return new Date(ms).toLocaleDateString("en-GB");
    } catch {
      return "Invalid date";
    }
  };

  maintenanceRecords.forEach(item => {
    if (!item?.value?.Ok) return;

    const maint = item.value.Ok;
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${nsToDate(maint.dateReported)}</td>
      <td>${nsToDate(maint.dateCompleted)}</td>
      <td>${maint.description || "N/A"}</td>
      <td>${maint.cost?.length > 0 ? `£${Number(maint.cost[0]).toFixed(2)}` : "N/A"}</td>
      <td>${maint.contractor?.length > 0 ? maint.contractor.join(", ") : "N/A"}</td>
      <td>${maint.paymentMethod?.length > 0 ? maint.paymentMethod.map(pm => JSON.stringify(pm)).join(", ") : "N/A"}</td>
      <td>${Object.keys(maint.status || {})[0] || "N/A"}</td>
    `;
    tableBody.appendChild(row);
  });
}