import { IDL } from "@dfinity/candid";
import { idlFactory } from "./backend.idl";
import {setupModal, setupToggle, currency, carousel, selectProperty, getSelectedPropertyIds, resultMessage } from "./All.js";
import {getCanister, getPrincipal, wireConnect, logout} from "./Main.js"
import { Principal } from "@dfinity/principal";

let currentSortOrder = "Newest"; // default

setupModal("createProposalBtn", "createProp-Modal", "closeModalProp");
selectProperty("propertyDropdown", true);
selectProperty("propertyDropdownModal", false);
wireConnect("connect_btn", "NavWallet");
setupToggle("filters-btn", "filtersBar", "filters-btn");
setupSearchListener();

// Your existing extractWhatTypeFromDid function
function extractWhatTypeFromDid() {
  const idl = idlFactory({ IDL });

  const updatePropField = idl._fields.find(([name]) => name === "updateProperty");
  if (!updatePropField) {
    throw new Error("updateProperty method not found in IDL");
  }

  const funcClass = updatePropField[1];
  if (!funcClass.argTypes || funcClass.argTypes.length === 0) {
    throw new Error("updateProperty has no argTypes");
  }

  const recordType = funcClass.argTypes[0];
  if (!recordType._fields) {
    throw new Error("First arg of updateProperty is not a record");
  }

  const whatField = recordType._fields.find(([fieldName]) => fieldName === "what");
  if (!whatField) {
    throw new Error(`Field 'what' not found. Available: ${recordType._fields.map(f => f[0]).join(", ")}`);
  }

  return whatField[1]; // This is the type of `what`
}

function getTypeStructure(type, visited = new Set()) {
  // Check for recursive types using _id
  if (type._id && visited.has(type._id)) {
    return { kind: 'recursive', id: type._id, name: type.name || 'unknown' };
  }
  if (type._id) {
    visited.add(type._id);
  }

  const getKind = (t, v) => t.accept({
    visitEmpty: () => ({ kind: 'primitive', name: 'empty' }),
    visitNull: () => ({ kind: 'primitive', name: 'null' }),
    visitBool: () => ({ kind: 'primitive', name: 'bool' }),
    visitText: () => ({ kind: 'primitive', name: 'text' }),
    visitInt: () => ({ kind: 'primitive', name: 'int' }),
    visitNat: () => ({ kind: 'primitive', name: 'nat' }),
    visitFloat: (tt, size) => ({ kind: 'primitive', name: `float${size}` }),
    visitFixedInt: (tt, size) => ({ kind: 'primitive', name: `int${size}` }),
    visitFixedNat: (tt, size) => ({ kind: 'primitive', name: `nat${size}` }),
    visitPrincipal: () => ({ kind: 'primitive', name: 'principal' }),
    visitReserved: () => ({ kind: 'primitive', name: 'reserved' }),
    visitUnknown: () => ({ kind: 'primitive', name: 'unknown' }),
    visitVec: (tt, ty) => ({ kind: 'vec', inner: getTypeStructure(ty, new Set(v)) }),
    visitOpt: (tt, ty) => ({ kind: 'opt', inner: getTypeStructure(ty, new Set(v)) }),
    visitRecord: (tt, fields) => ({
      kind: 'record',
      fields: fields.map(([name, ty]) => ({ name, type: getTypeStructure(ty, new Set(v)) })),
    }),
    visitVariant: (tt, fields) => ({
      kind: 'variant',
      fields: fields.map(([name, ty]) => ({ name, type: getTypeStructure(ty, new Set(v)) })),
    }),
    visitTuple: (tt, components) => ({
      kind: 'tuple',
      fields: components.map((ty, i) => ({ name: i.toString(), type: getTypeStructure(ty, new Set(v)) })),
    }),
    visitRec: (tt, ty) => getTypeStructure(ty, new Set(v)),
    visitFunc: (tt, f) => ({
      kind: 'func',
      args: f.argTypes.map(ty => getTypeStructure(ty, new Set(v))),
      rets: f.retTypes.map(ty => getTypeStructure(ty, new Set(v))),
      ann: f.annotations,
    }),
    visitService: (tt, methods) => ({
      kind: 'service',
      methods: Object.entries(methods).map(([name, ty]) => ({ name, type: getTypeStructure(ty, new Set(v)) })),
    }),
  }, null);

  return getKind(type, visited);
}

