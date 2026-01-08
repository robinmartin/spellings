// ----------------------
// Data
// ----------------------
let WORDS_DATA = null;
let WORDS = [];

// ----------------------
// Elements
// ----------------------
const el = {
  filterSelect: document.getElementById("filterSelect"),

  progressText: document.getElementById("progressText"),
  progressBar: document.getElementById("progressBar"),
  progress: document.querySelector(".progress"),

  wordArea: document.getElementById("wordArea"),

  prevBtn: document.getElementById("prevBtn"),
  nextBtn: document.getElementById("nextBtn"),
  startNewBtn: document.getElementById("startNewBtn"),

  confetti: document.getElementById("confetti"),
};

// ----------------------
// State
// ----------------------
let selectedFilter = "all";
let order = []; // current session order (array of words)
let index = 0;

// ----------------------
// Helpers
// ----------------------
function shuffle(array) {
  const a = array.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ----------------------
// LocalStorage persistence
// ----------------------
const STORAGE_KEY = "spellingTesterState";

function saveState() {
  try {
    const state = {
      order: order,
      filter: selectedFilter,
      index: index
    };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch (error) {
    console.error("Error saving state:", error);
  }
}

function loadState() {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      const state = JSON.parse(saved);
      return state;
    }
  } catch (error) {
    console.error("Error loading state:", error);
  }
  return null;
}

function clearState() {
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch (error) {
    console.error("Error clearing state:", error);
  }
}



function progress() {
  const total = order.length;
  const n = Math.min(total, Math.max(1, index + 1));
  el.progressText.textContent = `${n} / ${total}`;
  const pct = total ? (n / total) * 100 : 0;
  el.progressBar.style.width = `${pct}%`;
  el.progress.setAttribute("aria-valuenow", String(Math.round(pct)));
  
  // Enable/disable navigation buttons based on position
  if (total > 0) {
    el.prevBtn.disabled = index === 0;
    el.nextBtn.disabled = index === total - 1;
  } else {
    el.prevBtn.disabled = true;
    el.nextBtn.disabled = true;
  }
}

function currentWord() {
  return order[index];
}

function renderWord() {
  const w = currentWord();
  el.wordArea.innerHTML = "";

  const word = document.createElement("div");
  word.className = "word";
  word.textContent = w;
  el.wordArea.appendChild(word);

  progress();
  saveState(); // Save state after rendering
}

function getWordsForFilter(filter) {
  if (!WORDS_DATA || !Array.isArray(WORDS_DATA)) return [];

  if (filter === "all") {
    // Return all words
    return WORDS_DATA.map(item => item.word);
  } else if (filter === "learned") {
    // Return words that have a value in au1, au2, or sp1
    return WORDS_DATA
      .filter(item => {
        const hasAu1 = item.au1 !== undefined && item.au1 !== null && item.au1 !== "";
        const hasAu2 = item.au2 !== undefined && item.au2 !== null && item.au2 !== "";
        const hasSp1 = item.sp1 !== undefined && item.sp1 !== null && item.sp1 !== "";
        return hasAu1 || hasAu2 || hasSp1;
      })
      .map(item => item.word);
  } else if (filter === "not-learned") {
    // Return words that have null in all of au1, au2, and sp1
    return WORDS_DATA
      .filter(item => {
        const hasAu1 = item.au1 !== undefined && item.au1 !== null && item.au1 !== "";
        const hasAu2 = item.au2 !== undefined && item.au2 !== null && item.au2 !== "";
        const hasSp1 = item.sp1 !== undefined && item.sp1 !== null && item.sp1 !== "";
        return !hasAu1 && !hasAu2 && !hasSp1;
      })
      .map(item => item.word);
  } else {
    // Only return words that have a value in the selected filter column
    return WORDS_DATA
      .filter(item => item[filter] !== undefined && item[filter] !== null && item[filter] !== "")
      .map(item => item.word);
  }
}

