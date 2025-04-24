console.log('notify loaded')
document.addEventListener("DOMContentLoaded", () => {
    window.notify = notify
});

function notify(type, message) {
    let bgClass = 'bg-gray-600'
    if (type === 'notice') {
        bgClass = 'bg-brand-color-dark'
    } else if (type === 'alert') {
        bgClass = 'bg-red-600'
    }

    console.log('flash fired')

    const container = document.getElementById("toast-container");

    // Clear existing toasts to avoid duplicates or stale messages
    container.innerHTML = "";

    const toast = document.createElement("div");
    toast.className = `
        flex justify-between items-center max-w-sm w-full px-4 py-3 shadow-lg rounded-lg
        text-white animate-slide-in
        ${bgClass}
      `;
    toast.innerHTML = `
        <span>${message}</span>
        <button onclick="this.parentElement.remove()" class="ml-4 font-bold">×</button>
      `;

    container.appendChild(toast);

    // Auto remove after 7 seconds
    setTimeout(() => toast.remove(), 7000);

    // Clear the flash container before caching
    window.addEventListener("turbo:before-cache", () => {
        const container = document.getElementById("toast-container");
        if (container) container.innerHTML = "";
    });
}