function generateForm(struct, container) {
  if (struct.kind === 'recursive') {
    const span = document.createElement('span');
    span.textContent = `Recursive type (${struct.name}) - input not supported`;
    container.appendChild(span);
    return () => ({ recursive: struct.id });
  } else if (struct.kind === 'primitive') {
    const input = document.createElement('input');
    let inputType = 'text';
    if (struct.name === 'bool') {
      inputType = 'checkbox';
    } else if (struct.name.startsWith('float')) {
      inputType = 'number';
      input.step = 'any';
    } else if (struct.name.startsWith('int') || struct.name.startsWith('nat')) {
      inputType = 'number';
    }
    input.type = inputType;
    input.placeholder = struct.name;
    container.appendChild(input);
    return () => {
      switch (struct.name) {
        case 'text':
          return input.value;
        case 'principal':
          try {
            return IDL.Principal.fromText(input.value);
          } catch (e) {
            throw new Error(`Invalid principal: ${input.value}`);
          }
        case 'bool':
          return input.checked;
        case 'int':
        case 'nat':
        case 'int64':
        case 'nat64':
          return input.value ? BigInt(input.value) : BigInt(0);
        case 'int32':
        case 'nat32':
        case 'int16':
        case 'nat16':
        case 'int8':
        case 'nat8':
          return input.value ? Number(input.value) : 0;
        case 'float32':
        case 'float64':
          return input.value ? parseFloat(input.value) : 0.0;
        case 'null':
          return null;
        default:
          throw new Error(`Unsupported primitive: ${struct.name}`);
      }
    };
  } else if (struct.kind === 'variant') {
    const select = document.createElement('select');
    const defaultOption = document.createElement('option');
    defaultOption.value = '';
    defaultOption.text = 'Select Option';
    select.appendChild(defaultOption);
    struct.fields.forEach(field => {
      const option = document.createElement('option');
      option.value = field.name;
      option.text = field.name;
      select.appendChild(option);
    });
    container.appendChild(select);
    const subContainer = document.createElement('div');
    subContainer.style.marginLeft = '20px';
    container.appendChild(subContainer);
    let currentGetValue = () => undefined;
    select.addEventListener('change', () => {
      subContainer.innerHTML = '';
      currentGetValue = () => undefined;
      const selected = select.value;
      if (selected) {
        const selectedField = struct.fields.find(f => f.name === selected);
        currentGetValue = generateForm(selectedField.type, subContainer);
      }
    });
    return () => {
      const selected = select.value;
      if (!selected) throw new Error('No variant option selected');
      return { [selected]: currentGetValue() };
    };
  } else if (struct.kind === 'record' || struct.kind === 'tuple') {
    const fieldGets = [];
    struct.fields.forEach(field => {
      const label = document.createElement('label');
      label.textContent = `${field.name}: `;
      container.appendChild(label);
      const fieldContainer = document.createElement('div');
      fieldContainer.style.marginLeft = '20px';
      container.appendChild(fieldContainer);
      const fieldGet = generateForm(field.type, fieldContainer);
      fieldGets.push({ name: field.name, get: fieldGet });
    });
    return () => {
      if (struct.kind === 'tuple') {
        return fieldGets.sort((a, b) => Number(a.name) - Number(b.name)).map(fg => fg.get());
      } else {
        const obj = {};
        fieldGets.forEach(fg => {
          obj[fg.name] = fg.get();
        });
        return obj;
      }
    };
  } else if (struct.kind === 'vec') {
    const itemsContainer = document.createElement('div');
    container.appendChild(itemsContainer);
    const addButton = document.createElement('button');
    addButton.type = 'button';
    addButton.textContent = 'Add Item';
    container.appendChild(addButton);
    let itemGets = [];
    addButton.addEventListener('click', () => {
      const itemContainer = document.createElement('div');
      itemContainer.style.border = '1px dashed #ccc';
      itemContainer.style.padding = '5px';
      itemContainer.style.margin = '5px';
      itemsContainer.appendChild(itemContainer);
      const itemGet = generateForm(struct.inner, itemContainer);
      const removeButton = document.createElement('button');
      removeButton.type = 'button';
      removeButton.textContent = 'Remove Item';
      removeButton.addEventListener('click', () => {
        itemContainer.remove();
        itemGets = itemGets.filter(ig => ig !== itemGet);
      });
      itemContainer.appendChild(removeButton);
      itemGets.push(itemGet);
    });
    return () => itemGets.map(ig => ig());
  } else if (struct.kind === 'opt') {
    const checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    container.appendChild(checkbox);
    const label = document.createElement('label');
    label.textContent = 'Include Value';
    container.appendChild(label);
    const subContainer = document.createElement('div');
    subContainer.style.marginLeft = '20px';
    subContainer.style.display = 'none';
    container.appendChild(subContainer);
    let subGet = null;
    checkbox.addEventListener('change', () => {
      if (checkbox.checked) {
        subContainer.style.display = 'block';
        if (!subGet) {
          subGet = generateForm(struct.inner, subContainer);
        }
      } else {
        subContainer.style.display = 'none';
      }
    });
    return () => (checkbox.checked ? [subGet()] : []);
  } else {
    throw new Error(`Unsupported type kind: ${struct.kind}`);
  }
}

async function createProposal() {
  try {
    const whatType = extractWhatTypeFromDid();
    const whatStruct = getTypeStructure(whatType);

    const dynamicFormDiv = document.getElementById("dynamic-what-form");
    const addWhatBtn = document.getElementById("add-what-btn");

    let whatInstances = [];

    if (addWhatBtn) {
      addWhatBtn.addEventListener("click", () => {
        const whatContainer = document.createElement("div");
        whatContainer.style.border = "1px solid #ccc";
        whatContainer.style.padding = "10px";
        whatContainer.style.marginBottom = "10px";

        const whatGet = generateForm(whatStruct, whatContainer);

        const removeBtn = document.createElement("button");
        removeBtn.type = "button";
        removeBtn.textContent = "Remove What";
        removeBtn.style.marginTop = "10px";
        removeBtn.addEventListener("click", () => {
          whatContainer.remove();
          whatInstances = whatInstances.filter((inst) => inst !== whatGet);
        });
        whatContainer.appendChild(removeBtn);

        dynamicFormDiv.appendChild(whatContainer);
        whatInstances.push(whatGet);
      });
    }

    // ✅ Attach listener directly
    const submitBtn = document.getElementById("submitNewProposal");
    if (submitBtn) {
      submitBtn.addEventListener("click", async (e) => {
        e.preventDefault();

        let arg = {
          propertyId: Number(document.getElementById("propertyDropdownModal").value),
          what: {
            Governance: {
              Proposal: {
                Create: [
                  {
                    title: document.getElementById("prop-subject").value,
                    description: document.getElementById("prop-comments").value,
                    category: { [document.querySelector('input[name="category"]:checked')?.value]: null },
                    implementation: { [document.querySelector('input[name="Implementation"]:checked')?.value]: null },
                    startAt: BigInt(Math.floor(new Date(document.getElementById("start-time").value).getTime() * 1e6)),
                    actions: whatInstances.map((get) => get())
                  }
                ]
              }
            }
          }
        };

        console.log("CreateProposal: Arg", arg);

        try {
          let backend = await getCanister("backend");
          const result = await backend.updateProperty(arg);
          resultMessage("proposalCreationResult", "Proposal Created", true);
          console.log("Proposal created", result);
        } catch (error) {
          resultMessage("proposalCreationResult", "Error Creating Proposal", false);
          console.error("Error proposal create:", error);
        }
      });
    }
  } catch (err) {
    console.error("Error setting up proposal form:", err);
  }
}
createProposal();