function startSession(restoreFromStorage = false) {
  WORDS = getWordsForFilter(selectedFilter);

  if (!WORDS || WORDS.length === 0) {
    return;
  }

  if (restoreFromStorage) {
    const savedState = loadState();
    if (savedState && savedState.filter === selectedFilter && savedState.order && savedState.order.length > 0) {
      // Verify that the saved order contains valid words from current filter
      const validWords = new Set(WORDS);
      const savedOrderValid = savedState.order.every(word => validWords.has(word));

      if (savedOrderValid && savedState.index >= 0 && savedState.index < savedState.order.length) {
        order = savedState.order;
        index = savedState.index;
        renderWord();
        return;
      }
    }
  }

  // Start fresh if no valid saved state
  index = 0;
  order = shuffle(WORDS);
  renderWord();
}

function resetSession() {
  WORDS = getWordsForFilter(selectedFilter);
  if (!WORDS || WORDS.length === 0) {
    return;
  }
  index = 0;
  order = shuffle(WORDS);
  renderWord();
  saveState();
}

function startNewSession() {
  clearState();
  WORDS = getWordsForFilter(selectedFilter);
  if (!WORDS || WORDS.length === 0) {
    return;
  }
  index = 0;
  order = shuffle(WORDS);
  renderWord();
  saveState();
}


// ----------------------
// Confetti (tiny, no deps)
// ----------------------
const confetti = {
  running: false,
  parts: [],
  raf: 0,
  t0: 0,
};

function confettiBurst() {
  if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  const c = el.confetti;
  const dpr = Math.max(1, Math.min(2, window.devicePixelRatio || 1));
  const w = Math.floor(window.innerWidth);
  const h = Math.floor(window.innerHeight);
  c.width = Math.floor(w * dpr);
  c.height = Math.floor(h * dpr);
  c.style.opacity = "1";

  const ctx = c.getContext('2d');
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

  confetti.parts = [];
  const count = 140;
  for (let i = 0; i < count; i++) {
    confetti.parts.push({
      x: w / 2 + (Math.random() - 0.5) * 60,
      y: h * 0.18 + (Math.random() - 0.5) * 20,
      vx: (Math.random() - 0.5) * 9,
      vy: Math.random() * -6 - 3,
      g: 0.22 + Math.random() * 0.16,
      size: 5 + Math.random() * 7,
      rot: Math.random() * Math.PI,
      vr: (Math.random() - 0.5) * 0.25,
      life: 1.0,
    });
  }

  confetti.running = true;
  confetti.t0 = performance.now();

  const loop = (t) => {
    if (!confetti.running) return;
    const dt = Math.min(32, t - (confetti.lastT || t));
    confetti.lastT = t;

    ctx.clearRect(0, 0, w, h);

    for (const p of confetti.parts) {
      p.vy += p.g * (dt / 16);
      p.x += p.vx * (dt / 16);
      p.y += p.vy * (dt / 16);
      p.rot += p.vr * (dt / 16);
      p.life -= 0.0065 * (dt / 16);

      // wrap slightly
      if (p.x < -40) p.x = w + 40;
      if (p.x > w + 40) p.x = -40;

      const alpha = Math.max(0, Math.min(1, p.life));
      ctx.save();
      ctx.globalAlpha = alpha;
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rot);

      // Use a gradient-ish fill without hardcoding colors: derive from background palette via HSL.
      const hue = 220 + Math.random() * 120;
      ctx.fillStyle = `hsla(${hue}, 90%, 65%, ${alpha})`;
      ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size * 0.7);

      ctx.restore();
    }

    // stop after ~2.6s
    if (t - confetti.t0 > 2600) {
      confetti.running = false;
      c.style.opacity = "0";
      return;
    }

    confetti.raf = requestAnimationFrame(loop);
  };

  cancelAnimationFrame(confetti.raf);
  confetti.raf = requestAnimationFrame(loop);
}

// ----------------------
// Events
// ----------------------
// Filter selection - reset and restart when changed
el.filterSelect?.addEventListener("change", (e) => {
  selectedFilter = e.target.value;
  resetSession();
});

