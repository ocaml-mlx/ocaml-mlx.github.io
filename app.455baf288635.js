import { legacyLocation } from "/routes.353f2dcf47ed.js";

const destination = legacyLocation(location.search, location.hash);
if (destination !== null && destination !== location.pathname + location.search + location.hash) {
  location.replace(destination);
}

let setupPromptPromise;
let promptFeedbackTimer;
function loadSetupPrompt() {
  setupPromptPromise ??= fetch("/assets/setup-mlx-prompt.txt").then(response => {
    if (!response.ok) throw new Error(`Setup prompt unavailable (${response.status})`);
    return response.text();
  }).catch(error => {
    setupPromptPromise = null;
    throw error;
  });
  return setupPromptPromise;
}

document.addEventListener("click", async event => {
  const promptButton = event.target.closest("[data-copy-prompt]");
  if (promptButton) {
    clearTimeout(promptFeedbackTimer);
    const label = promptButton.querySelector("span");
    promptButton.disabled = true;
    label.textContent = "Loading prompt…";
    let promptLoaded = false;
    try {
      const prompt = await loadSetupPrompt();
      promptLoaded = true;
      label.textContent = "Copying prompt…";
      await navigator.clipboard.writeText(prompt);
      label.textContent = "Copied prompt";
    } catch {
      label.textContent = promptLoaded ? "Clipboard blocked — retry" : "Prompt unavailable — retry";
    } finally {
      promptButton.disabled = false;
      promptFeedbackTimer = setTimeout(() => {
        if (promptButton.isConnected) label.textContent = "Copy prompt";
      }, 3000);
    }
    return;
  }
  const button = event.target.closest("[data-copy]");
  if (button) {
    try {
      await navigator.clipboard.writeText(button.dataset.copy);
      button.querySelector("span").textContent = "Copied";
      setTimeout(() => { if (button.isConnected) button.querySelector("span").textContent = "Copy"; }, 1800);
    } catch {
      button.querySelector("span").textContent = "Select to copy";
    }
  }
});