//async function getProposals(){
//    try{
//        const readArgs = [
//          { Location: [] }, // Fetch Location
//          { Proposals: {
//            base: {Properties: [await selectProperty("propertyDropdownModal")]},
//            conditionals: {
//              category: [],
//              implementationCategory: [],
//              actions: [],
//              status: [],
//              creator: [],
//              eligibleCount: [],
//              totalVoterCount: [],
//              yesVotes: [],
//              noVotes: [],
//              startAt: [],
//              outcome: [],
//              voted: []
//            }
//          }}
//          //{ Tenants: { base: { Properties: [propertyId] }, conditionals: null } },
//        ];
//        console.log("getProposals:Read Args", readArgs);
//        let backend = await getCanister("backend");
//        console.log(backend);
//        const results = await backend.readProperties(readArgs, []);
//        console.log("getProposals:ReadResults",results);
//    
//     
//    }
//    catch(e){
//        console.log("getProposals:Error", e);
//    }
//};
getProposals();
async function voteOnProposal(propertyId, proposalId, vote) {
    const args = {
        propertyId: BigInt(propertyId),
        what: {
            Governance: {
                Vote: {
                    proposalId: BigInt(proposalId),
                    vote
                }
            }
        }
    };

    try {
        const backend = await getCanister("backend");
        const result = await backend.updateProperty(args);
        console.log(`Vote submitted successfully for proposal ${proposalId}: ${vote ? 'For' : 'Against'}`, result);
        return { success: true, result };
    } catch (e) {
        console.error(`voteOnProposal: Error for proposal ${proposalId}, vote: ${vote}`, e);
        return { success: false, error: e };
    }
}

document.getElementById("filters-done").addEventListener("click", () => {
  const dropdown = document.getElementById("propertyDropdown");
  const selected = dropdown.value || "all";

  const url = new URL(window.location);
  url.searchParams.set("id", selected);
  window.history.replaceState({}, "", url);

  getProposals();
});

document.getElementById("filters-clear").addEventListener("click", () => {
  const dropdown = document.getElementById("propertyDropdown");

  // ✅ set back to "All Properties"
  const allOption = Array.from(dropdown.options).find(opt =>
    opt.textContent === "All Properties"
  );
  if (allOption) {
    dropdown.value = allOption.value; // this will be the "1,2,5" string
  }

  // Update URL with those IDs
  const url = new URL(window.location);
  url.searchParams.set("id", dropdown.value);
  window.history.replaceState({}, "", url);

  getProposals();
});

function buildProposalConditionals(userPrincipal) {
  const conditionals = {
    category: [],
    implementationCategory: [],
    actions: [],
    status: [],
    creator: [],
    eligibleCount: [],
    totalVoterCount: [],
    yesVotes: [],
    noVotes: [],
    startAt: [],
    outcome: [],
    voted: []
  };

  // --- Status (single select) ---
  const statusVal = document.getElementById("statusFilter").value;
  if (statusVal) {
    conditionals.status = [{ [statusVal]: null }];
  }

  // --- Categories (multi select dropdown with checkboxes) ---
  const checkedCats = document.querySelectorAll(".filter-category:checked");
  const values = Array.from(checkedCats).map(cb => cb.value).filter(v => v !== "All");
  if (values.length > 0) {
    conditionals.category = [values.map(v => ({ [v]: v === "Invoice" ? { invoiceId: 0 } : null }))];
  }

  // --- Implementation Category (single select) ---
  const implVal = document.getElementById("implementationFilter").value;
  if (implVal) {
    if (implVal === "Other") {
      conditionals.implementationCategory = [{ Other: 0 }]; // default 0 for now
    } else {
      conditionals.implementationCategory = [{ [implVal]: null }];
    }
  }

  // --- My Involvement (single select) ---
  const involvementVal = document.getElementById("involvementFilter").value;
  if (involvementVal === "CreatedByMe") {
    if (userPrincipal) conditionals.creator = [userPrincipal];
  } else if (involvementVal === "HasVoted") {
    if (userPrincipal) conditionals.voted = [{ HasVoted: userPrincipal }];
  } else if (involvementVal === "NotVoted") {
    if (userPrincipal) conditionals.voted = [{ NotVoted: userPrincipal }];
  }

  // --- Outcome (single select, optional) ---
  const outcomeVal = document.getElementById("outcomeFilter")?.value || "";
  if (outcomeVal) {
    conditionals.outcome = [{ [outcomeVal]: null }];
  }

  return conditionals;
}