el.prevBtn.addEventListener("click", () => {
  if (!el.prevBtn.disabled && index > 0) {
    index--;
    renderWord();
  }
});

el.nextBtn.addEventListener("click", () => {
  if (!el.nextBtn.disabled && index < order.length - 1) {
    index++;
    renderWord();
  }
});

el.startNewBtn.addEventListener("click", () => {
  startNewSession();
});

// Keyboard shortcuts
window.addEventListener("keydown", (e) => {
  if (order.length > 0) {
    if (e.key === "ArrowLeft") { el.prevBtn.click(); }
    if (e.key === "ArrowRight") { el.nextBtn.click(); }
  }
});

// Resize confetti canvas if active
window.addEventListener('resize', () => {
  if (confetti.running) {
    confetti.running = false;
    el.confetti.style.opacity = "0";
  }
});

// Filter display names
const FILTER_NAMES = {
  "all": "All Words",
  "learned": "Covered",
  "not-learned": "Not Covered",
  "au1": "Autumn 1",
  "au2": "Autumn 2",
  "sp1": "Spring 1",
  "sp2": "Spring 2",
  "su1": "Summer 1",
  "su2": "Summer 2"
};

// Get available filters (filters that have at least one word)
function getAvailableFilters() {
  if (!WORDS_DATA || !Array.isArray(WORDS_DATA)) return [];

  const availableFilters = new Set();
  const allFilters = ["au1", "au2", "sp1", "sp2", "su1", "su2"];

  WORDS_DATA.forEach(item => {
    allFilters.forEach(filter => {
      if (item[filter] !== undefined && item[filter] !== null && item[filter] !== "") {
        availableFilters.add(filter);
      }
    });
  });

  return Array.from(availableFilters).sort();
}

// Populate filter dropdown
function populateFilters() {
  if (!el.filterSelect) return;

  // Clear existing options
  el.filterSelect.innerHTML = '';

  // Add "All Words" option
  const allOption = document.createElement("option");
  allOption.value = "all";
  allOption.textContent = FILTER_NAMES["all"];
  el.filterSelect.appendChild(allOption);

  // Add computed filters
  const learnedOption = document.createElement("option");
  learnedOption.value = "learned";
  learnedOption.textContent = FILTER_NAMES["learned"];
  el.filterSelect.appendChild(learnedOption);

  const notLearnedOption = document.createElement("option");
  notLearnedOption.value = "not-learned";
  notLearnedOption.textContent = FILTER_NAMES["not-learned"];
  el.filterSelect.appendChild(notLearnedOption);

  // Add available filters
  const availableFilters = getAvailableFilters();
  availableFilters.forEach(filter => {
    const option = document.createElement("option");
    option.value = filter;
    option.textContent = FILTER_NAMES[filter] || filter;
    el.filterSelect.appendChild(option);
  });

  // Set default to "au1" if available, otherwise "all"
  if (availableFilters.includes("au1")) {
    selectedFilter = "au1";
    el.filterSelect.value = "au1";
  } else {
    selectedFilter = "all";
    el.filterSelect.value = "all";
  }
}

// Load words from embedded JSON
function loadWords() {
  try {
    const wordsScript = document.getElementById('words-data');
    if (wordsScript) {
      WORDS_DATA = JSON.parse(wordsScript.textContent);
      populateFilters();
    } else {
      throw new Error('Words data not found');
    }
  } catch (error) {
    console.error('Error loading words:', error);
  }
}


// Init
selectedFilter = "au1"; // Default to Autumn 1
loadWords();
// Start immediately after words are loaded
// Use a small delay to ensure DOM and filters are ready
setTimeout(() => {
  // Try to restore from localStorage first
  const savedState = loadState();
  if (savedState && savedState.filter) {
    selectedFilter = savedState.filter;
    if (el.filterSelect) {
      el.filterSelect.value = selectedFilter;
    }
  }
  startSession(true); // Pass true to attempt restoration
}, 100);