async function getProposals() {
  const createPropContainer = document.getElementById('createProp-container');
  const propTableContainer = document.getElementById('prop-table-container');
  const mainContainer = createPropContainer.parentElement;

  // Check if user is logged in
  let userPrincipal = null;
  try {
    userPrincipal = await getPrincipal();
    console.log("getProposals:User Principal (string)", userPrincipal || "null");
  } catch (e) {
    console.error("getProposals:Failed to get user Principal", e);
  }

  if (!userPrincipal) {
    createPropContainer.style.display = 'none';
    propTableContainer.style.display = 'none';
    let messageEl = mainContainer.querySelector('#loginPromptMsg');
    if (!messageEl) {
      messageEl = document.createElement('p');
      messageEl.id = 'loginPromptMsg';
      messageEl.textContent = 'Please log in to view proposals';
      mainContainer.appendChild(messageEl);
    }
    return;
  }

  // Remove login message if present
  const loginMessageEl = mainContainer.querySelector('#loginPromptMsg');
  if (loginMessageEl) loginMessageEl.remove();
  createPropContainer.style.display = '';
  propTableContainer.style.display = '';

  try {
    let backend = await getCanister("backend");
    let principalObj = Principal.fromText(userPrincipal);

    // ---- collect property ids from dropdown ----
    const dropdown = document.getElementById("propertyDropdown");
    let propertyIds = [];
    if (dropdown && dropdown.value) {
      propertyIds = dropdown.value.split(",").map(Number).filter(n => !isNaN(n));
    }

    // ---- build conditionals from the helper function ----
    const conditionals = buildProposalConditionals(principalObj);
    console.log("getProposals: Conditionals", conditionals);

    // ---- backend call ----
    const readArgs = [
      { Location: [] },
      { Proposals: { base: { Properties: [propertyIds] }, conditionals } }
    ];

    const results = await backend.readProperties(readArgs, []);
    console.log("getProposals:ReadResults", JSON.stringify(results, (k, v) =>
      typeof v === 'bigint' ? v.toString() : v
    ));

    // Map propertyId -> addressLine1
    const locations = results[0].Location.reduce((map, loc) => {
      if (loc.value?.Ok) {
        map[Number(loc.id)] = loc.value.Ok.addressLine1;
      }
      return map;
    }, {});

    // Collect proposals
    const proposals = [];
    (results[1]?.Proposals || []).forEach(propEntry => {
      const propId = Number(propEntry.propertyId || 0);
      if (!propEntry.result || !("Ok" in propEntry.result)) return;

      propEntry.result.Ok.forEach(item => {
        if (!item?.value?.Ok) return;
        const proposal = item.value.Ok;

        // derive hasVoted + yourVote from votes
        let hasVoted = false;
        let yourVote = null;
        const voteEntry = proposal.votes.find(([p, v]) => p.toText() === userPrincipal);
        if (voteEntry) {
          hasVoted = true;
          yourVote = voteEntry[1] ? "For" : "Against";
        }

        proposals.push({
          ...item,
          propertyId: propId,
          addressLine1: locations[propId] || 'Unknown',
          hasVoted,
          yourVote
        });
      });
    });

    if (proposals.length === 0) {
      createPropContainer.style.display = 'none';
      propTableContainer.style.display = 'none';
      let messageEl = mainContainer.querySelector('#emptyProposalsMsg');
      if (!messageEl) {
        messageEl = document.createElement('p');
        messageEl.id = 'emptyProposalsMsg';
        messageEl.textContent =
          'Your proposals are empty, you need to hold a property’s NFTs to view their proposals.';
        mainContainer.appendChild(messageEl);
      }
      return;
    }

    const emptyMessageEl = mainContainer.querySelector('#emptyProposalsMsg');
    if (emptyMessageEl) emptyMessageEl.remove();
    setupSearchEnhancements(proposals);
    const sortedProposals = sortProposals(proposals, currentSortOrder);
    const filteredProposals = applySearchFilter(sortedProposals)
    // ---- render ----
    populateProposalsTable(filteredProposals, userPrincipal);

  } catch (e) {
    console.error("getProposals:Error", e);
  }
}
function setupSearchEnhancements(proposals) {
  const searchInput = document.getElementById("proposalSearch");
  const ghostSpan = document.getElementById("ghostText");
  const suggestionBox = document.getElementById("autocomplete-list");

  if (!searchInput || !ghostSpan || !suggestionBox) {
    console.warn("Search inputs not found in DOM.");
    return;
  }

  // Collect searchable words
  const words = proposals.flatMap(p => {
    const val = p?.value?.Ok || {};
    return [
      ...(val.title ? val.title.split(/\s+/) : []),
      ...(val.description ? val.description.split(/\s+/) : [])
    ];
  });
  const uniqueWords = [...new Set(words.map(w => w.toLowerCase()))].filter(w => w.length > 2);

  // 🔹 Handle typing
  searchInput.addEventListener("input", () => {
    const query = searchInput.value.toLowerCase();
    suggestionBox.innerHTML = "";
    ghostSpan.textContent = "";

    if (!query) return;

    // Autocomplete dropdown
    const matches = uniqueWords.filter(w => w.startsWith(query)).slice(0, 8);
    matches.forEach(match => {
      const div = document.createElement("div");
      div.textContent = match;
      div.addEventListener("click", () => {
        searchInput.value = match;
        suggestionBox.innerHTML = "";
        ghostSpan.textContent = "";
        getProposals();
      });
      suggestionBox.appendChild(div);
    });

    // Ghost text (remaining characters only)
    if (matches.length > 0) {
      const suggestion = matches[0];
      if (suggestion.startsWith(query)) {
        ghostSpan.textContent = suggestion;
      }
    }
  });

  // 🔹 Accept ghost suggestion on Tab / → / Enter
  searchInput.addEventListener("keydown", (e) => {
    if ((e.key === "Tab" || e.key === "ArrowRight" || e.key === "Enter") && ghostSpan.textContent) {
      e.preventDefault();
      searchInput.value += ghostSpan.textContent; // complete the word
      ghostSpan.textContent = "";
      suggestionBox.innerHTML = "";
      getProposals();
    }
  });

  // Hide dropdown when clicking outside
  document.addEventListener("click", (e) => {
    if (!searchInput.contains(e.target) && !suggestionBox.contains(e.target)) {
      suggestionBox.innerHTML = "";
    }
  });
}

function applySearchFilter(proposals) {
  const searchInput = document.getElementById("proposalSearch");
  if (!searchInput) return proposals;

  const query = searchInput.value.trim().toLowerCase();
  if (!query) return proposals;

  return proposals.filter(p => {
    const val = p?.value?.Ok || {};
    return (
      (val.title && val.title.toLowerCase().includes(query)) ||
      (val.description && val.description.toLowerCase().includes(query))
    );
  });
}
// 🔹 Helper: style ghost input to sit behind real input
function styleGhostInput(searchInput, ghostInput) {
  ghostInput.style.position = "absolute";
  ghostInput.style.top = searchInput.offsetTop + "px";
  ghostInput.style.left = searchInput.offsetLeft + "px";
  ghostInput.style.width = searchInput.offsetWidth + "px";
  ghostInput.style.height = searchInput.offsetHeight + "px";

  ghostInput.style.background = "transparent";
  ghostInput.style.color = "rgba(0,0,0,0.3)";
  ghostInput.style.border = "none";
  ghostInput.style.pointerEvents = "none";
  ghostInput.style.font = window.getComputedStyle(searchInput).font;
  ghostInput.style.padding = window.getComputedStyle(searchInput).padding;
}

function setupSearchListener() {
  const searchInput = document.getElementById("proposalSearch");
  if (!searchInput) return;

  searchInput.addEventListener("input", () => {
    getProposals(); // refresh table on typing
  });
}

function getSortKey(proposal) {
  const status = proposal.value.Ok.status;

  if ("LiveProposal" in status) {
    return Number(status.LiveProposal.endTime);
  }
  if ("Executed" in status) {
    return Number(status.Executed.executedAt);
  }
  if ("RejectedEarly" in status) {
    return Number(proposal.value.Ok.createdAt);
  }
  return Number(proposal.value.Ok.createdAt); // fallback
}

function sortProposals(proposals, order = "Newest") {
  return proposals.sort((a, b) => {
    const keyA = getSortKey(a);
    const keyB = getSortKey(b);
    return order === "Newest" ? keyB - keyA : keyA - keyB;
  });
}

document.querySelectorAll('.sort-option').forEach(option => {
  option.addEventListener('click', () => {
    currentSortOrder = option.dataset.value; // "Newest" or "Oldest"
    getProposals();
  });
});






// Helper function to format What actions using Candid types
function formatWhatActions(actions) {
    if (!actions || actions.length === 0) return '<li>No actions</li>';

    const formatDate = (ns) => {
        if (!ns) return 'N/A';
        return new Date(Number(ns) / 1e6).toLocaleString('en-US');
    };

    const formatPaymentMethod = (method) => {
        if (!method) return 'None';
        if ('Cash' in method) return 'Cash';
        if ('BankTransfer' in method) return 'Bank Transfer';
        if ('Crypto' in method) return method.Crypto.cryptoType ? Object.keys(method.Crypto.cryptoType)[0] : 'Crypto';
        if ('Other' in method) return method.Other.description[0] || 'Other';
        return 'Unknown';
    };

    const formatInvoiceDirection = (direction) => {
        if (!direction) return 'N/A';
        if ('Outgoing' in direction) {
            const { to, accountReference, category } = direction.Outgoing;
            return [
                `To: ${to?.owner?.toText?.() || 'N/A'}`,
                `Account Reference: ${accountReference || 'N/A'}`,
                `Category: ${category ? Object.keys(category)[0] : 'N/A'}`
            ].join('<br>');
        }
        if ('Incoming' in direction) {
            const { from, accountReference, category } = direction.Incoming;
            return [
                `From: ${from?.owner?.toText?.() || 'N/A'}`,
                `Account Reference: ${accountReference || 'N/A'}`,
                `Category: ${category ? Object.keys(category)[0] : 'N/A'}`
            ].join('<br>');
        }
        return 'Unknown';
    };

    const formatActions = (actionType, actionObj) => {
        if ('Create' in actionObj) {
            return actionObj.Create.map(item => {
                if (actionType === 'Tenant') {
                    return [
                        `Create Tenant`,
                        `  Lead Tenant: ${item.leadTenant || 'N/A'}`,
                        `  Monthly Rent: ${item.monthlyRent || 0}`,
                        `  Lease Start Date: ${formatDate(item.leaseStartDate)}`,
                        `  Deposit: ${item.deposit || 0}`,
                        `  Contract Length: ${item.contractLength ? Object.keys(item.contractLength)[0] : 'N/A'}`,
                        `  Other Tenants: ${item.otherTenants.join(', ') || 'None'}`
                    ].join('<br>');
                }
                if (actionType === 'Invoice') {
                    return [
                        `Create Invoice`,
                        `  Title: ${item.title || 'N/A'}`,
                        `  Amount: ${item.amount || 0}`,
                        `  Due Date: ${formatDate(item.dueDate)}`,
                        `  Direction: ${formatInvoiceDirection(item.direction)}`,
                        `  Payment Method: ${item.paymentMethod ? Object.keys(item.paymentMethod)[0] : 'None'}`
                    ].join('<br>');
                }
                if (actionType === 'Document') {
                    return [
                        `Create Document`,
                        `  Title: ${item.title || 'N/A'}`,
                        `  Type: ${item.documentType ? Object.keys(item.documentType)[0] : 'N/A'}`,
                        `  Description: ${item.description || 'N/A'}`,
                        `  URL: ${item.url || 'N/A'}`
                    ].join('<br>');
                }
                if (actionType === 'Inspection') {
                    return [
                        `Create Inspection`,
                        `  Findings: ${item.findings || 'N/A'}`,
                        `  Date: ${formatDate(item.date[0])}`,
                        `  Inspector Name: ${item.inspectorName || 'N/A'}`,
                        `  Action Required: ${item.actionRequired[0] || 'None'}`,
                        `  Follow-Up Date: ${formatDate(item.followUpDate[0])}`
                    ].join('<br>');
                }
                if (actionType === 'Insurance') {
                    return [
                        `Create Insurance`,
                        `  Policy Number: ${item.policyNumber || 'N/A'}`,
                        `  Provider: ${item.provider || 'N/A'}`,
                        `  Start Date: ${formatDate(item.startDate)}`,
                        `  End Date: ${formatDate(item.endDate[0])}`,
                        `  Premium: ${item.premium || 0}`,
                        `  Payment Frequency: ${item.paymentFrequency ? Object.keys(item.paymentFrequency)[0] : 'N/A'}`
                    ].join('<br>');
                }
                if (actionType === 'Note') {
                    return [
                        `Create Note`,
                        `  Title: ${item.title || 'N/A'}`,
                        `  Content: ${item.content || 'N/A'}`,
                        `  Date: ${formatDate(item.date[0])}`
                    ].join('<br>');
                }
                if (actionType === 'Maintenance') {
                    return [
                        `Create Maintenance`,
                        `  Description: ${item.description || 'N/A'}`,
                        `  Status: ${item.status ? Object.keys(item.status)[0] : 'N/A'}`,
                        `  Cost: ${item.cost[0] || 'N/A'}`,
                        `  Date Reported: ${formatDate(item.dateReported[0])}`,
                        `  Date Completed: ${formatDate(item.dateCompleted[0])}`,
                        `  Contractor: ${item.contractor[0] || 'None'}`,
                        `  Payment Method: ${formatPaymentMethod(item.paymentMethod[0])}`
                    ].join('<br>');
                }
                if (actionType === 'Valuations') {
                    return [
                        `Create Valuation`,
                        `  Value: ${item.value || 0}`,
                        `  Method: ${item.method ? Object.keys(item.method)[0] : 'N/A'}`
                    ].join('<br>');
                }
                if (actionType === 'Images') {
                    return [
                        `Create Images`,
                        `  URLs: ${item.join(', ') || 'N/A'}`
                    ].join('<br>');
                }
                if (actionType === 'Governance' && item.Vote) {
                    return [
                        `Vote on Proposal`,
                        `  Proposal ID: ${item.Vote.proposalId}`,
                        `  Vote: ${item.Vote.vote ? 'For' : 'Against'}`
                    ].join('<br>');
                }
                if (actionType === 'Governance' && item.Proposal) {
                    return [
                        `Proposal Action`,
                        `  Type: ${Object.keys(item.Proposal)[0]}`
                    ].join('<br>');
                }
                if (actionType === 'NftMarketplace') {
                    if ('Bid' in item) {
                        return [
                            `Place Bid`,
                            `  Amount: ${item.Bid.bidAmount}`,
                            `  Listing ID: ${item.Bid.listingId}`
                        ].join('<br>');
                    }
                    return [
                        `${Object.keys(item)[0]} NFT Action`
                    ].join('<br>');
                }
                return [`Create ${actionType}`].join('<br>');
            });
        }
        if ('Update' in actionObj) {
            const [updateData, ids] = actionObj.Update;
            const idList = ids.join(', ') || 'N/A';
            if (actionType === 'Tenant') {
                return [[
                    `Update Tenant`,
                    `  IDs: ${idList}`,
                    `  Lead Tenant: ${updateData.leadTenant[0] || 'N/A'}`,
                    `  Monthly Rent: ${updateData.monthlyRent[0] || 'N/A'}`
                ].join('<br>')];
            }
            if (actionType === 'Invoice') {
                return [[
                    `Update Invoice`,
                    `  IDs: ${idList}`,
                    `  Title: ${updateData.title[0] || 'N/A'}`,
                    `  Amount: ${updateData.amount[0] || 'N/A'}`
                ].join('<br>')];
            }
            if (actionType === 'Document') {
                return [[
                    `Update Document`,
                    `  IDs: ${idList}`,
                    `  Title: ${updateData.title[0] || 'N/A'}`
                ].join('<br>')];
            }
            if (actionType === 'Inspection') {
                return [[
                    `Update Inspection`,
                    `  IDs: ${idList}`,
                    `  Findings: ${updateData.findings[0] || 'N/A'}`
                ].join('<br>')];
            }
            if (actionType === 'Insurance') {
                return [[
                    `Update Insurance`,
                    `  IDs: ${idList}`,
                    `  Policy Number: ${updateData.policyNumber[0] || 'N/A'}`
                ].join('<br>')];
            }
            if (actionType === 'Note') {
                return [[
                    `Update Note`,
                    `  IDs: ${idList}`,
                    `  Title: ${updateData.title[0] || 'N/A'}`,
                    `  Content: ${updateData.content[0] || 'N/A'}`
                ].join('<br>')];
            }
            if (actionType === 'Maintenance') {
                return [[
                    `Update Maintenance`,
                    `  IDs: ${idList}`,
                    `  Description: ${updateData.description[0] || 'N/A'}`
                ].join('<br>')];
            }
            if (actionType === 'Valuations') {
                return [[
                    `Update Valuation`,
                    `  IDs: ${idList}`,
                    `  Value: ${updateData.value[0] || 'N/A'}`
                ].join('<br>')];
            }
            if (actionType === 'Images') {
                return [[
                    `Update Images`,
                    `  IDs: ${idList}`,
                    `  URLs: ${updateData || 'N/A'}`
                ].join('<br>')];
            }
            return [[`Update ${actionType}`, `  IDs: ${idList}`].join('<br>')];
        }
        if ('Delete' in actionObj) {
            return [[
                `Delete ${actionType}`,
                `  IDs: ${actionObj.Delete.join(', ') || 'N/A'}`
            ].join('<br>')];
        }
        return [[`Unknown ${actionType} Action`].join('<br>')];
    };

    const actionItems = actions.flatMap(action => {
        if ('Description' in action) {
            return [[`Set Description`, `  Value: ${action.Description || 'N/A'}`].join('<br>')];
        }
        if ('MonthlyRent' in action) {
            return [[`Set Monthly Rent`, `  Value: ${action.MonthlyRent || 0}`].join('<br>')];
        }
        if ('Financials' in action) {
            return [[
                `Update Financials`,
                `  Current Value: ${action.Financials.currentValue || 0}`
            ].join('<br>')];
        }
        if ('AdditionalDetails' in action) {
            const { schoolScore, affordability, floodZone, crimeScore } = action.AdditionalDetails;
            return [[
                `Update Additional Details`,
                `  School Score: ${schoolScore[0] || 'N/A'}`,
                `  Affordability: ${affordability[0] || 'N/A'}`,
                `  Flood Zone: ${floodZone[0] ? 'Yes' : 'No'}`,
                `  Crime Score: ${crimeScore[0] || 'N/A'}`
            ].join('<br>')];
        }
        if ('PhysicalDetails' in action) {
            const { beds, baths, squareFootage, yearBuilt, lastRenovation } = action.PhysicalDetails;
            return [[
                `Update Physical Details`,
                `  Beds: ${beds[0] || 'N/A'}`,
                `  Baths: ${baths[0] || 'N/A'}`,
                `  Square Footage: ${squareFootage[0] || 'N/A'}`,
                `  Year Built: ${yearBuilt[0] || 'N/A'}`,
                `  Last Renovation: ${lastRenovation[0] || 'N/A'}`
            ].join('<br>')];
        }
        if (['Tenant', 'Invoice', 'Document', 'Inspection', 'Insurance', 'Note', 'Maintenance', 'Valuations', 'Images', 'Governance', 'NftMarketplace'].some(type => type in action)) {
            const actionType = Object.keys(action)[0];
            return formatActions(actionType, action[actionType]);
        }
        return [[`Unknown Action`, `  Type: ${Object.keys(action)[0]}`].join('<br>')];
    });

    return actionItems.map(item => `<li>${item}</li>`).join('');
}

function populateProposalsTable(proposals, userPrincipal) {
    console.log("proposal data for table",proposals)
    const tbody = document.querySelector('#proposals-table tbody');
    if (!tbody) {
        console.error("Table body not found");
        return;
    }
    tbody.innerHTML = '';

    // Inject CSS for actions styling, vote feedback, and messages
    const style = document.createElement('style');
    style.textContent = `
        .details-content .actions-list {
            margin-top: 10px;
            padding: 10px;
            border-left: 3px solid #007bff;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        .details-content .actions-list li {
            margin: 5px 0;
            padding-left: 10px;
            font-size: 0.95em;
            color: #333;
            line-height: 1.5;
        }
        .details-content .actions-list li::before {
            content: "• ";
            color: #007bff;
        }
        .details-content .actions-list li br + * {
            margin-left: 20px;
            display: block;
        }
        .Votebtn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
        }
        .vote-feedback {
            margin-top: 10px;
            padding: 8px;
            border-radius: 4px;
            font-size: 0.9em;
        }
        .vote-feedback.pending {
            color: #004085;
            background-color: #cce5ff;
            border: 1px solid #b8daff;
        }
        .vote-feedback.success {
            color: #155724;
            background-color: #d4edda;
            border: 1px solid #c3e6cb;
        }
        .vote-feedback.error {
            color: #721c24;
            background-color: #f8d7da;
            border: 1px solid #f5c6cb;
        }
        .vote-feedback.failure {
            color: #856404;
            background-color: #fff3cd;
            border: 1px solid #ffeeba;
        }
        #loginPromptMsg, #emptyProposalsMsg {
            padding: 10px;
            font-size: 1em;
            color: #333;
            text-align: center;
        }
    `;
    document.head.appendChild(style);

    proposals.forEach((item) => {
        console.log("Proposal",item);
        
        const proposal = item.value.Ok;
        const proposalId = item.id;
        const propertyId = item.propertyId;
        const addressLine1 = item.addressLine1
        const detailsId = `details-${Number(proposalId)}`;

        const yesCount = proposal.votes.filter(vote => vote[1] === true).length;
        const noCount = proposal.votes.filter(vote => vote[1] === false).length;
        const totalVotes = yesCount + noCount;
        const totalEligible = Number(proposal.totalEligibleVoters) || 1;
        const votedPercentage = Math.round((totalVotes / totalEligible) * 100) + '%';

        let yourVote = 'Not Voted';
        let hasVoted = false;
        if (userPrincipal) {
            const userVote = proposal.votes.find(vote => vote[0].toText() === userPrincipal);
            if (userVote) {
                yourVote = userVote[1] ? 'For' : 'Against';
                hasVoted = true;
            }
        }

        const createdMs = Number(proposal.createdAt) / 1e6;
        const createdDateStr = new Date(createdMs).toLocaleDateString('en-US', {
            month: 'numeric',
            day: 'numeric',
            year: 'numeric'
        });

        const category = Object.keys(proposal.category)[0] || 'Unknown';
        const implementation = Object.keys(proposal.implementation)[0] || 'Unknown';
        const statusKey = Object.keys(proposal.status)[0] || 'Unknown';
        const status = statusKey.replace('Proposal', '');

        let timeUntil = 'Vote Concluded';
        let isLive = false;
        if (status === 'Live' && proposal.status.LiveProposal && proposal.status.LiveProposal.endTime) {
            const endTime = proposal.status.LiveProposal.endTime;
            console.log(`Proposal ${proposalId}: endTime = ${endTime} (${new Date(Number(endTime) / 1e6).toLocaleString('en-US')})`);
            const endMs = Number(endTime) / 1e6;
            const nowMs = Date.now();
            if (endMs > nowMs) {
                const diffMs = endMs - nowMs;
                const days = Math.floor(diffMs / (1000 * 60 * 60 * 24));
                const hours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
                const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
                timeUntil = `${days}d ${hours}h ${minutes}m`;
                isLive = true;
            }
        }

        const mainTr = document.createElement('tr');
        mainTr.classList.add('expandable');
        mainTr.setAttribute('data-details-id', detailsId);
        mainTr.setAttribute('aria-expanded', 'false');

        mainTr.innerHTML = `
            <td>${createdDateStr}</td>
            <td>${addressLine1}</td>
            <td>${proposal.title}</td>
            <td>${category}</td>
            <td>${status}</td>
            <td>${yourVote ? `<div id="${yourVote.toLowerCase().replace(' ', '-')}"><span>${yourVote}</span><i class="fa-solid ${yourVote === 'For' ? 'fa-check' : yourVote === 'Against' ? 'fa-xmark' : ''}"></i></div>` : ''}</td>
            <td>${yesCount}/${noCount}</td>
            <td>${votedPercentage}</td>
            <td>${timeUntil}</td>
        `;

        const detailsTr = document.createElement('tr');
        detailsTr.id = detailsId;
        detailsTr.classList.add('details-row');
        detailsTr.setAttribute('aria-hidden', 'true');
        detailsTr.style.display = 'none';

        const creatorStr = proposal.creator.toText ? proposal.creator.toText() : 'Unknown';
        const quorumStr = `${Math.round((totalVotes / totalEligible) * 100)}% (of ${totalEligible})`;
        const closesStr = proposal.status.LiveProposal && proposal.status.LiveProposal.endTime
            ? new Date(Number(proposal.status.LiveProposal.endTime) / 1e6).toLocaleString('en-US')
            : 'Vote Concluded';
        const attachments = proposal.actions.length > 0
            ? proposal.actions.map(action => `<a href="#">${Object.keys(action)[0]}</a>`).join(', ')
            : 'None';
        const actionsList = formatWhatActions(proposal.actions);

        detailsTr.innerHTML = `
            <td colspan="8">
                <div class="details-content">
                    <strong>Proposal #${Number(proposalId)} — ${proposal.title}</strong>
                    <ul>
                        <li><b>Description:</b> ${proposal.description}</li>
                        <li><b>Attachments:</b> ${attachments}</li>
                        <li><b>Actions:</b> <ul class="actions-list">${actionsList}</ul></li>
                        <li><b>Created by:</b> ${creatorStr}</li>
                        <li><b>Quorum:</b> ${quorumStr}</li>
                        <li><b>Closes:</b> ${closesStr}</li>
                        <li><b>Implementation:</b> ${implementation}</li>
                    </ul>
                    <div id="proposalVote-container">
                        <button class="Votebtn btn small ${hasVoted || !isLive ? 'disabled' : ''}" data-proposal-id="${Number(proposalId)}" data-vote="true" data-property-id="${propertyId}" ${hasVoted || !isLive ? 'disabled' : ''}>
                            <span>Vote For</span><i class="fa-solid fa-check"></i>
                        </button>
                        <button class="Votebtn btn small ${hasVoted || !isLive ? 'disabled' : ''}" data-proposal-id="${Number(proposalId)}" data-vote="false" data-property-id="${propertyId}" ${hasVoted || !isLive ? 'disabled' : ''}>
                            <span>Vote Against</span><i class="fa-solid fa-xmark"></i>
                        </button>
                        <p class="vote-feedback" id="vote-feedback-${Number(proposalId)}" style="display: none;"></p>
                    </div>
                </div>
            </td>
        `;

        tbody.appendChild(mainTr);
        tbody.appendChild(detailsTr);
    });

    const table = document.getElementById('proposals-table');
    if (!table.dataset.listenerAdded) {
        table.addEventListener('click', (event) => {
            const editableRow = event.target.closest('tr.expandable');
            if (editableRow) {
                const detailsId = editableRow.getAttribute('data-details-id');
                const detailsRow = document.getElementById(detailsId);
                if (detailsRow) {
                    document.querySelectorAll('tr.expandable[aria-expanded="true"]').forEach(otherRow => {
                        if (otherRow !== editableRow) {
                            const otherDetailsId = otherRow.getAttribute('data-details-id');
                            const otherDetailsRow = document.getElementById(otherDetailsId);
                            if (otherDetailsRow) {
                                otherRow.setAttribute('aria-expanded', 'false');
                                otherDetailsRow.setAttribute('aria-hidden', 'true');
                                otherDetailsRow.style.display = 'none';
                            }
                        }
                    });

                    const expanded = editableRow.getAttribute('aria-expanded') === 'true';
                    const newExpanded = !expanded;
                    editableRow.setAttribute('aria-expanded', newExpanded.toString());
                    detailsRow.setAttribute('aria-hidden', (!newExpanded).toString());
                    detailsRow.style.display = newExpanded ? '' : 'none';
                }
            }
        });

        table.addEventListener('click', async (event) => {
            const voteBtn = event.target.closest('.Votebtn');
            if (voteBtn && !voteBtn.disabled) {
                const proposalId = Number(voteBtn.getAttribute('data-proposal-id'));
                const vote = voteBtn.getAttribute('data-vote') === 'true';
                const propertyId = voteBtn.getAttribute('data-property-id');
                const feedbackEl = document.getElementById(`vote-feedback-${proposalId}`);

                feedbackEl.textContent = 'Voting, please wait...';
                feedbackEl.className = 'vote-feedback pending';
                feedbackEl.style.display = 'block';

                if (!propertyId) {
                    feedbackEl.textContent = 'Voting failed: Invalid property ID';
                    feedbackEl.className = 'vote-feedback failure';
                    setTimeout(() => {
                        feedbackEl.style.display = 'none';
                    }, 5000);
                    return;
                }

                const result = await voteOnProposal(propertyId, proposalId, vote);
                if (result.success) {
                    feedbackEl.textContent = `Successfully voted ${vote ? 'For' : 'Against'} on proposal #${proposalId}`;
                    feedbackEl.className = 'vote-feedback success';
                    await getProposals();
                } else {
                    feedbackEl.textContent = `Failed to vote on proposal #${proposalId}: ${result.error.message}`;
                    feedbackEl.className = 'vote-feedback error';
                }
                setTimeout(() => {
                    feedbackEl.style.display = 'none';
                }, 5000);
            }
        });

        table.dataset.listenerAdded = 'true';
    }
}

document.querySelectorAll('.dropdown-multi').forEach(dropdown => {
  const toggle = dropdown.querySelector('.dropdown-toggle');
  const labelSpan = toggle.querySelector('.dropdown-label'); // ✅ span for the text
  const arrowSpan = toggle.querySelector('.dropdown-arrow'); // ✅ span for the arrow
  const menu = dropdown.querySelector('.dropdown-menu');
  const checkboxes = menu.querySelectorAll('input[type="checkbox"]');
  const allCheckbox = menu.querySelector('input[value="All"]');

  // Open/close dropdown
  toggle.addEventListener('click', () => {
    dropdown.classList.toggle('open');
    // Rotate arrow when open/close
    if (dropdown.classList.contains('open')) {
      arrowSpan.textContent = '▲';
    } else {
      arrowSpan.textContent = '▼';
    }
  });

  // Handle checkbox changes
  checkboxes.forEach(cb => {
    cb.addEventListener('change', () => {
      if (cb.value === "All") {
        if (cb.checked) {
          // ✅ All clicked → uncheck everything else
          checkboxes.forEach(c => {
            if (c.value !== "All") c.checked = false;
          });
          labelSpan.textContent = "All Categories";
        }
      } else {
        if (cb.checked) {
          // ✅ Uncheck "All" if a category is selected
          allCheckbox.checked = false;
        }
        // Gather selected categories
        const selected = [...checkboxes]
          .filter(c => c.checked && c.value !== "All")
          .map(c => c.value);

        if (selected.length === 0) {
          // ✅ None selected → fall back to All
          allCheckbox.checked = true;
          labelSpan.textContent = "All Categories";
        } else {
          labelSpan.textContent = `${selected.length} selected`;
        }
      }
    });
  });

  // Close dropdown when clicking outside
  document.addEventListener('click', (e) => {
    if (!dropdown.contains(e.target)) {
      dropdown.classList.remove('open');
      arrowSpan.textContent = '▼'; // reset arrow
    }
  });
});

const sortContainer = document.querySelector(".sort-container");
const sortBtn = document.getElementById("sort-btn");
const sortValue = document.getElementById("sortValue");
const sortOptions = document.querySelectorAll(".sort-option");

// toggle dropdown on button click
sortBtn.addEventListener("click", (e) => {
  e.stopPropagation();
  sortContainer.classList.toggle("active");
});

// handle option click
sortOptions.forEach(option => {
  option.addEventListener("click", () => {
    currentSortOrder = option.dataset.value;
    sortValue.textContent = currentSortOrder;

    // close dropdown
    sortContainer.classList.remove("active");

    // refresh proposals
    getProposals();
  });
});

// close dropdown if click outside
document.addEventListener("click", (e) => {
  if (!sortContainer.contains(e.target)) {
    sortContainer.classList.remove("active");
  }
});

